-- ============================================================
-- tb_entradas_placa.vhd
-- Prueba de los botones MODO, ACCION y METRONOMO con base_tiempo
-- real a 2 MHz (los tiempos son milisegundos reales).
-- Revisa:
--   1) al presionar ACCION sale un solo pulso en accion, entre 19 y
--      21 ms despues, y ninguno al soltar
--   2) lo mismo para METRONOMO en metro_btn
--   3) MODO recorre 00, 01, 10, 11 y regresa a 00, una vez por
--      pulsacion y solo despues del antirrebote; mantenerlo
--      presionado no avanza mas
--   4) un rebote corto en ACCION y en MODO no genera pulso
--   5) el reset regresa a interpretacion
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
    signal btn       : std_logic_vector(2 downto 0) := "111";   -- MODO, ACCION, METRO = btn(0..2)
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
            btn       => btn,
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

        procedure pulsa_modo is
        begin
            btn(0) <= '0';
            wait for 40 ms;
            btn(0) <= '1';
            wait for 40 ms;
        end procedure;
    begin
        wait for 10 us;
        rst <= '0';
        wait for 30 ms;
        assert modo = "00" and n_acc = 0 and n_met = 0
            report "tb_entradas_placa: estado inicial incorrecto" severity error;

        -- 1) ACCION
        btn(1) <= '0';
        t0 := now;
        wait until accion = '1' for 30 ms;
        assert accion = '1' report "tb_entradas_placa: ACCION no genero accion" severity error;
        assert now - t0 >= 19 ms and now - t0 <= 21 ms
            report "tb_entradas_placa: accion fuera de la ventana del antirrebote" severity error;
        wait for 30 ms;
        btn(1) <= '1';
        wait for 40 ms;
        assert n_acc = 1 report "tb_entradas_placa: ACCION debe dar un solo pulso" severity error;
        assert modo = "00" report "tb_entradas_placa: ACCION no debe cambiar el modo" severity error;

        -- 2) METRONOMO
        btn(2) <= '0';
        wait for 40 ms;
        btn(2) <= '1';
        wait for 40 ms;
        assert n_met = 1 and n_acc = 1
            report "tb_entradas_placa: METRONOMO debe dar un solo pulso en metro_btn" severity error;
        assert modo = "00" report "tb_entradas_placa: METRONOMO no debe cambiar el modo" severity error;

        -- 3) MODO: antirrebote y recorrido de los cuatro modos
        btn(0) <= '0';
        wait for 15 ms;
        assert modo = "00" report "tb_entradas_placa: el modo cambio antes del antirrebote" severity error;
        wait for 10 ms;
        assert modo = "01" report "tb_entradas_placa: modo grabacion" severity error;
        wait for 100 ms;
        assert modo = "01" report "tb_entradas_placa: mantener MODO no debe avanzar mas" severity error;
        btn(0) <= '1';
        wait for 40 ms;
        pulsa_modo;
        assert modo = "10" report "tb_entradas_placa: modo reproduccion" severity error;
        pulsa_modo;
        assert modo = "11" report "tb_entradas_placa: modo configuracion" severity error;
        pulsa_modo;
        assert modo = "00" report "tb_entradas_placa: despues de configuracion sigue interpretacion"
            severity error;
        assert n_acc = 1 and n_met = 1
            report "tb_entradas_placa: MODO no debe generar accion ni metro_btn" severity error;

        -- 4) rebotes cortos
        btn(1) <= '0';
        wait for 5 ms;
        btn(1) <= '1';
        wait for 40 ms;
        assert n_acc = 1 report "tb_entradas_placa: un rebote de 5 ms genero accion" severity error;
        btn(0) <= '0';
        wait for 5 ms;
        btn(0) <= '1';
        wait for 40 ms;
        assert modo = "00" report "tb_entradas_placa: un rebote de 5 ms cambio el modo" severity error;

        -- 5) reset
        pulsa_modo;
        assert modo = "01" report "tb_entradas_placa: MODO despues del rebote" severity error;
        rst <= '1';
        wait for 10 us;
        rst <= '0';
        wait for 1 ms;
        assert modo = "00" report "tb_entradas_placa: el reset debe regresar a interpretacion" severity error;

        report "tb_entradas_placa: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
