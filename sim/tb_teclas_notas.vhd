-- ============================================================
-- tb_teclas_notas.vhd
-- Prueba de la traduccion de teclas a notas y funciones.
-- El mapa del teclado se vuelve a escribir aqui a partir de la
-- distribucion fisica (1 2 3 A / 4 5 6 B / 7 8 9 C / * 0 # D):
-- las teclas de nota, en orden de lectura, son los semitonos
-- C a B; la columna 4 son A, B, C, D.
-- Revisa:
--   1) cada una de las 24 teclas de nota da 12*octava + j
--      (teclado 2 = una octava arriba), en todas las octavas
--   2) cada tecla de funcion da un pulso de un ciclo en su bit
--   3) con varias teclas salen las 3 mas graves, de grave a aguda
--   4) ultima = la ultima tecla de nota presionada
--   5) las teclas de funcion no generan notas
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_teclas_notas is
end entity tb_teclas_notas;

architecture sim of tb_teclas_notas is
    constant T_CLK : time := 20 ns;

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal teclas : std_logic_vector(31 downto 0) := (others => '0');
    signal octava : std_logic_vector(2 downto 0) := "100";
    signal notas  : std_logic_vector(20 downto 0);
    signal func   : std_logic_vector(7 downto 0);
    signal ultima : std_logic_vector(6 downto 0);
    signal fin    : boolean := false;

    -- indice de tecla (4*fila + columna) de cada semitono, segun la
    -- distribucion fisica del teclado
    type t_idx is array (0 to 11) of natural;
    constant TECLA_SEMI : t_idx := (0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14);
    type t_idx4 is array (0 to 3) of natural;
    constant TECLA_FUNC : t_idx4 := (3, 7, 11, 15);   -- A, B, C, D

    function nota_i (v : std_logic_vector(20 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(7 * i + 6 downto 7 * i)));
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.teclas_notas
        port map (
            clk    => clk,
            rst    => rst,
            teclas => teclas,
            octava => octava,
            notas  => notas,
            func   => func,
            ultima => ultima
        );

    estimulo : process
        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        variable k, j    : natural;
        variable visto   : natural;
    begin
        rst <= '1';
        ciclos(3);
        rst <= '0';
        ciclos(2);
        assert notas = (notas'range => '0') and func = x"00"
            report "tb_teclas_notas: sin teclas debe haber silencio" severity error;

        -- 1) las 24 notas en las octavas 2 a 6
        for oct in 2 to 6 loop
            octava <= std_logic_vector(to_unsigned(oct, 3));
            for t in 0 to 1 loop
                for s in 0 to 11 loop
                    k := 16 * t + TECLA_SEMI(s);
                    j := 12 * t + s;
                    teclas <= (others => '0');
                    teclas(k) <= '1';
                    ciclos(2);
                    wait for 1 ns;
                    assert nota_i(notas, 0) = 12 * oct + j and nota_i(notas, 1) = 0
                           and nota_i(notas, 2) = 0
                        report "tb_teclas_notas: tecla " & integer'image(k) & " en octava "
                               & integer'image(oct) & " dio " & integer'image(nota_i(notas, 0))
                        severity error;
                    assert to_integer(unsigned(ultima)) = 12 * oct + j
                        report "tb_teclas_notas: ultima nota incorrecta" severity error;
                    teclas <= (others => '0');
                    ciclos(2);
                end loop;
            end loop;
        end loop;
        octava <= "100";

        -- 2) y 5) teclas de funcion: pulso de un ciclo y sin notas
        for t in 0 to 1 loop
            for f in 0 to 3 loop
                k := 16 * t + TECLA_FUNC(f);
                teclas(k) <= '1';
                visto := 0;
                for c in 1 to 6 loop
                    wait until rising_edge(clk);
                    wait for 1 ns;
                    if func(4 * t + f) = '1' then
                        visto := visto + 1;
                    end if;
                    for o in 0 to 7 loop
                        if o /= 4 * t + f then
                            assert func(o) = '0'
                                report "tb_teclas_notas: pulso de funcion en el bit equivocado"
                                severity error;
                        end if;
                    end loop;
                    assert notas = (notas'range => '0')
                        report "tb_teclas_notas: una tecla de funcion genero nota" severity error;
                end loop;
                assert visto = 1
                    report "tb_teclas_notas: la funcion " & integer'image(4 * t + f)
                           & " dio " & integer'image(visto) & " pulsos" severity error;
                teclas(k) <= '0';
                ciclos(3);
            end loop;
        end loop;

        -- 3) varias teclas: #, 1 (teclado 1) y 3 (teclado 2)
        teclas <= (others => '0');
        teclas(14) <= '1';            -- B4 = 59
        ciclos(2);
        teclas(0) <= '1';             -- C4 = 48
        ciclos(2);
        teclas(16 + 2) <= '1';        -- D5 = 62
        ciclos(2);
        wait for 1 ns;
        assert nota_i(notas, 0) = 48 and nota_i(notas, 1) = 59 and nota_i(notas, 2) = 62
            report "tb_teclas_notas: acorde mal ordenado" severity error;
        assert to_integer(unsigned(ultima)) = 62
            report "tb_teclas_notas: ultima debe ser 62" severity error;
        -- una cuarta tecla mas aguda no entra; una mas grave desplaza a la mas aguda
        teclas(16 + 14) <= '1';       -- B5 = 71
        ciclos(2);
        wait for 1 ns;
        assert nota_i(notas, 0) = 48 and nota_i(notas, 1) = 59 and nota_i(notas, 2) = 62
            report "tb_teclas_notas: la cuarta nota aguda no debe entrar" severity error;
        teclas(1) <= '1';             -- C#4 = 49
        ciclos(2);
        wait for 1 ns;
        assert nota_i(notas, 0) = 48 and nota_i(notas, 1) = 49 and nota_i(notas, 2) = 59
            report "tb_teclas_notas: deben quedar las 3 notas mas graves" severity error;
        assert to_integer(unsigned(ultima)) = 49
            report "tb_teclas_notas: ultima debe ser 49" severity error;
        -- soltar la ultima: ultima no cambia
        teclas(1) <= '0';
        ciclos(2);
        wait for 1 ns;
        assert to_integer(unsigned(ultima)) = 49
            report "tb_teclas_notas: soltar no debe cambiar ultima" severity error;

        -- reset
        rst <= '1';
        ciclos(2);
        wait for 1 ns;
        assert notas = (notas'range => '0') and to_integer(unsigned(ultima)) = 0
            report "tb_teclas_notas: el reset no limpio las salidas" severity error;
        rst <= '0';

        report "tb_teclas_notas: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
