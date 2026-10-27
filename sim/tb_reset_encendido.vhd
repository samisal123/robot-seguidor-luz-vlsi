-- ============================================================
-- tb_reset_encendido.vhd
-- Prueba del reset de encendido: rst vale '1' desde el encendido
-- hasta el flanco 16 del reloj (16 periodos) y despues '0' sin
-- volver a subir.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_reset_encendido is
end entity tb_reset_encendido;

architecture sim of tb_reset_encendido is
    constant T_CLK : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal fin : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.reset_encendido
        port map (clk => clk, rst => rst);

    estimulo : process
        variable altos : natural := 0;
    begin
        wait for 1 ns;
        assert rst = '1' report "tb_reset_encendido: rst debe arrancar en 1" severity error;
        for i in 1 to 200 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            if rst = '1' then
                altos := altos + 1;
                assert i < 16 report "tb_reset_encendido: rst volvio a subir" severity error;
            end if;
        end loop;
        -- el periodo antes del primer flanco mas los flancos 1 a 15
        assert altos + 1 = 16
            report "tb_reset_encendido: rst duro " & integer'image(altos + 1) & " periodos" severity error;

        report "tb_reset_encendido: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
