-- ============================================================
-- tb_leds_estado.vhd
-- Prueba de los 3 LEDs de la tarjeta, con el "ms" de 10 ciclos y
-- un periodo de parpadeo de 40 ms (PERIODO_MS) para que sea corta.
-- Los LEDs se encienden con '0'.
-- Revisa:
--   1) todo apagado al inicio (interpretacion)
--   2) grabacion: D4 parpadea lento (mitad del periodo encendido)
--      en espera y queda fijo grabando; D5 y D2 apagados
--   3) reproduccion: lo mismo con D5
--   4) configuracion: los 3 LEDs parpadean rapido (4 veces por
--      periodo, mitad encendidos) con el numero del parametro + 1
--      en binario, para los 7 parametros; el metronomo no se mete
--   5) con el metronomo encendido, cada tiempo enciende D2 durante
--      100 ms; con el metronomo apagado D2 no enciende
--   6) el reset apaga todo
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_leds_estado is
end entity tb_leds_estado;

architecture sim of tb_leds_estado is
    constant T_CLK   : time := 40 ns;
    constant PER_MS  : positive := 40;
    constant PER_CIC : natural := PER_MS * 10;   -- ciclos por periodo

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal tick_1ms   : std_logic := '0';
    signal metro_on   : std_logic := '0';
    signal beat       : std_logic := '0';
    signal modo       : std_logic_vector(1 downto 0) := M_INT;
    signal estado_sec : std_logic_vector(1 downto 0) := S_ESPERA;
    signal parametro  : std_logic_vector(2 downto 0) := "000";
    signal led_n      : std_logic_vector(2 downto 0);
    signal fin        : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
        variable c : natural := 0;
    begin
        if rising_edge(clk) then
            tick_1ms <= '0';
            if c = 9 then
                c := 0;
                tick_1ms <= '1';
            else
                c := c + 1;
            end if;
        end if;
    end process;

    dut : entity work.leds_estado
        generic map (PERIODO_MS => PER_MS)
        port map (
            clk        => clk,
            rst        => rst,
            tick_1ms   => tick_1ms,
            metro_on   => metro_on,
            beat       => beat,
            modo       => modo,
            estado_sec => estado_sec,
            parametro  => parametro,
            led_n      => led_n
        );

    estimulo : process
        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;

        -- esp: '1' = LED encendido (en el pin es '0')
        procedure revisa (esp : std_logic_vector(2 downto 0); msg : string) is
        begin
            ciclos(2);
            assert led_n = not esp report "tb_leds_estado: " & msg severity error;
        end procedure;

        -- durante un periodo completo los LEDs solo muestran "patron" o
        -- todo apagado; cuenta los ciclos con el patron y los cambios
        procedure parpadeo (patron : std_logic_vector(2 downto 0);
                            encendido_esp, cambios_esp : natural; msg : string) is
            variable enc, camb : natural := 0;
            variable antes : std_logic_vector(2 downto 0);
        begin
            ciclos(2);
            antes := led_n;
            for i in 1 to PER_CIC loop
                ciclos(1);
                if led_n = not patron then
                    enc := enc + 1;
                elsif led_n /= "111" then
                    report "tb_leds_estado: " & msg & ": patron inesperado" severity error;
                end if;
                if led_n /= antes then
                    camb := camb + 1;
                end if;
                antes := led_n;
            end loop;
            assert enc >= encendido_esp - 2 and enc <= encendido_esp + 2
                report "tb_leds_estado: " & msg & ": encendido " & integer'image(enc)
                       & " ciclos, se esperaban " & integer'image(encendido_esp) severity error;
            assert camb = cambios_esp
                report "tb_leds_estado: " & msg & ": " & integer'image(camb)
                       & " cambios, se esperaban " & integer'image(cambios_esp) severity error;
        end procedure;

        procedure destello (esperado_min, esperado_max : natural; msg : string) is
            variable encendido : natural := 0;
        begin
            beat <= '1';
            ciclos(1);
            beat <= '0';
            for i in 1 to 1500 loop
                ciclos(1);
                if led_n(0) = '0' then
                    encendido := encendido + 1;
                end if;
            end loop;
            assert encendido >= esperado_min and encendido <= esperado_max
                report "tb_leds_estado: " & msg & " (" & integer'image(encendido) & " ciclos)"
                severity error;
        end procedure;
    begin
        ciclos(3);
        rst <= '0';
        -- 1)
        revisa("000", "todo apagado al inicio");
        parpadeo("000", PER_CIC, 0, "interpretacion");

        -- 2) grabacion
        modo <= M_GRA;
        parpadeo("010", PER_CIC / 2, 2, "grabacion en espera");
        estado_sec <= S_GRABANDO;
        parpadeo("010", PER_CIC, 0, "grabando");
        estado_sec <= S_ESPERA;

        -- 3) reproduccion
        modo <= M_REP;
        parpadeo("100", PER_CIC / 2, 2, "reproduccion en espera");
        estado_sec <= S_REPRODUCE;
        parpadeo("100", PER_CIC, 0, "reproduciendo");
        estado_sec <= S_ESPERA;

        -- 4) configuracion, con el metronomo encendido y un tiempo a la mitad
        modo <= M_CONF;
        metro_on <= '1';
        for p in 0 to N_PARAM - 1 loop
            parametro <= std_logic_vector(to_unsigned(p, 3));
            if p = 3 then
                beat <= '1';
                ciclos(1);
                beat <= '0';
            end if;
            parpadeo(std_logic_vector(to_unsigned(p + 1, 3)), PER_CIC / 2, 8,
                     "configuracion, parametro " & integer'image(p));
        end loop;
        metro_on <= '0';

        -- 5) destello de 100 ms (100 ticks de 10 ciclos), en interpretacion
        modo <= M_INT;
        parametro <= "000";
        ciclos(2);
        destello(0, 0, "con el metronomo apagado D2 no debe encender");
        metro_on <= '1';
        destello(990, 1010, "el destello debe durar 100 ms");

        -- 6) reset a mitad de un destello y grabando
        modo <= M_GRA;
        estado_sec <= S_GRABANDO;
        beat <= '1';
        ciclos(1);
        beat <= '0';
        ciclos(20);
        assert led_n = "100" report "tb_leds_estado: D2 y D4 encendidos" severity error;
        rst <= '1';
        ciclos(2);
        assert led_n = "111" report "tb_leds_estado: el reset debe apagar todo" severity error;

        report "tb_leds_estado: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
