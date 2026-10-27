-- ============================================================
-- display_hex.vhd
-- Interfaz de usuario en los 6 displays de 7 segmentos.
--   HEX5-HEX4: modo  In (interpretacion), Gr (grabacion),
--              rP (reproduccion), CF (configuracion)
--   Interpretacion: HEX3-HEX2 = o y la octava base del teclado 1
--                   HEX1-HEX0 = ultima nota tocada (letra y
--                   octava; el punto indica sostenido, C. = C#)
--   Grabacion y reproduccion: HEX2-HEX0 = numero de eventos
--                   (grabando o en espera) o evento que suena
--                   (reproduciendo)
--   Configuracion:  HEX3-HEX2 = parametro: Fo forma, At attack,
--                   dE decay, Su sustain, rE release, Uo volumen,
--                   tE tempo, EF efecto
--                   HEX0 = valor del parametro
-- Segmentos de la DE10-Lite: bit 0 = a ... bit 6 = g, bit 7 =
-- punto, activos en bajo. Las salidas van registradas.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity display_hex is
    port (
        clk       : in  std_logic;
        modo      : in  std_logic_vector(1 downto 0);
        parametro : in  std_logic_vector(2 downto 0);
        forma     : in  std_logic_vector(1 downto 0);
        atk       : in  std_logic_vector(1 downto 0);
        dec       : in  std_logic_vector(1 downto 0);
        sus       : in  std_logic_vector(1 downto 0);
        rel       : in  std_logic_vector(1 downto 0);
        volumen   : in  std_logic_vector(2 downto 0);
        tempo     : in  std_logic_vector(1 downto 0);
        efecto    : in  std_logic_vector(1 downto 0);
        octava    : in  std_logic_vector(2 downto 0);
        ultima    : in  std_logic_vector(6 downto 0);
        posicion  : in  std_logic_vector(8 downto 0);
        hex0      : out std_logic_vector(7 downto 0);
        hex1      : out std_logic_vector(7 downto 0);
        hex2      : out std_logic_vector(7 downto 0);
        hex3      : out std_logic_vector(7 downto 0);
        hex4      : out std_logic_vector(7 downto 0);
        hex5      : out std_logic_vector(7 downto 0)
    );
end entity display_hex;

architecture rtl of display_hex is
    subtype t_seg is std_logic_vector(7 downto 0);   -- activo en alto: dp g f e d c b a

    constant L_NADA : t_seg := "00000000";
    constant L_GUION: t_seg := "01000000";
    constant L_A    : t_seg := "01110111";
    constant L_B    : t_seg := "01111100";   -- b
    constant L_C    : t_seg := "00111001";
    constant L_D    : t_seg := "01011110";   -- d
    constant L_E    : t_seg := "01111001";
    constant L_F    : t_seg := "01110001";
    constant L_G    : t_seg := "00111101";
    constant L_I    : t_seg := "00110000";
    constant L_N    : t_seg := "01010100";   -- n
    constant L_O    : t_seg := "01011100";   -- o
    constant L_P    : t_seg := "01110011";
    constant L_R    : t_seg := "01010000";   -- r
    constant L_S    : t_seg := "01101101";
    constant L_T    : t_seg := "01111000";   -- t
    constant L_U    : t_seg := "00111110";   -- U
    constant L_UM   : t_seg := "00011100";   -- u
    constant PUNTO  : t_seg := "10000000";

    type t_tabla is array (0 to 9) of t_seg;
    constant DIGITO : t_tabla := (
        "00111111", "00000110", "01011011", "01001111", "01100110",
        "01101101", "01111101", "00000111", "01111111", "01101111");

    -- letra de cada semitono (C = 0 ... B = 11); los sostenidos
    -- usan la letra de abajo y llevan punto
    type t_letras is array (0 to 11) of t_seg;
    constant LETRA : t_letras := (
        L_C, L_C, L_D, L_D, L_E, L_F, L_F, L_G, L_G, L_A, L_A, L_B);
    constant SOSTENIDO : std_logic_vector(0 to 11) := "010100101010";

    signal h0, h1, h2, h3, h4, h5 : t_seg := (others => '0');   -- registros
    signal c0, c1, c2, c3, c4, c5 : t_seg;                      -- combinacional
begin

    -- contenido de cada display (combinacional)
    process (modo, parametro, forma, atk, dec, sus, rel, volumen, tempo, efecto,
             octava, ultima, posicion)
        variable n, oct, semi : natural range 0 to 127;
        variable v            : natural range 0 to 511;
        variable c, d, u      : natural range 0 to 9;
        variable val          : natural range 0 to 7;
    begin
        -- modo
        case modo is
            when M_INT  => c5 <= L_I; c4 <= L_N;
            when M_GRA  => c5 <= L_G; c4 <= L_R;
            when M_REP  => c5 <= L_R; c4 <= L_P;
            when others => c5 <= L_C; c4 <= L_F;
        end case;

        -- numero de 3 cifras sin ceros a la izquierda
        v := to_integer(unsigned(posicion));
        c := (v / 100) mod 10;
        d := (v / 10) mod 10;
        u := v mod 10;

        case modo is
            when M_INT =>
                c3 <= L_O;
                c2 <= DIGITO(to_integer(unsigned(octava)));
                n := to_integer(unsigned(ultima));
                if n = 0 then
                    c1 <= L_GUION;
                    c0 <= L_GUION;
                else
                    oct  := n / 12;
                    semi := n mod 12;
                    if SOSTENIDO(semi) = '1' then
                        c1 <= LETRA(semi) or PUNTO;
                    else
                        c1 <= LETRA(semi);
                    end if;
                    c0 <= DIGITO(oct mod 10);
                end if;

            when M_GRA | M_REP =>
                c3 <= L_NADA;
                if c = 0 then
                    c2 <= L_NADA;
                else
                    c2 <= DIGITO(c);
                end if;
                if c = 0 and d = 0 then
                    c1 <= L_NADA;
                else
                    c1 <= DIGITO(d);
                end if;
                c0 <= DIGITO(u);

            when others =>
                case to_integer(unsigned(parametro)) is
                    when P_FORMA   => c3 <= L_F; c2 <= L_O;  val := to_integer(unsigned(forma));
                    when P_ATTACK  => c3 <= L_A; c2 <= L_T;  val := to_integer(unsigned(atk));
                    when P_DECAY   => c3 <= L_D; c2 <= L_E;  val := to_integer(unsigned(dec));
                    when P_SUSTAIN => c3 <= L_S; c2 <= L_UM; val := to_integer(unsigned(sus));
                    when P_RELEASE => c3 <= L_R; c2 <= L_E;  val := to_integer(unsigned(rel));
                    when P_VOLUMEN => c3 <= L_U; c2 <= L_O;  val := to_integer(unsigned(volumen));
                    when P_TEMPO   => c3 <= L_T; c2 <= L_E;  val := to_integer(unsigned(tempo));
                    when others    => c3 <= L_E; c2 <= L_F;  val := to_integer(unsigned(efecto));
                end case;
                c1 <= L_NADA;
                c0 <= DIGITO(val);
        end case;
    end process;

    -- salidas registradas
    process (clk)
    begin
        if rising_edge(clk) then
            h0 <= c0;
            h1 <= c1;
            h2 <= c2;
            h3 <= c3;
            h4 <= c4;
            h5 <= c5;
        end if;
    end process;

    -- la DE10-Lite enciende cada segmento con '0'
    hex0 <= not h0;
    hex1 <= not h1;
    hex2 <= not h2;
    hex3 <= not h3;
    hex4 <= not h4;
    hex5 <= not h5;

end architecture rtl;
