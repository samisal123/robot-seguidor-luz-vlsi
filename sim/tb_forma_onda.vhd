-- ============================================================
-- tb_forma_onda.vhd
-- Prueba del generador de formas de onda. Recorre las 65 536
-- fases que distinguen los 16 bits altos, para cada forma, y
-- compara contra la forma ideal calculada en el testbench.
-- Revisa:
--   1) todas las muestras quedan entre -127 y 127
--   2) cuadrada: +127 en la primera mitad, -127 en la segunda
--   3) triangular: sube en la primera mitad, baja en la segunda,
--      sin saltos (cambio maximo de 1 entre fases vecinas), con
--      picos de +-127 y a no mas de 2 de la triangular ideal
--   4) sierra: rampa creciente de -127 a 127 con un solo salto
--   5) seno: error maximo de 1 contra 127 * sin(2 pi fase)
--   6) cambio de forma en operacion (siguiente ciclo)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.synth_pkg.all;

entity tb_forma_onda is
end entity tb_forma_onda;

architecture sim of tb_forma_onda is
    constant T_CLK : time := 20 ns;

    signal clk     : std_logic := '0';
    signal forma   : std_logic_vector(1 downto 0) := W_CUADRADA;
    signal fase    : std_logic_vector(23 downto 0) := (others => '0');
    signal muestra : std_logic_vector(7 downto 0);
    signal fin     : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.forma_onda
        port map (
            clk     => clk,
            forma   => forma,
            fase    => fase,
            muestra => muestra
        );

    estimulo : process
        variable m, ant  : integer;
        variable saltos  : natural;
        variable maxi    : integer;
        variable mini    : integer;
        variable ideal   : real;
        type t_formas is array (0 to 3) of std_logic_vector(1 downto 0);
        constant FORMAS : t_formas := (W_CUADRADA, W_TRIANGULAR, W_SIERRA, W_SENO);
    begin
        for w in 0 to 3 loop
            forma  <= FORMAS(w);
            saltos := 0;
            maxi   := -1000;
            mini   := 1000;
            ant    := 0;
            for k in 0 to 65535 loop
                fase <= std_logic_vector(to_unsigned(k, 16)) & x"00";
                wait until rising_edge(clk);
                wait for 1 ns;
                m := to_integer(signed(muestra));
                -- 1) rango
                assert m >= -127 and m <= 127
                    report "tb_forma_onda: muestra fuera de rango" severity error;
                if m > maxi then maxi := m; end if;
                if m < mini then mini := m; end if;
                case w is
                    when 0 =>
                        -- 2) cuadrada
                        if k < 32768 then
                            assert m = 127 report "tb_forma_onda: cuadrada debe ser 127" severity error;
                        else
                            assert m = -127 report "tb_forma_onda: cuadrada debe ser -127" severity error;
                        end if;
                    when 1 =>
                        -- 3) triangular: contra la ideal (+-2) y sin saltos
                        if k < 32768 then
                            ideal := -127.0 + 254.0 * real(k) / 32767.0;
                        else
                            ideal := 127.0 - 254.0 * real(k - 32768) / 32767.0;
                        end if;
                        assert abs (real(m) - ideal) <= 2.0
                            report "tb_forma_onda: la triangular se aleja de la ideal" severity error;
                        if k > 0 then
                            assert abs (m - ant) <= 1
                                report "tb_forma_onda: la triangular tiene un salto" severity error;
                            if k < 32768 then
                                assert m >= ant report "tb_forma_onda: la triangular debe subir" severity error;
                            else
                                assert m <= ant report "tb_forma_onda: la triangular debe bajar" severity error;
                            end if;
                        end if;
                    when 2 =>
                        -- 4) sierra
                        if k > 0 then
                            if m < ant then
                                saltos := saltos + 1;
                            end if;
                        end if;
                    when others =>
                        -- 5) seno
                        ideal := 127.0 * sin(2.0 * MATH_PI * real(k / 256) / 256.0);
                        assert abs (real(m) - ideal) <= 1.0
                            report "tb_forma_onda: el seno se aleja de la ideal" severity error;
                end case;
                ant := m;
            end loop;
            if w = 2 then
                assert saltos = 0
                    report "tb_forma_onda: la sierra debe ser creciente dentro del periodo" severity error;
                assert mini = -127 and maxi = 127
                    report "tb_forma_onda: la sierra debe ir de -127 a 127" severity error;
            end if;
            if w = 1 or w = 3 then
                assert mini = -127 and maxi = 127
                    report "tb_forma_onda: picos de +-127 incorrectos" severity error;
            end if;
        end loop;

        -- la sierra salta de 127 a -127 al dar la vuelta
        forma <= W_SIERRA;
        fase  <= x"FFFF00";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(signed(muestra)) = 127 report "tb_forma_onda: sierra al final" severity error;
        fase <= x"000000";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(signed(muestra)) = -127 report "tb_forma_onda: sierra al inicio" severity error;

        -- 6) cambio de forma con la misma fase
        fase  <= x"C00000";   -- tres cuartos de periodo
        forma <= W_CUADRADA;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(signed(muestra)) = -127 report "tb_forma_onda: cambio a cuadrada" severity error;
        forma <= W_SENO;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(signed(muestra)) = -127 report "tb_forma_onda: cambio a seno" severity error;
        forma <= W_TRIANGULAR;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert abs (to_integer(signed(muestra))) <= 1 report "tb_forma_onda: cambio a triangular" severity error;

        report "tb_forma_onda: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
