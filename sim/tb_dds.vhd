-- ============================================================
-- tb_dds.vhd
-- Prueba del acumulador de fase.
-- Revisa:
--   1) fase = N * inc mod 2**24 despues de N muestras
--   2) solo avanza con tick_fs
--   3) al cambiar inc la fase sigue desde donde iba (sin saltos)
--   4) frecuencia: con el incremento de A4 (synth_pkg), en un
--      segundo de muestras (48 828) da 440 vueltas
--   5) incrementos de todas las notas: error < 0.1 % respecto a
--      440 * 2**((n - 57) / 12)
--   6) reset
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.synth_pkg.all;

entity tb_dds is
end entity tb_dds;

architecture sim of tb_dds is
    constant T_CLK : time := 20 ns;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal tick_fs : std_logic := '0';
    signal inc     : std_logic_vector(23 downto 0) := (others => '0');
    signal fase    : std_logic_vector(23 downto 0);
    signal fin     : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.dds
        port map (
            clk     => clk,
            rst     => rst,
            tick_fs => tick_fs,
            inc     => inc,
            fase    => fase
        );

    estimulo : process
        procedure muestras (n : natural) is
        begin
            for i in 1 to n loop
                tick_fs <= '1';
                wait until rising_edge(clk);
                tick_fs <= '0';
                wait until rising_edge(clk);
            end loop;
        end procedure;

        variable esperado : unsigned(23 downto 0);
        variable vueltas  : natural;
        variable ant      : std_logic;
        variable f_real   : real;
        variable f_ideal  : real;
    begin
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';
        wait for 1 ns;
        assert unsigned(fase) = 0 report "tb_dds: la fase debe iniciar en 0" severity error;

        -- 1) N muestras
        inc <= std_logic_vector(to_unsigned(123457, 24));
        muestras(1000);
        esperado := to_unsigned((1000 * 123457) mod 2 ** 24, 24);
        assert unsigned(fase) = esperado
            report "tb_dds: fase tras 1000 muestras incorrecta" severity error;

        -- 2) sin tick no avanza
        for i in 1 to 50 loop
            wait until rising_edge(clk);
        end loop;
        assert unsigned(fase) = esperado
            report "tb_dds: la fase avanzo sin tick_fs" severity error;

        -- 3) cambio de incremento sin saltos
        inc <= std_logic_vector(to_unsigned(2 ** 23 + 5, 24));
        muestras(3);
        esperado := esperado + to_unsigned(3 * (2 ** 23 + 5) mod 2 ** 24, 24);
        assert unsigned(fase) = esperado
            report "tb_dds: la fase salto al cambiar el incremento" severity error;

        -- 4) A4 durante un segundo de muestras
        rst <= '1';
        wait until rising_edge(clk);
        rst <= '0';
        inc <= std_logic_vector(to_unsigned(inc_nota(57), 24));
        vueltas := 0;
        ant := '0';
        for i in 1 to 48828 loop
            tick_fs <= '1';
            wait until rising_edge(clk);
            tick_fs <= '0';
            wait for 1 ns;
            if ant = '1' and fase(23) = '0' then
                vueltas := vueltas + 1;
            end if;
            ant := fase(23);
        end loop;
        assert vueltas = 440 or vueltas = 439
            report "tb_dds: A4 dio " & integer'image(vueltas) & " vueltas en 1 s" severity error;

        -- 5) incrementos de todas las notas que usa el teclado (24 a 95)
        assert inc_nota(0) = 0 report "tb_dds: la nota 0 debe ser silencio" severity error;
        for n in 24 to 95 loop
            f_real  := real(inc_nota(n)) * 48828.125 / 16777216.0;
            f_ideal := 440.0 * 2.0 ** (real(n - 57) / 12.0);
            assert abs (f_real - f_ideal) / f_ideal < 0.001
                report "tb_dds: la nota " & integer'image(n) & " esta desafinada" severity error;
        end loop;

        report "tb_dds: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
