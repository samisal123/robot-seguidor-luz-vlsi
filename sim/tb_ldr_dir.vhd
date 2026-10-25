-- ============================================================
-- tb_ldr_dir.vhd
-- Recorre las 16 combinaciones de las LDR y compara contra la
-- tabla de direccion del enunciado del modulo. Ademas:
--   - un pulso mas corto que el filtro no cambia nada
--   - luz_cerca sigue al comparador de cerca (filtrado)
--   - con LUZ_ACTIVA = '0' y entradas invertidas da lo mismo
-- tick_1ms lo genera el testbench cada 4 ciclos (simulacion
-- rapida) y FILTRO_MS = 3.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity tb_ldr_dir is
end entity tb_ldr_dir;

architecture sim of tb_ldr_dir is
    constant T_CLK : time := 10 ns;
    constant T_MS  : time := 4 * T_CLK;   -- un "ms" del testbench

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal ve       : std_logic_vector(3 downto 0) := "0000";
    signal cerca    : std_logic := '0';
    signal luz      : std_logic_vector(3 downto 0);
    signal dir_luz  : std_logic_vector(2 downto 0);
    signal hay_luz, luz_cerca : std_logic;
    signal dir_inv  : std_logic_vector(2 downto 0);
    signal ve_n     : std_logic_vector(3 downto 0);
    signal cerca_n  : std_logic;
    signal fin      : boolean := false;

    -- ve = (A, D, I, F) en bits 3..0
    type t_tabla is array (0 to 15) of std_logic_vector(2 downto 0);
    constant TABLA : t_tabla := (
        0  => D_NINGUNA,    1  => D_FRENTE,     2  => D_IZQ,        3  => D_FRENTE_IZQ,
        4  => D_DER,        5  => D_FRENTE_DER, 6  => D_FRENTE,     7  => D_FRENTE,
        8  => D_ATRAS,      9  => D_FRENTE,     10 => D_IZQ,        11 => D_FRENTE_IZQ,
        12 => D_DER,        13 => D_FRENTE_DER, 14 => D_FRENTE,     15 => D_FRENTE);

    function img (v : std_logic_vector) return string is
        variable s : string(1 to v'length);
        variable k : natural := 1;
    begin
        for i in v'range loop
            if v(i) = '1' then s(k) := '1'; else s(k) := '0'; end if;
            k := k + 1;
        end loop;
        return s;
    end function;
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

    dut : entity work.ldr_dir
        generic map (FILTRO_MS => 3, LUZ_ACTIVA => '1')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, ve => ve, cerca => cerca,
                  luz => luz, dir_luz => dir_luz, hay_luz => hay_luz, luz_cerca => luz_cerca);

    ve_n    <= not ve;
    cerca_n <= not cerca;

    dut_inv : entity work.ldr_dir
        generic map (FILTRO_MS => 3, LUZ_ACTIVA => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, ve => ve_n,
                  cerca => cerca_n, luz => open, dir_luz => dir_inv,
                  hay_luz => open, luz_cerca => open);

    estimulo : process
    begin
        wait for 3 * T_CLK;
        rst <= '0';
        wait for 10 * T_MS;

        for c in 0 to 15 loop
            ve <= std_logic_vector(to_unsigned(c, 4));
            wait for 8 * T_MS;
            assert dir_luz = TABLA(c)
                report "ve=" & img(std_logic_vector(to_unsigned(c, 4))) &
                       ": dir_luz=" & img(dir_luz) & ", se esperaba " & img(TABLA(c))
                severity error;
            assert dir_inv = TABLA(c)
                report "Polaridad invertida: dir distinta con ve=" &
                       img(std_logic_vector(to_unsigned(c, 4))) severity error;
            if c = 0 then
                assert hay_luz = '0' report "hay_luz deberia ser 0" severity error;
            else
                assert hay_luz = '1' report "hay_luz deberia ser 1" severity error;
            end if;
            assert luz = std_logic_vector(to_unsigned(c, 4))
                report "luz filtrada distinta de la entrada" severity error;
        end loop;

        -- Pulso de 1 ms en el frente: el filtro lo descarta
        ve <= "0000";
        wait for 8 * T_MS;
        ve <= "0001";
        wait for 1 * T_MS;
        ve <= "0000";
        for k in 1 to 8 loop
            wait for T_MS;
            assert dir_luz = D_NINGUNA report "Un pulso corto paso el filtro" severity error;
        end loop;

        -- Luz cerca
        assert luz_cerca = '0' report "luz_cerca deberia iniciar en 0" severity error;
        ve    <= "0001";
        cerca <= '1';
        wait for 8 * T_MS;
        assert luz_cerca = '1' report "luz_cerca no subio" severity error;
        cerca <= '0';
        wait for 8 * T_MS;
        assert luz_cerca = '0' report "luz_cerca no bajo" severity error;

        report "tb_ldr_dir: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
