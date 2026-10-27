-- ============================================================
-- tb_teclado_scan.vhd
-- Prueba del barrido de los dos teclados 4x4. El testbench
-- modela las dos matrices: la columna c de un teclado lee '0'
-- si alguna tecla presionada de esa columna esta en la fila
-- activa ('0'); si no, '1' (pull-up).
-- Para simular rapido, el "ms" dura 10 ciclos.
-- Revisa:
--   1) solo hay una fila activa a la vez y recorren 0,1,2,3
--   2) tiempo de antirrebote: una tecla aparece entre 4*(N-1)
--      y 4*N ms despues de presionarla (N = 5 lecturas)
--   3) un rebote (tecla que cambia en cada lectura) no aparece
--   4) varias teclas a la vez en los dos teclados, en el bit
--      16*teclado + 4*fila + columna
--   5) al soltar, la tecla desaparece con el mismo antirrebote
--   6) reset
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_teclado_scan is
end entity tb_teclado_scan;

architecture sim of tb_teclado_scan is
    constant T_CLK : time := 20 ns;
    constant N_DEB : positive := 5;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal filas    : std_logic_vector(3 downto 0);
    signal col1     : std_logic_vector(3 downto 0);
    signal col2     : std_logic_vector(3 downto 0);
    signal teclas   : std_logic_vector(31 downto 0);

    -- teclas presionadas del modelo: bit 4*fila + columna
    signal pres1 : std_logic_vector(15 downto 0) := (others => '0');
    signal pres2 : std_logic_vector(15 downto 0) := (others => '0');

    signal fin : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    -- "ms" de 10 ciclos
    process (clk)
        variable c : natural := 0;
    begin
        if rising_edge(clk) then
            tick_1ms <= '0';
            if c = 9 then
                c := 0;
                tick_1ms <= '1';
            else
                c := c + 1;
            end if;
        end if;
    end process;

    -- modelo de las dos matrices
    process (filas, pres1, pres2)
        variable v1, v2 : std_logic_vector(3 downto 0);
    begin
        v1 := "1111";
        v2 := "1111";
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                if filas(r) = '0' and pres1(4 * r + c) = '1' then
                    v1(c) := '0';
                end if;
                if filas(r) = '0' and pres2(4 * r + c) = '1' then
                    v2(c) := '0';
                end if;
            end loop;
        end loop;
        col1 <= v1;
        col2 <= v2;
    end process;

    dut : entity work.teclado_scan
        generic map (
            N_DEB => N_DEB
        )
        port map (
            clk      => clk,
            rst      => rst,
            tick_1ms => tick_1ms,
            filas    => filas,
            col1     => col1,
            col2     => col2,
            teclas   => teclas
        );

    -- 1) una sola fila activa, en orden
    process (clk)
        variable ceros : natural;
        variable ant   : integer := -1;
        variable act   : integer;
    begin
        if rising_edge(clk) and rst = '1' then
            ant := -1;
        elsif rising_edge(clk) then
            ceros := 0;
            act   := -1;
            for r in 0 to 3 loop
                if filas(r) = '0' then
                    ceros := ceros + 1;
                    act   := r;
                end if;
            end loop;
            assert ceros = 1
                report "tb_teclado_scan: debe haber exactamente una fila activa" severity error;
            if ant /= -1 and act /= ant then
                assert act = (ant + 1) mod 4
                    report "tb_teclado_scan: las filas no siguen el orden 0,1,2,3" severity error;
            end if;
            ant := act;
        end if;
    end process;

    estimulo : process
        procedure espera_ms (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk) and tick_1ms = '1';
            end loop;
            wait until rising_edge(clk);
        end procedure;

        procedure revisa (esperado : std_logic_vector(31 downto 0); msg : string) is
        begin
            assert teclas = esperado
                report "tb_teclado_scan: " & msg severity error;
        end procedure;

        variable esp : std_logic_vector(31 downto 0);
    begin
        rst <= '1';
        wait for 10 * T_CLK;
        wait until rising_edge(clk);
        rst <= '0';
        espera_ms(40);
        revisa((others => '0'), "sin teclas la salida debe ser 0");

        -- 2) tiempo de antirrebote, en las 4 fases posibles del barrido
        for fase in 0 to 3 loop
            espera_ms(fase);
            pres1(4 * 1 + 2) <= '1';          -- teclado 1, fila 1, columna 2
            espera_ms(4 * (N_DEB - 1));
            assert teclas(6) = '0'
                report "tb_teclado_scan: la tecla aparecio antes del antirrebote" severity error;
            espera_ms(4);
            esp := (others => '0');
            esp(6) := '1';
            revisa(esp, "tecla 1,2 del teclado 1 no detectada a tiempo");
            -- 5) soltar
            pres1(4 * 1 + 2) <= '0';
            espera_ms(4 * (N_DEB - 1));
            assert teclas(6) = '1'
                report "tb_teclado_scan: la tecla se solto antes del antirrebote" severity error;
            espera_ms(4);
            revisa((others => '0'), "la tecla no se solto");
        end loop;

        -- 3) rebote: la tecla cambia cada 4 ms (cada lectura distinta)
        for i in 1 to 30 loop
            pres2(4 * 2 + 1) <= not pres2(4 * 2 + 1);
            espera_ms(4);
            assert teclas(16 + 9) = '0'
                report "tb_teclado_scan: un rebote paso el filtro" severity error;
        end loop;
        pres2 <= (others => '0');
        espera_ms(40);

        -- 4) varias teclas en los dos teclados
        pres1(0)  <= '1';     -- teclado 1, fila 0, columna 0
        pres1(15) <= '1';     -- teclado 1, fila 3, columna 3
        pres2(9)  <= '1';     -- teclado 2, fila 2, columna 1
        pres2(3)  <= '1';     -- teclado 2, fila 0, columna 3
        espera_ms(4 * N_DEB + 4);
        esp := (others => '0');
        esp(0)  := '1';
        esp(15) := '1';
        esp(16 + 9) := '1';
        esp(16 + 3) := '1';
        revisa(esp, "varias teclas mal detectadas");

        -- todas las teclas de un teclado, una por una
        pres1 <= (others => '0');
        pres2 <= (others => '0');
        espera_ms(4 * N_DEB + 4);
        for k in 0 to 31 loop
            if k < 16 then
                pres1(k) <= '1';
            else
                pres2(k - 16) <= '1';
            end if;
            espera_ms(4 * N_DEB + 4);
            esp := (others => '0');
            esp(k) := '1';
            revisa(esp, "tecla individual mal ubicada");
            pres1 <= (others => '0');
            pres2 <= (others => '0');
            espera_ms(4 * N_DEB + 4);
        end loop;

        -- 6) reset con una tecla presionada
        pres1(5) <= '1';
        espera_ms(4 * N_DEB + 4);
        assert teclas(5) = '1' report "tb_teclado_scan: tecla 5 no detectada" severity error;
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        revisa((others => '0'), "el reset no limpio las teclas");
        rst <= '0';
        espera_ms(4 * N_DEB + 4);
        assert teclas(5) = '1' report "tb_teclado_scan: tecla 5 no regreso tras el reset" severity error;

        report "tb_teclado_scan: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
