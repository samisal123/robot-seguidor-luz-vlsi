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
--
-- Las notas se buscan en serie, una tecla por ciclo, con un solo
-- sumador (base + j) en lugar de 24 comparaciones en paralelo:
--   ciclo 24     copia las 24 teclas de nota (foto) y la octava,
--                publica el resultado anterior y reinicia la busqueda
--   ciclos 0-23  si la tecla j de la foto esta presionada y aun hay
--                lugar, guarda base + j en el siguiente lugar
-- Una vuelta dura 25 ciclos (1 us a 25 MHz); las teclas cambian
-- cada milisegundo, asi que la latencia no se nota.
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
        func   : out std_logic_vector(7 downto 0)
    );
end entity teclas_notas;

architecture rtl of teclas_notas is
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

    subtype t_nota is unsigned(6 downto 0);
    type t_lugares is array (0 to 2) of t_nota;

    signal j       : natural range 0 to 24 := 24;
    signal foto    : std_logic_vector(23 downto 0) := (others => '0');   -- nota j en el bit j
    signal base    : t_nota := (others => '0');
    signal lugar   : t_lugares := (others => (others => '0'));
    signal cuantas : natural range 0 to 3 := 0;

    signal f_ant   : std_logic_vector(7 downto 0) := (others => '0');
    signal f_now   : std_logic_vector(7 downto 0);
    signal s_notas : std_logic_vector(20 downto 0) := (others => '0');
    signal s_func  : std_logic_vector(7 downto 0) := (others => '0');
begin

    -- teclas de funcion en orden de bit
    gen_func : for f in 0 to 7 generate
        f_now(f) <= teclas(tecla_de_func(f));
    end generate;

    process (clk)
        variable n : t_nota;
    begin
        if rising_edge(clk) then
            -- funciones: flanco de subida, un ciclo
            f_ant  <= f_now;
            s_func <= f_now and not f_ant;

            if rst = '1' then
                j       <= 24;
                foto    <= (others => '0');
                lugar   <= (others => (others => '0'));
                cuantas <= 0;
                s_notas <= (others => '0');
                s_func  <= (others => '0');
            elsif j = 24 then
                -- publica la busqueda anterior y toma la foto nueva
                s_notas <= std_logic_vector(lugar(2)) & std_logic_vector(lugar(1))
                           & std_logic_vector(lugar(0));
                for k in 0 to 23 loop
                    foto(k) <= teclas(tecla_de_nota(k));
                end loop;
                base    <= to_unsigned(12 * to_integer(unsigned(octava)), 7);
                lugar   <= (others => (others => '0'));
                cuantas <= 0;
                j       <= 0;
            else
                -- una tecla por ciclo, de la mas grave a la mas aguda
                if foto(j) = '1' and cuantas < 3 then
                    n := base + to_unsigned(j, 7);
                    lugar(cuantas) <= n;
                    cuantas <= cuantas + 1;
                end if;
                j <= j + 1;
            end if;
        end if;
    end process;

    notas <= s_notas;
    func  <= s_func;

end architecture rtl;
