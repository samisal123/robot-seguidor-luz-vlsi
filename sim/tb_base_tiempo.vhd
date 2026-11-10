-- ============================================================
-- tb_base_tiempo.vhd
-- Prueba de la base de tiempo a 25 MHz reales.
-- Revisa:
--   1) tick_fs cada FS_DIV = 512 ciclos (20.48 us)
--   2) tick_1ms cada 1 ms exacto
--   3) cada pulso dura un solo ciclo
--   4) con rst activo no sale ningun pulso, y al soltarlo las
--      cuentas empiezan de cero (tambien a mitad de una cuenta)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity tb_base_tiempo is
end entity tb_base_tiempo;

architecture sim of tb_base_tiempo is
    constant T_CLK : time := 40 ns;    -- 25 MHz

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_fs  : std_logic;
    signal tick_1ms : std_logic;
    signal fin      : boolean := false;

    -- mide el periodo y el ancho de un tick durante n pulsos
    procedure revisar (signal reloj : in std_logic; signal t : in std_logic;
                       periodo : time; n : natural; nombre : string) is
        variable ultimo : time := -1 ns;
        variable ancho  : natural;
    begin
        for i in 1 to n loop
            wait until rising_edge(reloj) and t = '1';
            if ultimo >= 0 ns then
                assert now - ultimo = periodo
                    report "tb_base_tiempo: " & nombre & ": periodo incorrecto" severity error;
            end if;
            ultimo := now;
            ancho := 0;
            while t = '1' loop
                wait until rising_edge(reloj);
                ancho := ancho + 1;
            end loop;
            assert ancho = 1
                report "tb_base_tiempo: " & nombre & ": el pulso no dura un ciclo" severity error;
        end loop;
    end procedure;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.base_tiempo
        port map (
            clk      => clk,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms
        );

    vigila_rst : process (clk)
    begin
        if rising_edge(clk) and rst = '1' and now > 2 * T_CLK then
            assert tick_fs = '0' and tick_1ms = '0'
                report "tb_base_tiempo: salio un tick durante rst" severity error;
        end if;
    end process;

    estimulo : process
        variable t0 : time;
    begin
        wait for 30 us;            -- rst mas largo que un periodo de tick_fs
        wait until rising_edge(clk);
        rst <= '0';
        t0 := now;
        -- 4) tras el rst, el primer tick_fs sale en el flanco FS_DIV
        wait until rising_edge(clk) and tick_fs = '1';
        assert now - t0 = (FS_DIV + 1) * T_CLK
            report "tb_base_tiempo: el rst no reinicio la cuenta de tick_fs" severity error;

        revisar(clk, tick_fs, FS_DIV * T_CLK, 30, "tick_fs");
        revisar(clk, tick_1ms, 1 ms, 4, "tick_1ms");

        -- rst a mitad de las cuentas: las dos vuelven a empezar
        wait for 7 us;
        wait until rising_edge(clk);
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';
        t0 := now;
        wait until rising_edge(clk) and tick_fs = '1';
        assert now - t0 = (FS_DIV + 1) * T_CLK
            report "tb_base_tiempo: el rst no reinicio tick_fs a mitad de cuenta" severity error;
        wait until rising_edge(clk) and tick_1ms = '1';
        assert now - t0 = 1 ms + T_CLK
            report "tb_base_tiempo: el rst no reinicio tick_1ms a mitad de cuenta" severity error;

        report "tb_base_tiempo: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
