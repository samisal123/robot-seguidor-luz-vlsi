-- ============================================================
-- tb_sync_2ff.vhd
-- Verifica sync_2ff con WIDTH = 4 e INIT = '1':
--   arranca en INIT,
--   un cambio asincrono en d aparece en q exactamente en el
--   segundo flanco de subida despues del cambio (en varias fases
--   respecto al reloj),
--   cada bit es independiente.
-- GHDL: sim/correr.sh sync_2ff
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_sync_2ff is
end entity tb_sync_2ff;

architecture sim of tb_sync_2ff is
    constant T_CLK : time := 20 ns;
    signal clk : std_logic := '0';
    signal d   : std_logic_vector(3 downto 0) := "1111";
    signal q   : std_logic_vector(3 downto 0);
    signal fin : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.sync_2ff
        generic map (WIDTH => 4, INIT => '1')
        port map (clk => clk, d => d, q => q);

    estimulo : process
        type t_valores is array (natural range <>) of std_logic_vector(3 downto 0);
        constant VALORES : t_valores := ("0000", "0101", "1010", "0001", "1111", "1000");
        -- desfase del cambio respecto al flanco de subida
        type t_fases is array (natural range <>) of time;
        constant FASES : t_fases := (1 ns, 5 ns, 10 ns, 15 ns, 19 ns, 3 ns);
        variable previo : std_logic_vector(3 downto 0) := "1111";
    begin
        wait for 1 ns;
        assert q = "1111" report "q no arranca en INIT" severity error;

        for i in VALORES'range loop
            wait until rising_edge(clk);
            wait for FASES(i);
            d <= VALORES(i);
            -- primer flanco: q conserva el valor anterior
            wait until rising_edge(clk);
            wait for 1 ns;
            assert q = previo report "q cambio en el primer flanco" severity error;
            -- segundo flanco: ya debe verse
            wait until rising_edge(clk);
            wait for 1 ns;
            assert q = VALORES(i) report "q no cambio en el segundo flanco" severity error;
            -- se mantiene mientras d no cambie
            wait for 3 * T_CLK;
            assert q = VALORES(i) report "q no se mantuvo" severity error;
            previo := VALORES(i);
        end loop;

        report "tb_sync_2ff: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
