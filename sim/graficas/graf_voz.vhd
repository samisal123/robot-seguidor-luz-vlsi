-- ============================================================
-- graf_voz.vhd
-- Datos para la grafica de una voz: nota A3 (220 Hz), onda
-- cuadrada y triangular, ADSR con attack 50 ms, decay 200 ms,
-- sustain 50 % y release 150 ms. Gate de 10 a 500 ms.
-- Una muestra cada 2 ciclos (el tiempo se cuenta en muestras;
-- t = n / Fs). Escribe salida/voz.csv: n;gate;nivel;cuadrada;triangular
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.synth_pkg.all;

entity graf_voz is
end entity graf_voz;

architecture sim of graf_voz is
    constant FS : real := 48828.125;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal tick_fs : std_logic := '0';
    signal gate    : std_logic := '0';
    signal nota    : std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(45, 7));
    signal m_cua, m_tri : std_logic_vector(7 downto 0);
    signal niv_cua, niv_tri : std_logic_vector(7 downto 0);
    signal fin     : boolean := false;
begin

    clk <= not clk after 10 ns when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            tick_fs <= not tick_fs;
        end if;
    end process;

    v_cua : entity work.voz
        port map (clk => clk, rst => rst, tick_fs => tick_fs, nota => nota, gate => gate,
                  forma => W_CUADRADA, atk => "01", dec => "01", sus => "01", rel => "01",
                  muestra => m_cua, nivel => niv_cua, activa => open);

    v_tri : entity work.voz
        port map (clk => clk, rst => rst, tick_fs => tick_fs, nota => nota, gate => gate,
                  forma => W_TRIANGULAR, atk => "01", dec => "01", sus => "01", rel => "01",
                  muestra => m_tri, nivel => niv_tri, activa => open);

    process
        file f     : text open write_mode is "salida/voz.csv";
        variable l : line;
        variable n : natural := 0;
    begin
        write(l, string'("n;gate;nivel;cuadrada;triangular"));
        writeline(f, l);
        wait for 100 ns;
        rst <= '0';
        while real(n) < 0.75 * FS loop
            -- una lectura por muestra (con un tick de retraso fijo)
            wait until rising_edge(clk) and tick_fs = '1';
            wait for 1 ns;
            n := n + 1;
            if real(n) >= 0.010 * FS and real(n) < 0.500 * FS then
                gate <= '1';
            else
                gate <= '0';
            end if;
            write(l, n);
            write(l, string'(";"));
            write(l, std_logic'image(gate));
            write(l, string'(";"));
            write(l, to_integer(unsigned(niv_cua)));
            write(l, string'(";"));
            write(l, to_integer(signed(m_cua)));
            write(l, string'(";"));
            write(l, to_integer(signed(m_tri)));
            writeline(f, l);
        end loop;
        report "graf_voz: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
