-- ============================================================
-- synth_pkg.vhd
-- Constantes y tablas compartidas del sintetizador. Los puertos
-- de todas las entidades usan solo std_logic y std_logic_vector
-- (para que el Block Editor de Quartus genere sus simbolos);
-- este paquete solo da nombre a los codigos y guarda las tablas.
--
-- Reloj: 25 MHz (el PLL de la Cyclone II lo saca de los 50 MHz
--        del oscilador de la tarjeta).
-- Audio: una muestra cada FS_DIV ciclos de 25 MHz
--        (25e6 / 512 = 48 828.125 muestras por segundo).
-- Notas: n = 12 * octava + semitono (C = 0 ... B = 11); A4 = 57.
--        n = 0 significa "sin nota".
-- DDS:   acumulador de fase de 24 bits; f = inc * Fs / 2**24.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package synth_pkg is

    constant CLK_HZ_SIS : natural := 25_000_000;   -- reloj del sistema
    constant FS_DIV     : natural := 512;          -- ciclos de reloj por muestra

    -- Modos de operacion (el boton MODO los recorre en este orden)
    constant M_INT  : std_logic_vector(1 downto 0) := "00";   -- interpretacion
    constant M_GRA  : std_logic_vector(1 downto 0) := "01";   -- grabacion
    constant M_REP  : std_logic_vector(1 downto 0) := "10";   -- reproduccion
    constant M_CONF : std_logic_vector(1 downto 0) := "11";   -- configuracion

    -- Estado del secuenciador
    constant S_ESPERA      : std_logic_vector(1 downto 0) := "00";
    constant S_GRABANDO    : std_logic_vector(1 downto 0) := "01";
    constant S_REPRODUCE   : std_logic_vector(1 downto 0) := "10";

    -- Formas de onda
    constant W_CUADRADA   : std_logic_vector(1 downto 0) := "00";
    constant W_TRIANGULAR : std_logic_vector(1 downto 0) := "01";
    constant W_SIERRA     : std_logic_vector(1 downto 0) := "10";
    constant W_SENO       : std_logic_vector(1 downto 0) := "11";

    -- Efectos
    constant E_NINGUNO : std_logic_vector(1 downto 0) := "00";
    constant E_TREMOLO : std_logic_vector(1 downto 0) := "01";
    constant E_ECO     : std_logic_vector(1 downto 0) := "10";
    constant E_AMBOS   : std_logic_vector(1 downto 0) := "11";

    -- Parametros del modo configuracion (orden en que se recorren)
    constant P_FORMA   : natural := 0;
    constant P_ATTACK  : natural := 1;
    constant P_DECAY   : natural := 2;
    constant P_SUSTAIN : natural := 3;
    constant P_RELEASE : natural := 4;
    constant P_VOLUMEN : natural := 5;
    constant P_TEMPO   : natural := 6;
    constant P_EFECTO  : natural := 7;

    -- Octava base del teclado 1 (el teclado 2 suena una octava arriba)
    constant OCT_MIN : natural := 2;
    constant OCT_MAX : natural := 6;

    -- Incremento de fase de la nota n (0 = sin nota)
    function inc_nota (n : natural range 0 to 127) return natural;

    -- Tabla de incrementos de las 128 notas, para guardarla como ROM:
    --   constant TABLA : t_tabla_inc := tabla_inc;
    type t_tabla_inc is array (0 to 127) of natural range 0 to 2 ** 24 - 1;
    function tabla_inc return t_tabla_inc;

    -- Seno de 256 puntos, de -127 a 127
    function seno (i : natural range 0 to 255) return integer;

    -- Envolvente ADSR: acumulador de 24 bits (nivel = 8 bits altos).
    -- Paso por muestra para recorrer la escala completa en T ms:
    --   paso = 2**24 / (T * Fs / 1000) = 343 597 / T
    function paso_attack  (sel : std_logic_vector(1 downto 0)) return natural;  -- 2, 50, 200, 800 ms
    function paso_decay   (sel : std_logic_vector(1 downto 0)) return natural;  -- 50, 200, 600, 1500 ms
    function paso_release (sel : std_logic_vector(1 downto 0)) return natural;  -- 20, 150, 500, 1500 ms
    function nivel_sustain(sel : std_logic_vector(1 downto 0)) return natural;  -- 25, 50, 75, 100 %

    -- Metronomo: 60, 90, 120 y 150 BPM
    function periodo_beat_ms (sel : std_logic_vector(1 downto 0)) return natural;
    function bpm (sel : std_logic_vector(1 downto 0)) return natural;

end package synth_pkg;

