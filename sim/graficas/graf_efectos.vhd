-- ============================================================
-- graf_efectos.vhd
-- Datos para la grafica de los efectos:
--   tremolo: un tono de 440 Hz de amplitud 1000 durante 0.6 s
--   eco: una rafaga de 60 ms del mismo tono y luego silencio
-- Muestras de 12 bits (escala completa +-2032), una cada 8
-- ciclos. Escribe salida/efectos.csv: n;x;tremolo;x_eco;eco
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity graf_efectos is
end entity graf_efectos;

architecture sim of graf_efectos is
    constant FS : real := 48828.125;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal valida  : std_logic := '0';
    signal x_t, x_e : std_logic_vector(11 downto 0) := (others => '0');
    signal y_t, y_e : std_logic_vector(11 downto 0);
    signal fin     : boolean := false;
begin

    clk <= not clk after 10 ns when not fin;

    u_tre : entity work.tremolo
        port map (clk => clk, rst => rst, activo => '1', ent_valida => valida, x => x_t,
                  y => y_t, sal_valida => open);

    u_eco : entity work.eco
        port map (clk => clk, rst => rst, activo => '1', ent_valida => valida, x => x_e,
                  y => y_e, sal_valida => open, satura => open);

    process
        file f     : text open write_mode is "salida/efectos.csv";
        variable l : line;
        variable v : integer;
    begin
        write(l, string'("n;x;tremolo;x_eco;eco"));
        writeline(f, l);
        wait for 100 ns;
        wait until rising_edge(clk);
        rst <= '0';
        for n in 0 to integer(0.6 * FS) loop
            v := integer(1000.0 * sin(2.0 * MATH_PI * 440.0 * real(n) / FS));
            x_t <= std_logic_vector(to_signed(v, 12));
            if real(n) < 0.060 * FS then
                x_e <= std_logic_vector(to_signed(v, 12));
            else
                x_e <= (others => '0');
            end if;
            valida <= '1';
            wait until rising_edge(clk);
            valida <= '0';
            for c in 1 to 7 loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
            write(l, n);
            write(l, string'(";"));
            write(l, to_integer(signed(x_t)));
            write(l, string'(";"));
            write(l, to_integer(signed(y_t)));
            write(l, string'(";"));
            write(l, to_integer(signed(x_e)));
            write(l, string'(";"));
            write(l, to_integer(signed(y_e)));
            writeline(f, l);
        end loop;
        report "graf_efectos: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
