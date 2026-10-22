-- ============================================================
-- tb_robot_top.vhd
-- Verifica el smoke test con un CLK_HZ reducido:
--   LEDR1 = not KEY0, LEDR0 cambia cada CLK_HZ/2 ciclos,
--   LEDR9..2 en cero.
-- GHDL:  ghdl -a ../rtl/robot_top.vhd tb_robot_top.vhd
--        ghdl -e tb_robot_top && ghdl -r tb_robot_top --assert-level=error
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_robot_top is
end entity tb_robot_top;

architecture sim of tb_robot_top is
    constant T_CLK  : time    := 20 ns;
    constant CLK_HZ : natural := 10;      -- medio periodo de 5 ciclos
    signal clk  : std_logic := '0';
    signal key  : std_logic_vector(1 downto 0) := "11";
    signal ledr : std_logic_vector(9 downto 0);
    signal fin  : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.robot_top
        generic map (CLK_HZ => CLK_HZ)
        port map (MAX10_CLK1_50 => clk, KEY => key, LEDR => ledr);

    estimulo : process
        variable t0 : time;
    begin
        -- LEDR1 refleja KEY0, que es activo en bajo
        wait for 1 ns;
        assert ledr(1) = '0' report "LEDR1 deberia estar apagado con KEY0 suelto" severity error;
        key(0) <= '0';
        wait for 1 ns;
        assert ledr(1) = '1' report "LEDR1 deberia encender con KEY0 presionado" severity error;
        key(0) <= '1';

        -- LEDR0 cambia cada CLK_HZ/2 ciclos de reloj
        wait on ledr(0);
        t0 := now;
        wait on ledr(0);
        assert now - t0 = (CLK_HZ / 2) * T_CLK
            report "Periodo de LEDR0 incorrecto" severity error;

        assert ledr(9 downto 2) = "00000000" report "LEDR9..2 deberian estar en cero" severity error;

        report "tb_robot_top: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
