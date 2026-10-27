-- ============================================================
-- graf_pwm.vhd
-- Datos para la grafica del DAC por PWM: una senoidal de 1 kHz y
-- amplitud 100 entra a salida_pwm (una muestra cada 1024 ciclos,
-- como en el sistema). Se registra la salida PWM en cada ciclo
-- durante 2 ms; el filtro RC se calcula despues en Python.
-- Escribe salida/pwm.csv: ciclo;muestra;pwm
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity graf_pwm is
end entity graf_pwm;

architecture sim of graf_pwm is
    constant FS : real := 48828.125;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal muestra : std_logic_vector(7 downto 0) := (others => '0');
    signal pwm     : std_logic;
    signal fin     : boolean := false;
begin

    clk <= not clk after 10 ns when not fin;

    dut : entity work.salida_pwm
        port map (clk => clk, rst => rst, muestra => muestra, pwm => pwm);

    process
        file f     : text open write_mode is "salida/pwm.csv";
        variable l : line;
        variable n : natural := 0;
    begin
        write(l, string'("ciclo;muestra;pwm"));
        writeline(f, l);
        wait for 100 ns;
        wait until rising_edge(clk);
        rst <= '0';
        for c in 0 to 100_000 loop
            if c mod 1024 = 0 then
                muestra <= std_logic_vector(to_signed(
                    integer(100.0 * sin(2.0 * MATH_PI * 1000.0 * real(n) / FS)), 8));
                n := n + 1;
            end if;
            wait until rising_edge(clk);
            wait for 1 ns;
            write(l, c);
            write(l, string'(";"));
            write(l, to_integer(signed(muestra)));
            write(l, string'(";"));
            if pwm = '1' then
                write(l, string'("1"));
            else
                write(l, string'("0"));
            end if;
            writeline(f, l);
        end loop;
        report "graf_pwm: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
