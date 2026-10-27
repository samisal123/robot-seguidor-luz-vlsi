-- ============================================================
-- tb_mezclador.vhd
-- Prueba del mezclador de 3 voces.
-- Revisa:
--   1) mezcla = saturar(8 * (voz0 + voz1 + voz2), +-2032) y la
--      bandera satura, con voz0 en todo su rango (-128..127) y
--      voz1, voz2 en una rejilla de 15 valores (57 600 casos)
--   2) escala: una voz sola a 127 da 1016 (mitad de la escala) sin
--      saturar; dos voces a +-127 llegan a +-2032 sin saturar;
--      tres voces a +-127 saturan
--   3) sal_valida es un pulso 1 ciclo despues de ent_valida
--   4) sin ent_valida la salida se mantiene
--   5) reset
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mezclador is
end entity tb_mezclador;

architecture sim of tb_mezclador is
    constant T_CLK : time := 20 ns;
    constant TOPE  : integer := 2032;

    type t_lista is array (natural range <>) of integer;
    constant REJILLA : t_lista := (-128, -127, -126, -100, -64, -33, -1, 0,
                                   1, 32, 63, 64, 100, 126, 127);

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal ent_valida : std_logic := '0';
    signal voz0, voz1, voz2 : std_logic_vector(7 downto 0) := (others => '0');
    signal mezcla     : std_logic_vector(11 downto 0);
    signal sal_valida : std_logic;
    signal satura     : std_logic;
    signal fin        : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.mezclador
        port map (
            clk        => clk,
            rst        => rst,
            ent_valida => ent_valida,
            voz0       => voz0,
            voz1       => voz1,
            voz2       => voz2,
            mezcla     => mezcla,
            sal_valida => sal_valida,
            satura     => satura
        );

    estimulo : process
        variable casos : natural := 0;

        -- Manda una muestra y revisa la salida y el pulso de validez
        procedure probar (a, b, c : integer) is
            variable p, e : integer;
            variable sat  : std_logic;
        begin
            voz0       <= std_logic_vector(to_signed(a, 8));
            voz1       <= std_logic_vector(to_signed(b, 8));
            voz2       <= std_logic_vector(to_signed(c, 8));
            ent_valida <= '1';
            wait until rising_edge(clk);       -- el mezclador captura
            ent_valida <= '0';
            wait for 1 ns;
            p := 8 * (a + b + c);
            if p > TOPE then
                e := TOPE;  sat := '1';
            elsif p < -TOPE then
                e := -TOPE; sat := '1';
            else
                e := p;     sat := '0';
            end if;
            assert sal_valida = '1'
                report "sal_valida no llego 1 ciclo despues de ent_valida" severity error;
            assert to_integer(signed(mezcla)) = e
                report "mezcla(" & integer'image(a) & "," & integer'image(b) & "," &
                       integer'image(c) & ") = " & integer'image(to_integer(signed(mezcla))) &
                       ", se esperaba " & integer'image(e) severity error;
            assert satura = sat
                report "satura incorrecta con (" & integer'image(a) & "," & integer'image(b) &
                       "," & integer'image(c) & ")" severity error;
            wait until rising_edge(clk);       -- ciclo sin ent_valida
            wait for 1 ns;
            assert sal_valida = '0'
                report "sal_valida dura mas de un ciclo" severity error;
            assert to_integer(signed(mezcla)) = e
                report "la mezcla no se mantuvo sin ent_valida" severity error;
            casos := casos + 1;
        end procedure;
    begin
        for i in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert sal_valida = '0' and to_integer(signed(mezcla)) = 0
            report "estado despues del reset incorrecto" severity error;

        -- 2) escala
        probar(127, 0, 0);
        assert to_integer(signed(mezcla)) = 1016 and satura = '0'
            report "una voz a escala completa no da 1016" severity error;
        probar(0, -127, 0);
        assert to_integer(signed(mezcla)) = -1016 and satura = '0'
            report "una voz a -127 no da -1016" severity error;
        probar(127, 127, 0);
        assert to_integer(signed(mezcla)) = 2032 and satura = '0'
            report "dos voces a 127 no deben saturar" severity error;
        probar(-127, 0, -127);
        assert to_integer(signed(mezcla)) = -2032 and satura = '0'
            report "dos voces a -127 no deben saturar" severity error;
        probar(127, 127, 127);
        assert to_integer(signed(mezcla)) = 2032 and satura = '1'
            report "tres voces a 127 deben saturar en 2032" severity error;
        probar(-127, -127, -127);
        assert to_integer(signed(mezcla)) = -2032 and satura = '1'
            report "tres voces a -127 deben saturar en -2032" severity error;

        -- 1) barrido
        for a in -128 to 127 loop
            for j in REJILLA'range loop
                for k in REJILLA'range loop
                    probar(a, REJILLA(j), REJILLA(k));
                end loop;
            end loop;
        end loop;

        -- 4) muchos ciclos sin ent_valida: se mantiene
        probar(10, 20, 30);
        voz0 <= std_logic_vector(to_signed(-100, 8));
        for i in 1 to 50 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;
        assert to_integer(signed(mezcla)) = 480 and sal_valida = '0'
            report "la mezcla cambio sin ent_valida" severity error;

        -- 5) reset
        probar(127, 127, 127);
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(signed(mezcla)) = 0 and satura = '0' and sal_valida = '0'
            report "el reset no limpio la salida" severity error;
        rst <= '0';

        report "casos revisados: " & integer'image(casos);
        report "tb_mezclador: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
