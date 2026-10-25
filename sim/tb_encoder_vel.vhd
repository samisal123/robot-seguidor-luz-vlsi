-- ============================================================
-- tb_encoder_vel.vhd
-- VENTANA_MS = 10, tick_1ms cada 4 ciclos (ventana de 40 ciclos).
-- Cuadratura: N transiciones validas en una ventana dan vel = N;
-- un cambio simultaneo de A y B no cuenta.
-- Un canal: cuenta los dos flancos de A e ignora B.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_encoder_vel is
end entity tb_encoder_vel;

architecture sim of tb_encoder_vel is
    constant T_CLK : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal a, b     : std_logic := '0';
    signal vel_q, vel_1 : std_logic_vector(9 downto 0);
    signal listo_q, listo_1 : std_logic;
    signal fin      : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
        variable n : natural := 0;
    begin
        if rising_edge(clk) then
            if n = 3 then
                n := 0;
                tick_1ms <= '1';
            else
                n := n + 1;
                tick_1ms <= '0';
            end if;
        end if;
    end process;

    dut_q : entity work.encoder_vel
        generic map (VENTANA_MS => 10, UN_CANAL => false)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, a => a, b => b,
                  vel => vel_q, listo => listo_q);

    dut_1 : entity work.encoder_vel
        generic map (VENTANA_MS => 10, UN_CANAL => true)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, a => a, b => b,
                  vel => vel_1, listo => listo_1);

    estimulo : process
        -- Un paso de cuadratura hacia adelante: 00 -> 10 -> 11 -> 01 -> 00
        procedure paso is
        begin
            wait until rising_edge(clk);
            if a = '0' and b = '0' then
                a <= '1';
            elsif a = '1' and b = '0' then
                b <= '1';
            elsif a = '1' and b = '1' then
                a <= '0';
            else
                b <= '0';
            end if;
            wait until rising_edge(clk);
        end procedure;

        procedure ventana is
        begin
            wait until rising_edge(clk) and listo_q = '1';
            wait until rising_edge(clk);
        end procedure;
    begin
        wait for 3 * T_CLK;
        rst <= '0';

        -- 7 transiciones de cuadratura en una ventana
        ventana;
        for k in 1 to 7 loop
            paso;
        end loop;
        ventana;
        assert to_integer(unsigned(vel_q)) = 7
            report "Cuadratura: vel = " & integer'image(to_integer(unsigned(vel_q))) &
                   ", se esperaba 7" severity error;
        -- de esas 7, 4 fueron cambios de A (flancos de A): 00->10, 11->01, ...
        assert to_integer(unsigned(vel_1)) = 4
            report "Un canal: vel = " & integer'image(to_integer(unsigned(vel_1))) &
                   ", se esperaba 4" severity error;

        -- Ventana sin movimiento
        ventana;
        assert to_integer(unsigned(vel_q)) = 0 report "Sin movimiento vel deberia ser 0" severity error;

        -- Cambio simultaneo de A y B: no cuenta en cuadratura
        wait until rising_edge(clk);
        a <= not a;
        b <= not b;
        ventana;
        assert to_integer(unsigned(vel_q)) = 0
            report "Un cambio simultaneo de A y B no debe contar" severity error;

        report "tb_encoder_vel: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
