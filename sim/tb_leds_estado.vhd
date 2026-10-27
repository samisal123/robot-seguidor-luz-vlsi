-- ============================================================
-- tb_leds_estado.vhd
-- Prueba de los LEDs de estado (con el "ms" de 10 ciclos).
-- Revisa:
--   1) LEDR0-2 siguen a las voces, LEDR3 al metronomo, LEDR7 a la
--      memoria llena, LEDR9 a la saturacion
--   2) LEDR5 solo grabando y LEDR6 solo reproduciendo
--   3) LEDR8 encendido con cualquier efecto
--   4) cada tiempo del metronomo enciende LEDR4 durante 100 ms
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity tb_leds_estado is
end entity tb_leds_estado;

architecture sim of tb_leds_estado is
    constant T_CLK : time := 20 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal tick_1ms   : std_logic := '0';
    signal activas    : std_logic_vector(2 downto 0) := "000";
    signal metro_on   : std_logic := '0';
    signal beat       : std_logic := '0';
    signal estado_sec : std_logic_vector(1 downto 0) := S_ESPERA;
    signal llena      : std_logic := '0';
    signal efecto     : std_logic_vector(1 downto 0) := E_NINGUNO;
    signal clip       : std_logic := '0';
    signal ledr       : std_logic_vector(9 downto 0);
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
            activas    => activas,
            metro_on   => metro_on,
            beat       => beat,
            estado_sec => estado_sec,
            llena      => llena,
            efecto     => efecto,
            clip       => clip,
            ledr       => ledr
        );

    estimulo : process
        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;

        procedure revisa (esp : std_logic_vector(9 downto 0); msg : string) is
        begin
            ciclos(2);
            assert ledr = esp report "tb_leds_estado: " & msg severity error;
        end procedure;

        variable encendido : natural;
    begin
        ciclos(3);
        rst <= '0';
        revisa("0000000000", "todo apagado al inicio");

        -- 1)
        activas <= "101";
        revisa("0000000101", "voces 0 y 2");
        activas <= "000";
        metro_on <= '1';
        revisa("0000001000", "metronomo encendido");
        metro_on <= '0';
        llena <= '1';
        revisa("0010000000", "memoria llena");
        llena <= '0';
        clip <= '1';
        revisa("1000000000", "saturacion");
        clip <= '0';

        -- 2)
        estado_sec <= S_GRABANDO;
        revisa("0000100000", "grabando");
        estado_sec <= S_REPRODUCE;
        revisa("0001000000", "reproduciendo");
        estado_sec <= S_ESPERA;

        -- 3)
        for e in 1 to 3 loop
            if e = 1 then efecto <= E_TREMOLO; elsif e = 2 then efecto <= E_ECO; else efecto <= E_AMBOS; end if;
            revisa("0100000000", "efecto activo");
        end loop;
        efecto <= E_NINGUNO;

        -- 4) destello de 100 ms (100 ticks de 10 ciclos)
        beat <= '1';
        ciclos(1);
        beat <= '0';
        encendido := 0;
        for i in 1 to 1500 loop
            ciclos(1);
            if ledr(4) = '1' then
                encendido := encendido + 1;
            end if;
        end loop;
        assert encendido >= 990 and encendido <= 1010
            report "tb_leds_estado: el destello debe durar 100 ms (" & integer'image(encendido)
                   & " ciclos)" severity error;

        report "tb_leds_estado: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
