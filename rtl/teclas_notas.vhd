-- ============================================================
-- teclas_notas.vhd
-- Traduce el estado de las 32 teclas a notas y funciones.
-- En cada teclado las tres primeras columnas son notas, en orden
-- de lectura (cromatico), y la cuarta columna son funciones:
--      1  2  3  A        C   C#  D   | A
--      4  5  6  B   ->   D#  E   F   | B
--      7  8  9  C        F#  G   G#  | C
--      *  0  #  D        A   A#  B   | D
-- El teclado 1 toca la octava base y el teclado 2 la siguiente.
-- Nota n = 12 * octava + semitono (synth_pkg).
-- Salidas:
--   notas : hasta 3 notas presionadas, de la mas grave a la mas
--           aguda (nota i en los bits 7i+6..7i; 0 = vacia). Con
--           mas de 3 teclas se quedan las 3 mas graves.
--   func  : pulso de un ciclo al presionar A, B, C, D del teclado 1
--           (bits 0 a 3) y del teclado 2 (bits 4 a 7).
--   ultima: ultima nota presionada (para los displays).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity teclas_notas is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;   -- sincrono, activo en alto
        teclas : in  std_logic_vector(31 downto 0);
        octava : in  std_logic_vector(2 downto 0);
        notas  : out std_logic_vector(20 downto 0);
        func   : out std_logic_vector(7 downto 0);
        ultima : out std_logic_vector(6 downto 0)
    );
end entity teclas_notas;

architecture rtl of teclas_notas is
    signal ant      : std_logic_vector(31 downto 0) := (others => '0');
    signal nn       : std_logic_vector(20 downto 0);
    signal hay_ult  : boolean;
    signal ult      : std_logic_vector(6 downto 0);
    signal fc       : std_logic_vector(7 downto 0);
    signal s_notas  : std_logic_vector(20 downto 0) := (others => '0');
    signal s_func   : std_logic_vector(7 downto 0) := (others => '0');
    signal s_ultima : std_logic_vector(6 downto 0) := (others => '0');

    -- indice de tecla de la nota j (0..23): teclado j/12, semitono j mod 12
    function tecla_de_nota (j : natural) return natural is
        variable t, s : natural;
    begin
        t := j / 12;
        s := j mod 12;
        return 16 * t + 4 * (s / 3) + (s mod 3);
    end function;

    -- indice de tecla de la funcion f (0..7): teclado f/4, fila f mod 4, columna 3
    function tecla_de_func (f : natural) return natural is
    begin
        return 16 * (f / 4) + 4 * (f mod 4) + 3;
    end function;
begin

    -- traduccion (combinacional)
    process (teclas, ant, octava)
        variable cuantas : natural range 0 to 3;
        variable v       : std_logic_vector(20 downto 0);
        variable base    : natural range 0 to 127;
        variable n       : natural range 0 to 127;
        variable hay     : boolean;
        variable u       : natural range 0 to 127;
    begin
        base := 12 * to_integer(unsigned(octava));

        -- hasta 3 notas, de grave a aguda
        v       := (others => '0');
        cuantas := 0;
        for j in 0 to 23 loop
            if teclas(tecla_de_nota(j)) = '1' and cuantas < 3 then
                n := base + j;
                v(7 * cuantas + 6 downto 7 * cuantas) := std_logic_vector(to_unsigned(n, 7));
                cuantas := cuantas + 1;
            end if;
        end loop;
        nn <= v;

        -- ultima nota presionada (la mas aguda si llegan juntas)
        hay := false;
        u   := 0;
        for j in 0 to 23 loop
            if teclas(tecla_de_nota(j)) = '1' and ant(tecla_de_nota(j)) = '0' then
                hay := true;
                u   := base + j;
            end if;
        end loop;
        hay_ult <= hay;
        ult     <= std_logic_vector(to_unsigned(u, 7));

        -- funciones (flanco de subida)
        for f in 0 to 7 loop
            fc(f) <= teclas(tecla_de_func(f)) and not ant(tecla_de_func(f));
        end loop;
    end process;

    -- registros
    process (clk)
    begin
        if rising_edge(clk) then
            ant <= teclas;
            if rst = '1' then
                s_notas  <= (others => '0');
                s_func   <= (others => '0');
                s_ultima <= (others => '0');
            else
                s_notas <= nn;
                s_func  <= fc;
                if hay_ult then
                    s_ultima <= ult;
                end if;
            end if;
        end if;
    end process;

    notas  <= s_notas;
    func   <= s_func;
    ultima <= s_ultima;

end architecture rtl;