package body synth_pkg is

    type t_inc12 is array (0 to 11) of natural;
    -- Octava 7 (C7 a B7); las octavas de abajo se obtienen con
    -- corrimientos a la derecha, sin perder precision apreciable
    constant INC_OCT7 : t_inc12 := (
        719151, 761914, 807220, 855219, 906073, 959951,
        1017033, 1077509, 1141581, 1209463, 1281381, 1357576);

    -- inc = INC_OCT7(semitono) / 2**(7 - octava); se divide entre 2
    -- una vez por cada octava por debajo de la 7
    function inc_nota (n : natural range 0 to 127) return natural is
        variable oct : natural range 0 to 10;
        variable v   : natural;
    begin
        if n = 0 or n > 95 then
            return 0;
        end if;
        oct := n / 12;
        v   := INC_OCT7(n mod 12);
        for k in 1 to 7 loop
            if oct + k <= 7 then
                v := v / 2;
            end if;
        end loop;
        return v;
    end function;

    function tabla_inc return t_tabla_inc is
        variable t : t_tabla_inc;
    begin
        for n in 0 to 127 loop
            t(n) := inc_nota(n);
        end loop;
        return t;
    end function;

    type t_seno is array (0 to 255) of integer range -127 to 127;
    constant TABLA_SENO : t_seno := (
        0, 3, 6, 9, 12, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46,
        49, 51, 54, 57, 60, 63, 65, 68, 71, 73, 76, 78, 81, 83, 85, 88,
        90, 92, 94, 96, 98, 100, 102, 104, 106, 107, 109, 111, 112, 113, 115, 116,
        117, 118, 120, 121, 122, 122, 123, 124, 125, 125, 126, 126, 126, 127, 127, 127,
        127, 127, 127, 127, 126, 126, 126, 125, 125, 124, 123, 122, 122, 121, 120, 118,
        117, 116, 115, 113, 112, 111, 109, 107, 106, 104, 102, 100, 98, 96, 94, 92,
        90, 88, 85, 83, 81, 78, 76, 73, 71, 68, 65, 63, 60, 57, 54, 51,
        49, 46, 43, 40, 37, 34, 31, 28, 25, 22, 19, 16, 12, 9, 6, 3,
        0, -3, -6, -9, -12, -16, -19, -22, -25, -28, -31, -34, -37, -40, -43, -46,
        -49, -51, -54, -57, -60, -63, -65, -68, -71, -73, -76, -78, -81, -83, -85, -88,
        -90, -92, -94, -96, -98, -100, -102, -104, -106, -107, -109, -111, -112, -113, -115, -116,
        -117, -118, -120, -121, -122, -122, -123, -124, -125, -125, -126, -126, -126, -127, -127, -127,
        -127, -127, -127, -127, -126, -126, -126, -125, -125, -124, -123, -122, -122, -121, -120, -118,
        -117, -116, -115, -113, -112, -111, -109, -107, -106, -104, -102, -100, -98, -96, -94, -92,
        -90, -88, -85, -83, -81, -78, -76, -73, -71, -68, -65, -63, -60, -57, -54, -51,
        -49, -46, -43, -40, -37, -34, -31, -28, -25, -22, -19, -16, -12, -9, -6, -3);

    function seno (i : natural range 0 to 255) return integer is
    begin
        return TABLA_SENO(i);
    end function;

    function paso_attack (sel : std_logic_vector(1 downto 0)) return natural is
    begin
        case sel is
            when "00"   => return 343597 / 2;
            when "01"   => return 343597 / 50;
            when "10"   => return 343597 / 200;
            when others => return 343597 / 800;
        end case;
    end function;

    function paso_decay (sel : std_logic_vector(1 downto 0)) return natural is
    begin
        case sel is
            when "00"   => return 343597 / 50;
            when "01"   => return 343597 / 200;
            when "10"   => return 343597 / 600;
            when others => return 343597 / 1500;
        end case;
    end function;

    function paso_release (sel : std_logic_vector(1 downto 0)) return natural is
    begin
        case sel is
            when "00"   => return 343597 / 20;
            when "01"   => return 343597 / 150;
            when "10"   => return 343597 / 500;
            when others => return 343597 / 1500;
        end case;
    end function;

    function nivel_sustain (sel : std_logic_vector(1 downto 0)) return natural is
    begin
        case sel is
            when "00"   => return 64;
            when "01"   => return 128;
            when "10"   => return 192;
            when others => return 255;
        end case;
    end function;

    function periodo_beat_ms (sel : std_logic_vector(1 downto 0)) return natural is
    begin
        case sel is
            when "00"   => return 1000;   -- 60 BPM
            when "01"   => return 667;    -- 90 BPM
            when "10"   => return 500;    -- 120 BPM
            when others => return 400;    -- 150 BPM
        end case;
    end function;

    function bpm (sel : std_logic_vector(1 downto 0)) return natural is
    begin
        case sel is
            when "00"   => return 60;
            when "01"   => return 90;
            when "10"   => return 120;
            when others => return 150;
        end case;
    end function;

end package body synth_pkg;
