-- ============================================================
-- tb_voz.vhd
-- Prueba de una voz completa (ROM de incrementos, DDS, forma de
-- onda, ADSR y multiplicacion). Una muestra cada 2 ciclos.
-- Revisa:
--   1) A4 (nota 57) en onda cuadrada: periodo de Fs / 440 =
--      110.97 muestras (se miden 100 periodos)
--   2) amplitud con sustain de 255 (+-126) y de 128 (+-63)
--   3) cambio de nota en operacion: A5 (nota 69) da la mitad del
--      periodo, con la triangular
--   4) al soltar, despues del release la salida es 0 y activa 0
--   5) la nota 0 no suena
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_voz is
end entity tb_voz;

architecture sim of tb_voz is
    constant T_CLK : time := 20 ns;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal tick_fs : std_logic := '0';
    signal nota    : std_logic_vector(6 downto 0) := (others => '0');
    signal gate    : std_logic := '0';
    signal forma   : std_logic_vector(1 downto 0) := W_CUADRADA;
    signal atk     : std_logic_vector(1 downto 0) := "00";
    signal dec     : std_logic_vector(1 downto 0) := "00";
    signal sus     : std_logic_vector(1 downto 0) := "11";
    signal rel     : std_logic_vector(1 downto 0) := "00";
    signal muestra : std_logic_vector(7 downto 0);
    signal nivel   : std_logic_vector(7 downto 0);
    signal activa  : std_logic;
    signal fin     : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            tick_fs <= not tick_fs;
        end if;
    end process;

    dut : entity work.voz
        port map (
            clk     => clk,
            rst     => rst,
            tick_fs => tick_fs,
            nota    => nota,
            gate    => gate,
            forma   => forma,
            atk     => atk,
            dec     => dec,
            sus     => sus,
            rel     => rel,
            muestra => muestra,
            nivel   => nivel,
            activa  => activa
        );

    estimulo : process
        variable m, ant  : integer;
        variable maxi    : integer;
        variable mini    : integer;
        variable cruces  : natural;
        variable n       : natural;
        variable inicio  : natural;
        variable periodo : real;

        procedure una_muestra is
        begin
            wait until rising_edge(clk) and tick_fs = '1';
            wait for 1 ns;
        end procedure;

        -- mide en muestras la duracion de p periodos (cruces por
        -- cero hacia arriba) y los picos de la senal
        procedure mide (p : natural; per : out real; pmax, pmin : out integer) is
            variable c, k, k0 : natural := 0;
            variable a, v     : integer;
            variable hi, lo   : integer;
        begin
            hi := -1000;
            lo := 1000;
            a  := to_integer(signed(muestra));
            k  := 0;
            k0 := 0;
            while c <= p and k < 200000 loop
                una_muestra;
                k := k + 1;
                v := to_integer(signed(muestra));
                if a < 0 and v >= 0 then
                    if c = 0 then
                        k0 := k;
                    end if;
                    c := c + 1;
                end if;
                if c > 0 then
                    if v > hi then hi := v; end if;
                    if v < lo then lo := v; end if;
                end if;
                a := v;
            end loop;
            per  := real(k - k0) / real(p);
            pmax := hi;
            pmin := lo;
        end procedure;
    begin
        rst <= '1';
        wait for 10 * T_CLK;
        wait until rising_edge(clk);
        rst <= '0';

        -- 5) nota 0: no avanza la fase, la salida es constante
        nota <= (others => '0');
        gate <= '1';
        for i in 1 to 300 loop
            una_muestra;
        end loop;
        ant := to_integer(signed(muestra));
        for i in 1 to 300 loop
            una_muestra;
            assert to_integer(signed(muestra)) = ant
                report "tb_voz: la nota 0 no debe oscilar" severity error;
        end loop;
        gate <= '0';
        for i in 1 to 2000 loop
            una_muestra;
        end loop;

        -- 1) y 2) A4 cuadrada, sustain 255
        nota <= std_logic_vector(to_unsigned(57, 7));
        sus  <= "11";
        gate <= '1';
        for i in 1 to 500 loop
            una_muestra;
        end loop;
        mide(100, periodo, maxi, mini);
        assert abs (periodo - 48828.125 / 440.0) < 0.05
            report "tb_voz: periodo de A4 incorrecto" severity error;
        assert maxi >= 125 and maxi <= 127 and mini <= -125 and mini >= -127
            report "tb_voz: amplitud con sustain 255 incorrecta" severity error;

        -- sustain de 128 (cambio en operacion)
        sus <= "01";
        for i in 1 to 5000 loop
            una_muestra;
        end loop;
        mide(20, periodo, maxi, mini);
        assert maxi >= 62 and maxi <= 64 and mini <= -62 and mini >= -64
            report "tb_voz: amplitud con sustain 128 incorrecta" severity error;

        -- 3) cambio de nota y de forma sin soltar
        nota  <= std_logic_vector(to_unsigned(69, 7));
        forma <= W_TRIANGULAR;
        for i in 1 to 200 loop
            una_muestra;
        end loop;
        mide(100, periodo, maxi, mini);
        assert abs (periodo - 48828.125 / 880.0) < 0.05
            report "tb_voz: periodo de A5 incorrecto" severity error;

        -- 4) soltar: tras el release (20 ms = 977 muestras) queda en 0
        gate <= '0';
        for i in 1 to 1200 loop
            una_muestra;
        end loop;
        assert activa = '0' and unsigned(nivel) = 0
            report "tb_voz: tras el release la voz debe quedar inactiva" severity error;
        for i in 1 to 300 loop
            una_muestra;
            assert to_integer(signed(muestra)) = 0
                report "tb_voz: una voz inactiva debe dar 0" severity error;
        end loop;

        report "tb_voz: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
