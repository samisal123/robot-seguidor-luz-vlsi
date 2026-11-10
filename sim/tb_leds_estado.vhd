-- ============================================================
-- tb_leds_estado.vhd
-- Prueba de los 3 LEDs de la tarjeta (con el "ms" de 10 ciclos).
-- Los LEDs se encienden con '0'.
-- Revisa:
--   1) todo apagado al inicio
--   2) D4 solo grabando y D5 solo reproduciendo
--   3) con el metronomo encendido, cada tiempo enciende D2 durante
--      100 ms; con el metronomo apagado D2 no enciende
--   4) el reset apaga todo
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity tb_leds_estado is
end entity tb_leds_estado;

architecture sim of tb_leds_estado is
    constant T_CLK : time := 40 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal tick_1ms   : std_logic := '0';
    signal metro_on   : std_logic := '0';
    signal beat       : std_logic := '0';
    signal estado_sec : std_logic_vector(1 downto 0) := S_ESPERA;
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
        port map (
            clk        => clk,
            rst        => rst,
            tick_1ms   => tick_1ms,
            metro_on   => metro_on,
            beat       => beat,
            estado_sec => estado_sec,
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

        -- 2)
        estado_sec <= S_GRABANDO;
        revisa("010", "grabando");
        estado_sec <= S_REPRODUCE;
        revisa("100", "reproduciendo");
        estado_sec <= S_ESPERA;
        revisa("000", "en espera");

        -- 3) destello de 100 ms (100 ticks de 10 ciclos)
        destello(0, 0, "con el metronomo apagado D2 no debe encender");
        metro_on <= '1';
        destello(990, 1010, "el destello debe durar 100 ms");

        -- 4) reset a mitad de un destello y grabando
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
