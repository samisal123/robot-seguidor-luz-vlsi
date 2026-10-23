-- ============================================================
-- tb_tick_gen.vhd
-- Verifica tick_gen a 50 MHz reales:
--   periodos exactos de 1 us, 58 us y 1 ms,
--   cada pulso dura un solo ciclo,
--   con rst activo no sale ningun pulso.
-- GHDL: sim/correr.sh tick_gen
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_tick_gen is
end entity tb_tick_gen;

architecture sim of tb_tick_gen is
    constant T_CLK : time := 20 ns;
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';
    signal t1   : std_logic;
    signal t58  : std_logic;
    signal tms  : std_logic;
    signal fin  : boolean := false;

    -- Mide el periodo y el ancho de un tick durante n pulsos
    procedure revisar (signal reloj : in std_logic; signal t : in std_logic;
                       periodo : time; n : natural; nombre : string) is
        variable ultimo : time := -1 ns;
        variable ancho  : natural;
    begin
        for i in 1 to n loop
            wait until rising_edge(reloj) and t = '1';
            if ultimo >= 0 ns then
                assert now - ultimo = periodo
                    report nombre & ": periodo incorrecto" severity error;
            end if;
            ultimo := now;
            ancho := 0;
            while t = '1' loop
                wait until rising_edge(reloj);
                ancho := ancho + 1;
            end loop;
            assert ancho = 1 report nombre & ": el pulso no dura un ciclo" severity error;
        end loop;
    end procedure;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.tick_gen
        port map (clk => clk, rst => rst, tick_1us => t1, tick_58us => t58, tick_1ms => tms);

    -- Con rst activo no debe salir ningun pulso
    vigila_rst : process (clk)
    begin
        if rising_edge(clk) and rst = '1' and now > 0 ns then
            assert t1 = '0' and t58 = '0' and tms = '0'
                report "salio un tick durante rst" severity error;
        end if;
    end process;

    estimulo : process
        variable t0 : time;
    begin
        wait for 5 us;                 -- rst por 250 ciclos
        wait until rising_edge(clk);
        rst <= '0';

        revisar(clk, t1,  1 us,  20, "tick_1us");
        revisar(clk, t58, 58 us, 5,  "tick_58us");
        revisar(clk, tms, 1 ms,  3,  "tick_1ms");

        -- tick_1ms coincide con un tick_1us
        wait until rising_edge(clk) and tms = '1';
        assert t1 = '1' report "tick_1ms no coincide con tick_1us" severity error;

        -- El rst a mitad de cuenta reinicia el prescaler
        rst <= '1';
        wait for 3 us;
        wait until rising_edge(clk);
        rst <= '0';
        t0 := now;
        wait until rising_edge(clk) and t1 = '1';
        -- pre cuenta 0..49 a partir del flanco siguiente; el pulso sale
        -- en el flanco 50 y se observa en el 51
        assert now - t0 = 51 * T_CLK
            report "el rst no reinicio el prescaler" severity error;
        report "tb_tick_gen: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
