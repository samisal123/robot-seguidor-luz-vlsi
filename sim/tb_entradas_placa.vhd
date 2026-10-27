-- ============================================================
-- tb_entradas_placa.vhd
-- Prueba de botones y switches con base_tiempo real a 2 MHz
-- (los tiempos son milisegundos reales).
-- Revisa:
--   1) al presionar KEY0 sale un solo pulso en accion, entre 19 y
--      21 ms despues, y ninguno al soltar
--   2) lo mismo para KEY1 en metro_btn
--   3) SW9-SW8 llegan a modo despues del antirrebote; SW0-SW7 no
--      afectan nada
--   4) un rebote corto en KEY0 no genera pulso
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_entradas_placa is
end entity tb_entradas_placa;

architecture sim of tb_entradas_placa is
    constant T_CLK : time := 500 ns;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal tick_1ms  : std_logic;
    signal key       : std_logic_vector(1 downto 0) := "11";
    signal sw        : std_logic_vector(9 downto 0) := (others => '0');
    signal accion    : std_logic;
    signal metro_btn : std_logic;
    signal modo      : std_logic_vector(1 downto 0);
    signal n_acc, n_met : natural := 0;
    signal fin       : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    ticks : entity work.base_tiempo
        generic map (CLK_HZ => 2_000_000)
        port map (clk => clk, rst => rst, tick_fs => open, tick_1ms => tick_1ms);

    dut : entity work.entradas_placa
        port map (
            clk       => clk,
            rst       => rst,
            tick_1ms  => tick_1ms,
            key       => key,
            sw        => sw,
            accion    => accion,
            metro_btn => metro_btn,
            modo      => modo
        );

    cuenta : process (clk)
    begin
        if rising_edge(clk) then
            if accion = '1' then
                n_acc <= n_acc + 1;
            end if;
            if metro_btn = '1' then
                n_met <= n_met + 1;
            end if;
        end if;
    end process;

    estimulo : process
        variable t0 : time;
    begin
        wait for 10 us;
        rst <= '0';
        wait for 30 ms;
        assert modo = "00" and n_acc = 0 and n_met = 0
            report "tb_entradas_placa: estado inicial incorrecto" severity error;

        -- 1) KEY0
        key(0) <= '0';
        t0 := now;
        wait until accion = '1' for 30 ms;
        assert accion = '1' report "tb_entradas_placa: KEY0 no genero accion" severity error;
        assert now - t0 >= 19 ms and now - t0 <= 21 ms
            report "tb_entradas_placa: accion fuera de la ventana del antirrebote" severity error;
        wait for 30 ms;
        key(0) <= '1';
        wait for 40 ms;
        assert n_acc = 1 report "tb_entradas_placa: KEY0 debe dar un solo pulso" severity error;

        -- 2) KEY1
        key(1) <= '0';
        wait for 40 ms;
        key(1) <= '1';
        wait for 40 ms;
        assert n_met = 1 and n_acc = 1
            report "tb_entradas_placa: KEY1 debe dar un solo pulso en metro_btn" severity error;

        -- 3) switches
        sw(7 downto 0) <= (others => '1');
        wait for 40 ms;
        assert modo = "00" report "tb_entradas_placa: SW0-SW7 no deben cambiar el modo" severity error;
        sw(9 downto 8) <= "01";
        wait for 15 ms;
        assert modo = "00" report "tb_entradas_placa: el modo cambio antes del antirrebote" severity error;
        wait for 10 ms;
        assert modo = "01" report "tb_entradas_placa: modo grabacion" severity error;
        sw(9 downto 8) <= "11";
        wait for 25 ms;
        assert modo = "11" report "tb_entradas_placa: modo configuracion" severity error;
        sw(9 downto 8) <= "10";
        wait for 25 ms;
        assert modo = "10" report "tb_entradas_placa: modo reproduccion" severity error;

        -- 4) rebote corto en KEY0
        key(0) <= '0';
        wait for 5 ms;
        key(0) <= '1';
        wait for 40 ms;
        assert n_acc = 1 report "tb_entradas_placa: un rebote de 5 ms genero pulso" severity error;

        report "tb_entradas_placa: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
