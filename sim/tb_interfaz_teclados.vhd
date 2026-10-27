-- ============================================================
-- tb_interfaz_teclados.vhd
-- Prueba de la conexion con los teclados, con los modelos de
-- teclado (sim/modelo_teclado.vhd) en los pines. El "ms" dura
-- 20 ciclos.
-- Revisa:
--   1) las filas solo valen '0' o 'Z' (colector abierto) y hay
--      exactamente una en '0' en cada teclado, la misma en los dos
--   2) cada una de las 32 teclas llega a su bit de teclas
--   3) dos teclas de la misma columna en filas distintas se leen
--      las dos (sin corto entre filas)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_interfaz_teclados is
end entity tb_interfaz_teclados;

architecture sim of tb_interfaz_teclados is
    constant T_CLK : time := 20 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal tec1_col, tec2_col : std_logic_vector(3 downto 0);
    signal tec1_fil, tec2_fil : std_logic_vector(3 downto 0);
    signal teclas   : std_logic_vector(31 downto 0);
    signal pres1, pres2 : std_logic_vector(15 downto 0) := (others => '0');
    signal fin      : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
        variable c : natural := 0;
    begin
        if rising_edge(clk) then
            tick_1ms <= '0';
            if c = 19 then
                c := 0;
                tick_1ms <= '1';
            else
                c := c + 1;
            end if;
        end if;
    end process;

    dut : entity work.interfaz_teclados
        port map (
            clk      => clk,
            rst      => rst,
            tick_1ms => tick_1ms,
            tec1_col => tec1_col,
            tec2_col => tec2_col,
            tec1_fil => tec1_fil,
            tec2_fil => tec2_fil,
            teclas   => teclas
        );

    teclado1 : entity work.modelo_teclado
        port map (filas => tec1_fil, cols => tec1_col, presion => pres1);
    teclado2 : entity work.modelo_teclado
        port map (filas => tec2_fil, cols => tec2_col, presion => pres2);

    -- 1) colector abierto
    filas : process (clk)
        variable ceros : natural;
    begin
        if rising_edge(clk) and rst = '0' then
            ceros := 0;
            for r in 0 to 3 loop
                assert tec1_fil(r) = '0' or tec1_fil(r) = 'Z'
                    report "tb_interfaz_teclados: fila del teclado 1 distinta de 0 o Z" severity error;
                assert tec2_fil(r) = tec1_fil(r)
                    report "tb_interfaz_teclados: los dos teclados deben barrer la misma fila"
                    severity error;
                if tec1_fil(r) = '0' then
                    ceros := ceros + 1;
                end if;
            end loop;
            assert ceros = 1
                report "tb_interfaz_teclados: debe haber una sola fila activa" severity error;
        end if;
    end process;

    estimulo : process
        procedure espera_ms (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk) and tick_1ms = '1';
            end loop;
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        variable esp : std_logic_vector(31 downto 0);
    begin
        wait for 10 * T_CLK;
        wait until rising_edge(clk);
        rst <= '0';
        espera_ms(30);
        assert teclas = x"00000000" report "tb_interfaz_teclados: sin teclas" severity error;

        -- 2) las 32 teclas una por una
        for k in 0 to 31 loop
            if k < 16 then
                pres1(k) <= '1';
            else
                pres2(k - 16) <= '1';
            end if;
            espera_ms(26);
            esp := (others => '0');
            esp(k) := '1';
            assert teclas = esp
                report "tb_interfaz_teclados: la tecla " & integer'image(k) & " no llego a su bit"
                severity error;
            pres1 <= (others => '0');
            pres2 <= (others => '0');
            espera_ms(26);
        end loop;

        -- 3) misma columna, filas 0 y 3, en el teclado 2
        pres2(0)  <= '1';
        pres2(12) <= '1';
        espera_ms(26);
        esp := (others => '0');
        esp(16 + 0)  := '1';
        esp(16 + 12) := '1';
        assert teclas = esp
            report "tb_interfaz_teclados: dos teclas de la misma columna" severity error;

        report "tb_interfaz_teclados: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
