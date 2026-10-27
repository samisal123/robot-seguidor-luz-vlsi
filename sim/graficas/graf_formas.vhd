-- ============================================================
-- graf_formas.vhd
-- Datos para la grafica de las 4 formas de onda: recorre dos
-- periodos de la fase (512 puntos) con cada forma.
-- Escribe salida/formas.csv: k;cuadrada;triangular;sierra;seno
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.synth_pkg.all;

entity graf_formas is
end entity graf_formas;

architecture sim of graf_formas is
    signal clk  : std_logic := '0';
    signal fase : std_logic_vector(23 downto 0) := (others => '0');
    signal m0, m1, m2, m3 : std_logic_vector(7 downto 0);
    signal fin  : boolean := false;
begin

    clk <= not clk after 10 ns when not fin;

    f0 : entity work.forma_onda port map (clk => clk, forma => W_CUADRADA, fase => fase, muestra => m0);
    f1 : entity work.forma_onda port map (clk => clk, forma => W_TRIANGULAR, fase => fase, muestra => m1);
    f2 : entity work.forma_onda port map (clk => clk, forma => W_SIERRA, fase => fase, muestra => m2);
    f3 : entity work.forma_onda port map (clk => clk, forma => W_SENO, fase => fase, muestra => m3);

    process
        file f     : text open write_mode is "salida/formas.csv";
        variable l : line;
    begin
        write(l, string'("k;cuadrada;triangular;sierra;seno"));
        writeline(f, l);
        for k in 0 to 511 loop
            fase <= std_logic_vector(to_unsigned((k mod 256) * 65536, 24));
            wait until rising_edge(clk);
            wait for 1 ns;
            write(l, k);
            write(l, string'(";"));
            write(l, to_integer(signed(m0)));
            write(l, string'(";"));
            write(l, to_integer(signed(m1)));
            write(l, string'(";"));
            write(l, to_integer(signed(m2)));
            write(l, string'(";"));
            write(l, to_integer(signed(m3)));
            writeline(f, l);
        end loop;
        report "graf_formas: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
