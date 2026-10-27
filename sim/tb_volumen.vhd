-- ============================================================
-- tb_volumen.vhd
-- Prueba del control de volumen.
-- Revisa:
--   1) todos los x de 12 bits (-2048..2047) con vol 0..7:
--      y = piso(x * min(vol, 4) / 4)   (32 768 casos)
--   2) niveles exactos con escala completa (2032): 0, 508, 1016,
--      1524, 2032 y con -2032
--   3) sal_valida es un pulso 1 ciclo despues de ent_valida
--   4) reset
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_volumen is
end entity tb_volumen;

architecture sim of tb_volumen is
    constant T_CLK : time := 20 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal ent_valida : std_logic := '0';
    signal x          : std_logic_vector(11 downto 0) := (others => '0');
    signal vol        : std_logic_vector(2 downto 0) := "100";
    signal y          : std_logic_vector(11 downto 0);
    signal sal_valida : std_logic;
    signal fin        : boolean := false;

    -- division con redondeo hacia abajo (b > 0)
    function piso_div (a, b : integer) return integer is
    begin
        if a >= 0 then
            return a / b;
        else
            return -((-a + b - 1) / b);
        end if;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.volumen
        port map (
            clk        => clk,
            rst        => rst,
            ent_valida => ent_valida,
            x          => x,
            vol        => vol,
            y          => y,
            sal_valida => sal_valida
        );

    estimulo : process
        variable casos : natural := 0;

        procedure probar (xv, v : integer) is
            variable ve, e : integer;
        begin
            x          <= std_logic_vector(to_signed(xv, 12));
            vol        <= std_logic_vector(to_unsigned(v, 3));
            ent_valida <= '1';
            wait until rising_edge(clk);
            ent_valida <= '0';
            wait for 1 ns;
            if v > 4 then
                ve := 4;
            else
                ve := v;
            end if;
            e := piso_div(xv * ve, 4);
            assert sal_valida = '1'
                report "sal_valida no llego 1 ciclo despues de ent_valida" severity error;
            assert to_integer(signed(y)) = e
                report "vol " & integer'image(v) & ", x = " & integer'image(xv) &
                       ": y = " & integer'image(to_integer(signed(y))) &
                       ", se esperaba " & integer'image(e) severity error;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '0'
                report "sal_valida dura mas de un ciclo" severity error;
            casos := casos + 1;
        end procedure;

        type t_lista is array (0 to 4) of integer;
        constant NIVELES : t_lista := (0, 508, 1016, 1524, 2032);
    begin
        for i in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '0';

        -- 2) niveles con escala completa
        for v in 0 to 4 loop
            probar(2032, v);
            assert to_integer(signed(y)) = NIVELES(v)
                report "nivel " & integer'image(v) & " de 2032 incorrecto" severity error;
            probar(-2032, v);
            assert to_integer(signed(y)) = -NIVELES(v)
                report "nivel " & integer'image(v) & " de -2032 incorrecto" severity error;
        end loop;

        -- 1) barrido completo
        for v in 0 to 7 loop
            for xv in -2048 to 2047 loop
                probar(xv, v);
            end loop;
        end loop;

        -- 4) reset
        probar(1000, 4);
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(signed(y)) = 0 and sal_valida = '0'
            report "el reset no limpio la salida" severity error;
        rst <= '0';

        report "casos revisados: " & integer'image(casos);
        report "tb_volumen: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
