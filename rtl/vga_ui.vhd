-- ============================================================
-- vga_ui.vhd
-- Interfaz grafica VGA del sintetizador: 640x480 a 60 Hz con
-- 4 bits por color (DAC de resistencias de la DE10-Lite).
--
-- Pantalla (x, y en pixeles; el texto va en una cuadricula de
-- celdas de 12x16 con letras 5x7 al doble de tamano):
--   y   0- 63  Banda del modo, de color segun el modo (azul
--              INTERPRETACION, rojo GRABACION, verde REPRODUCCION,
--              naranja CONFIGURACION), con el nombre del modo en
--              letras x4. A la derecha: METRONOMO ON/OFF, el tempo
--              en BPM y un foco que se enciende DESTELLO ciclos en
--              cada tiempo (verde; rojo en el tiempo con acento).
--   y  80- 95  TECLADO 1 y TECLADO 2 sobre su octava.
--   y  96-229  Piano de dos octavas (14 blancas, 10 negras) desde
--              la nota octava*12. La tecla de cada nota que suena
--              (gate en 1) se pinta del color de su voz (V1
--              naranja, V2 verde, V3 azul). Las teclas C llevan
--              C<octava> y C<octava+1>.
--   y 234-387  Tres paneles:
--              PARAMETROS: forma, attack, decay, sustain, release,
--                volumen (con medidor de 4 segmentos), tempo y
--                efecto. En CONFIGURACION el renglon del parametro
--                elegido se resalta en amarillo con una flecha.
--              FORMA DE ONDA: un periodo de la forma elegida
--                (calculado igual que forma_onda) y su nombre.
--              VOCES: nota de cada voz (gris si no tiene gate) y
--                barra de su nivel de envolvente; octava base.
--   y 392-455  SECUENCIADOR: estado (EN ESPERA, GRABANDO con punto
--              rojo que parpadea, REPRODUCIENDO), EVENTOS n/256,
--              barra (AVANCE posicion/eventos al reproducir;
--              MEMORIA eventos/256 si no) y POS n.
--   y 464-477  Pie de pagina.
--
-- Tiempos: pixel de 25 MHz = una habilitacion (pix_en) cada dos
-- ciclos de 50 MHz. Horizontal 640 + 16 + 96 + 48 = 800 pixeles,
-- vertical 480 + 10 + 2 + 33 = 525 lineas, sincronias en bajo.
-- Fuera de la zona visible el color es 0.
--
-- Las entradas se copian una vez por cuadro (al inicio de la
-- ultima linea, antes de la zona visible), asi el cuadro sale
-- completo con los mismos datos. En esa copia se decodifican las
-- notas, se calcula el umbral de la barra y arranca la conversion
-- a BCD de eventos y posicion (doble-dabble, un bit por ciclo).
-- El pulso beat se atiende en cada ciclo: arranca la cuenta del
-- foco, que el cuadro siguiente muestra encendido.
--
-- Tuberia de 4 etapas, todas con pix_en (los registros cambian
-- cada 40 ns; la logica se reparte para que cada etapa sea corta):
--   1 coordenadas y geometria: zona de la pantalla, celda de texto,
--     celda del titulo, tecla blanca, banderas de los graficos
--     (foco, caja de la onda, barras) y producto de la barra.
--   2 contenido: codigo del caracter de la cuadricula, tecla negra
--     o blanca y voz que la toca, linea de la onda, rellenos; un
--     color por zona.
--   3 color de fondo segun la zona y letra que toca (titulo,
--     etiqueta del piano o cuadricula).
--   4 fuente: lee la fila del caracter y elige el color final.
-- HSYNC y VSYNC pasan por las mismas 4 etapas, asi que siguen
-- alineadas con el color.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;
use work.fuente_5x7.all;

entity vga_ui is
    generic (
        DESTELLO : natural := 5_000_000;   -- ciclos encendido del foco (100 ms)
        PARPADEO : natural := 4            -- bit del contador de cuadros del parpadeo (4: ~0.5 s)
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        modo       : in  std_logic_vector(1 downto 0);
        estado_sec : in  std_logic_vector(1 downto 0);
        forma      : in  std_logic_vector(1 downto 0);
        atk        : in  std_logic_vector(1 downto 0);
        dec        : in  std_logic_vector(1 downto 0);
        sus        : in  std_logic_vector(1 downto 0);
        rel        : in  std_logic_vector(1 downto 0);
        volumen    : in  std_logic_vector(2 downto 0);   -- 0 a 4
        tempo      : in  std_logic_vector(1 downto 0);
        efecto     : in  std_logic_vector(1 downto 0);
        metro_on   : in  std_logic;
        beat       : in  std_logic;   -- pulso de un ciclo por tiempo
        acento     : in  std_logic;   -- junto con beat en el tiempo fuerte
        octava     : in  std_logic_vector(2 downto 0);
        notas      : in  std_logic_vector(20 downto 0);  -- voz i en 7i+6..7i
        gates      : in  std_logic_vector(2 downto 0);
        niveles    : in  std_logic_vector(23 downto 0);  -- voz i en 8i+7..8i
        parametro  : in  std_logic_vector(2 downto 0);
        eventos    : in  std_logic_vector(8 downto 0);
        posicion   : in  std_logic_vector(8 downto 0);
        vga_r      : out std_logic_vector(3 downto 0);
        vga_g      : out std_logic_vector(3 downto 0);
        vga_b      : out std_logic_vector(3 downto 0);
        vga_hs     : out std_logic;
        vga_vs     : out std_logic
    );
end entity vga_ui;

architecture rtl of vga_ui is

    ------------------------------------------------------------
    -- Tiempos VGA 640x480 a 60 Hz
    ------------------------------------------------------------
    constant H_VIS : natural := 640;
    constant H_FP  : natural := 16;
    constant H_SY  : natural := 96;
    constant H_TOT : natural := 800;
    constant V_VIS : natural := 480;
    constant V_FP  : natural := 10;
    constant V_SY  : natural := 2;
    constant V_TOT : natural := 525;

    ------------------------------------------------------------
    -- Geometria (pixeles; los rangos x0..x1 son inclusivos)
    ------------------------------------------------------------
    constant BANDA_Y1 : natural := 64;                      -- banda: y < 64
    constant TIT_X    : natural := 24;                      -- titulo x4, celdas de 24x32
    constant TIT_Y    : natural := 18;
    constant TIT_LEN  : natural := 14;
    constant FOCO_X   : natural := 596;                     -- foco: circulo de 32x32
    constant FOCO_Y   : natural := 16;
    constant RECU_X0  : natural := 592;                     -- recuadro del foco
    constant RECU_X1  : natural := 631;
    constant RECU_Y0  : natural := 12;
    constant RECU_Y1  : natural := 51;
    constant PIA_X    : natural := 40;                      -- piano: blancas de 40x120
    constant PIA_Y    : natural := 104;
    constant PIA_ANCHO : natural := 14 * 40;
    constant NEGRA_ALTO : natural := 72;                    -- negras de 24x72
    constant PL_X0 : natural := 6;                          -- panel PARAMETROS
    constant PL_X1 : natural := 261;
    constant PM_X0 : natural := 266;                        -- panel FORMA DE ONDA
    constant PM_X1 : natural := 433;
    constant PR_X0 : natural := 438;                        -- panel VOCES
    constant PR_X1 : natural := 633;
    constant PA_Y0 : natural := 234;                        -- alto de los tres paneles
    constant PA_Y1 : natural := 387;
    constant PS_Y0 : natural := 392;                        -- panel SECUENCIADOR (x de PL_X0 a PR_X1)
    constant PS_Y1 : natural := 455;
    constant ONDA_X : natural := 288;                       -- caja de la onda: 128x96
    constant ONDA_Y : natural := 264;
    constant VOL_X  : natural := 144;                       -- medidor de volumen
    constant VOL_Y  : natural := 339;
    constant NIV_X  : natural := 445;                       -- barras de nivel: 128 pixeles
    constant NIV_Y  : natural := 276;                       -- voz v en NIV_Y + 32 v
    constant REC_X  : natural := 349;                       -- punto de grabacion 10x10
    constant REC_Y  : natural := 403;
    constant BAR_X  : natural := 120;                       -- barra del secuenciador
    constant BAR_W  : natural := 384;
    constant BAR_Y  : natural := 434;

    ------------------------------------------------------------
    -- Colores R G B de 4 bits
    ------------------------------------------------------------
    subtype t_color is std_logic_vector(11 downto 0);
    type t_colores is array (natural range <>) of t_color;

    constant C_NEGRO      : t_color := x"000";
    constant C_BLANCO     : t_color := x"FFF";
    constant C_FONDO      : t_color := x"112";
    constant C_PANEL      : t_color := x"223";
    constant C_MARCO      : t_color := x"46A";
    constant C_TEXTO      : t_color := x"EEE";
    constant C_TENUE      : t_color := x"99A";
    constant C_PIE        : t_color := x"557";
    constant C_ENCAB      : t_color := x"FC4";
    constant C_RESALTE    : t_color := x"FD3";
    constant C_RECUADRO   : t_color := x"111";
    constant C_FOCO_OFF   : t_color := x"222";
    constant C_FOCO_APAG  : t_color := x"444";
    constant C_FOCO_BEAT  : t_color := x"4F4";
    constant C_FOCO_ACEN  : t_color := x"F43";
    constant C_CAJA       : t_color := x"333";
    constant C_T_BLANCA   : t_color := x"EEE";
    constant C_T_NEGRA    : t_color := x"111";
    constant C_ETIQ       : t_color := x"666";
    constant C_ONDA       : t_color := x"FE3";
    constant C_ONDA_FONDO : t_color := x"012";
    constant C_ONDA_EJE   : t_color := x"257";
    constant C_ONDA_MARCO : t_color := x"468";
    constant C_BARRA_FONDO : t_color := x"112";
    constant C_BARRA_MARCO : t_color := x"668";
    constant C_SEG_APAG   : t_color := x"334";
    constant C_REC        : t_color := x"F11";

    -- banda por modo: INTERPRETACION, GRABACION, REPRODUCCION, CONFIGURACION
    constant C_BANDA : t_colores(0 to 3) := (x"25B", x"C22", x"194", x"D70");
    -- voces V1, V2, V3
    constant C_VOZ   : t_colores(0 to 2) := (x"F62", x"3D3", x"39F");
    -- medidor de volumen, de verde a rojo
    constant C_SEG   : t_colores(0 to 3) := (x"3C3", x"9D2", x"FC2", x"F52");
    -- texto del estado del secuenciador y relleno de la barra
    constant C_EST   : t_colores(0 to 3) := (x"EEE", x"F44", x"4E5", x"99A");
    constant C_AVAN  : t_colores(0 to 3) := (x"69B", x"E33", x"3C5", x"69B");

    ------------------------------------------------------------
    -- Tablas (se calculan al elaborar; en hardware son ROM)
    ------------------------------------------------------------
    type t_tabla is array (natural range <>) of natural range 0 to 127;

    function tabla_div (n, d : positive) return t_tabla is
        variable t : t_tabla(0 to n - 1);
    begin
        for i in 0 to n - 1 loop
            t(i) := i / d;
        end loop;
        return t;
    end function;

    function tabla_mod (n, d : positive) return t_tabla is
        variable t : t_tabla(0 to n - 1);
    begin
        for i in 0 to n - 1 loop
            t(i) := i mod d;
        end loop;
        return t;
    end function;

    -- y (0 arriba, 0-95) de la onda en cada una de las 128 columnas
    -- de la caja, para las cuatro formas (indice 128 * forma + x).
    -- La columna x es la fase de 8 bits 2x y la muestra se calcula
    -- como en forma_onda; y = 48 - muestra/4 (redondeo hacia abajo).
    function tabla_onda return t_tabla is
        variable t     : t_tabla(0 to 511);
        variable f, tr : natural;
        variable m, q  : integer;
    begin
        for w in 0 to 3 loop
            for x in 0 to 127 loop
                f := 2 * x;
                case w is
                    when 0 =>                               -- cuadrada
                        if f < 128 then
                            m := 127;
                        else
                            m := -127;
                        end if;
                    when 1 =>                               -- triangular
                        tr := (2 * f) mod 256;
                        if f < 128 then
                            m := tr - 128;
                        else
                            m := 127 - tr;
                        end if;
                    when 2 =>                               -- sierra
                        m := f - 128;
                    when others =>                          -- seno
                        m := seno(f);
                end case;
                if m < -127 then
                    m := -127;
                end if;
                if m >= 0 then
                    q := m / 4;
                else
                    q := -((3 - m) / 4);
                end if;
                t(128 * w + x) := 48 - q;
            end loop;
        end loop;
        return t;
    end function;

    -- divisiones sin divisor: celdas de 12 = 3 bloques de 4 pixeles,
    -- de 24 = 3 bloques de 8 y teclas de 40 = 5 bloques de 8
    constant DIV3  : t_tabla(0 to 255) := tabla_div(256, 3);
    constant MOD3  : t_tabla(0 to 255) := tabla_mod(256, 3);
    constant DIV5  : t_tabla(0 to 127) := tabla_div(128, 5);
    constant MOD5  : t_tabla(0 to 127) := tabla_mod(128, 5);
    -- nota n -> octava y semitono
    constant DIV12 : t_tabla(0 to 127) := tabla_div(128, 12);
    constant MOD12 : t_tabla(0 to 127) := tabla_mod(128, 12);
    constant ONDA_TAB : t_tabla(0 to 511) := tabla_onda;

    -- semitono (0-23) de cada tecla blanca y si tiene negra a su derecha
    constant KW : t_tabla(0 to 31) := (0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, others => 0);
    constant HAY_NEGRA : std_logic_vector(0 to 31) := "11011101101110000000000000000000";

    -- medio ancho de cada renglon de los circulos (foco r=16, punto r=5)
    constant CIRC16 : t_tabla(0 to 31) := (4, 7, 9, 10, 11, 12, 13, 14, 14, 15, 15, 15, 16, 16, 16, 16,
                                           16, 16, 16, 16, 15, 15, 15, 14, 14, 13, 12, 11, 10, 9, 7, 4);
    constant CIRC5  : t_tabla(0 to 15) := (2, 4, 4, 5, 5, 5, 5, 4, 4, 2, others => 0);

    ------------------------------------------------------------
    -- Textos (codigos de fuente_5x7, calculados al elaborar)
    ------------------------------------------------------------
    subtype t_t8  is t_texto(0 to 7);
    subtype t_t10 is t_texto(0 to 9);
    subtype t_t11 is t_texto(0 to 10);
    subtype t_t13 is t_texto(0 to 12);
    subtype t_t14 is t_texto(0 to 13);
    type t_txt8x8   is array (0 to 7) of t_t8;
    type t_txt4x10  is array (0 to 3) of t_t10;
    type t_txt4x11  is array (0 to 3) of t_t11;
    type t_txt4x13  is array (0 to 3) of t_t13;
    type t_txt4x14  is array (0 to 3) of t_t14;

    constant TITULO : t_txt4x14 := (txt("INTERPRETACION"), txt("GRABACION     "),
                                    txt("REPRODUCCION  "), txt("CONFIGURACION "));
    constant ETIQ : t_txt8x8 := (txt("FORMA   "), txt("ATTACK  "), txt("DECAY   "), txt("SUSTAIN "),
                                 txt("RELEASE "), txt("VOLUMEN "), txt("TEMPO   "), txt("EFECTO  "));
    constant V_FORMA  : t_txt4x11 := (txt("CUADRADA   "), txt("TRIANGULAR "), txt("SIERRA     "), txt("SENO       "));
    constant V_ATK    : t_txt4x11 := (txt("2 MS       "), txt("50 MS      "), txt("200 MS     "), txt("800 MS     "));
    constant V_DEC    : t_txt4x11 := (txt("50 MS      "), txt("200 MS     "), txt("600 MS     "), txt("1500 MS    "));
    constant V_SUS    : t_txt4x11 := (txt("25 %       "), txt("50 %       "), txt("75 %       "), txt("100 %      "));
    constant V_REL    : t_txt4x11 := (txt("20 MS      "), txt("150 MS     "), txt("500 MS     "), txt("1500 MS    "));
    constant V_TEMPO  : t_txt4x11 := (txt("60 BPM     "), txt("90 BPM     "), txt("120 BPM    "), txt("150 BPM    "));
    constant V_EFECTO : t_txt4x11 := (txt("NINGUNO    "), txt("TREMOLO    "), txt("ECO        "), txt("TREMOLO+ECO"));
    constant N_FORMA  : t_txt4x10 := (txt(" CUADRADA "), txt("TRIANGULAR"), txt("  SIERRA  "), txt("   SENO   "));
    constant T_ESTADO : t_txt4x13 := (txt("EN ESPERA    "), txt("GRABANDO     "),
                                      txt("REPRODUCIENDO"), txt("---          "));

    constant T_METRO_ON  : t_texto := txt("METRONOMO ON ");
    constant T_METRO_OFF : t_texto := txt("METRONOMO OFF");
    constant T_TECLADO1  : t_texto := txt("TECLADO 1");
    constant T_TECLADO2  : t_texto := txt("TECLADO 2");
    constant T_PARAM     : t_texto := txt("PARAMETROS");
    constant T_FORMA     : t_texto := txt("FORMA DE ONDA");
    constant T_VOCES     : t_texto := txt("VOCES");
    constant T_OCTAVA    : t_texto := txt("OCTAVA ");
    constant T_SECUEN    : t_texto := txt("SECUENCIADOR");
    constant T_EVENTOS   : t_texto := txt("EVENTOS ");
    constant T_256       : t_texto := txt("/256");
    constant T_AVANCE    : t_texto := txt("AVANCE ");
    constant T_MEMORIA   : t_texto := txt("MEMORIA");
    constant T_POS       : t_texto := txt("POS ");
    constant T_PIE       : t_texto := txt("DISENO DIGITAL VLSI  FI UNAM");

    constant NOTA_LETRA : t_texto := txt("CCDDEFFGGAAB");
    constant NOTA_SOST  : std_logic_vector(0 to 11) := "010100101010";

    constant CH_GUION  : t_cod := cod_car('-');
    constant CH_SOST   : t_cod := cod_car('#');
    constant CH_FLECHA : t_cod := cod_car('>');
    constant CH_V      : t_cod := cod_car('V');
    constant CH_C      : t_cod := cod_car('C');

    -- caracter j (0-2) del nombre de una nota: C4, C#4 o ---
    function car_nota (nula : std_logic; semi, oct, j : natural) return t_cod is
        variable o : natural range 0 to 9;
    begin
        if oct > 9 then
            o := 9;
        else
            o := oct;
        end if;
        if nula = '1' then
            return CH_GUION;
        elsif j = 0 then
            return NOTA_LETRA(semi);
        elsif NOTA_SOST(semi) = '1' then
            if j = 1 then
                return CH_SOST;
            else
                return CH_0 + o;
            end if;
        elsif j = 1 then
            return CH_0 + o;
        else
            return CH_ESP;
        end if;
    end function;

    -- digito i (0 centenas, 1 decenas, 2 unidades) de un numero BCD
    function car_bcd (b : unsigned(11 downto 0); i : natural) return t_cod is
    begin
        case i is
            when 0      => return CH_0 + to_integer(b(11 downto 8));
            when 1      => return CH_0 + to_integer(b(7 downto 4));
            when others => return CH_0 + to_integer(b(3 downto 0));
        end case;
    end function;

    function dentro (x, y, x0, x1, y0, y1 : natural) return boolean is
    begin
        return x >= x0 and x <= x1 and y >= y0 and y <= y1;
    end function;

    ------------------------------------------------------------
    -- Barrido
    ------------------------------------------------------------
    signal pix_en  : std_logic := '0';
    signal hc      : natural range 0 to H_TOT - 1 := 0;
    signal vc      : natural range 0 to V_TOT - 1 := 0;
    signal cuadros : unsigned(7 downto 0) := (others => '0');

    ------------------------------------------------------------
    -- Copia de las entradas para el cuadro
    ------------------------------------------------------------
    subtype t_n4 is natural range 0 to 3;
    type t_nat3 is array (0 to 2) of natural range 0 to 255;
    signal f_modo   : t_n4 := 0;
    signal f_est    : t_n4 := 0;
    signal f_forma  : t_n4 := 0;
    signal f_atk    : t_n4 := 0;
    signal f_dec    : t_n4 := 0;
    signal f_sus    : t_n4 := 0;
    signal f_rel    : t_n4 := 0;
    signal f_tempo  : t_n4 := 0;
    signal f_efecto : t_n4 := 0;
    signal f_vol    : natural range 0 to 4 := 0;
    signal f_oct    : natural range 0 to 7 := 0;
    signal f_param  : natural range 0 to 7 := 0;
    signal f_metro  : std_logic := '0';
    signal f_foco   : t_color := C_FOCO_OFF;
    signal f_rec    : std_logic := '0';                          -- punto de grabacion encendido
    signal v_oct    : t_nat3 := (others => 0);
    signal v_semi   : t_nat3 := (others => 0);
    signal v_tecla  : t_nat3 := (others => 0);                   -- tecla del piano (0-23)
    signal v_nivel  : t_nat3 := (others => 0);                   -- pixeles llenos de la barra (0-128)
    signal v_nula   : std_logic_vector(0 to 2) := (others => '1');
    signal v_act    : std_logic_vector(0 to 2) := (others => '0');   -- se pinta en el piano
    signal v_gate   : std_logic_vector(0 to 2) := (others => '0');
    signal umbral   : natural range 0 to 2**18 - 1 := 0;         -- barra: numerador * BAR_W
    signal den      : natural range 0 to 511 := 0;               -- barra: denominador

    signal dest_cnt : natural range 0 to DESTELLO := 0;          -- foco del metronomo
    signal dest_ac  : std_logic := '0';

    signal bcd_paso : natural range 0 to 20 := 0;                -- 0 = sin conversion
    signal bcd_sh   : unsigned(8 downto 0)  := (others => '0');
    signal bcd_acc  : unsigned(11 downto 0) := (others => '0');
    signal bcd_ev   : unsigned(11 downto 0) := (others => '0');
    signal bcd_pos  : unsigned(11 downto 0) := (others => '0');

    ------------------------------------------------------------
    -- Zonas de la pantalla (las calcula la etapa 1)
    ------------------------------------------------------------
    constant Z_FONDO : natural := 0;
    constant Z_BANDA : natural := 1;
    constant Z_PIANO : natural := 2;
    constant Z_MARCO : natural := 3;    -- marco de cualquier panel
    constant Z_PL    : natural := 4;    -- dentro de PARAMETROS
    constant Z_PM    : natural := 5;    -- dentro de FORMA DE ONDA
    constant Z_PR    : natural := 6;    -- dentro de VOCES
    constant Z_PS    : natural := 7;    -- dentro de SECUENCIADOR

    function b2sl (b : boolean) return std_logic is
    begin
        if b then
            return '1';
        else
            return '0';
        end if;
    end function;

    ------------------------------------------------------------
    -- Etapa 1: coordenadas y geometria (solo dependen de hc, vc)
    ------------------------------------------------------------
    signal s1_hs, s1_vs : std_logic := '1';
    signal s1_vis    : std_logic := '0';
    signal s1_zona   : natural range 0 to 7 := Z_FONDO;
    signal s1_tc     : natural range 0 to 127 := 0;   -- columna de texto
    signal s1_tgx    : natural range 0 to 7 := 0;     -- columna dentro de la letra (5 = hueco)
    signal s1_tr     : natural range 0 to 31 := 0;    -- renglon de texto
    signal s1_tgy    : natural range 0 to 7 := 0;     -- fila dentro de la letra (7 = hueco)
    signal s1_ien    : std_logic := '0';              -- dentro del titulo
    signal s1_ic     : natural range 0 to 127 := 0;
    signal s1_igx    : natural range 0 to 7 := 0;
    signal s1_igy    : natural range 0 to 7 := 0;
    signal s1_recu   : std_logic := '0';              -- recuadro del foco
    signal s1_foco   : std_logic := '0';              -- circulo del foco
    signal s1_franja : std_logic := '0';              -- franja de color arriba del piano
    signal s1_pen    : std_logic := '0';              -- dentro de las teclas
    signal s1_pw     : natural range 0 to 31 := 0;    -- tecla blanca
    signal s1_poff   : natural range 0 to 63 := 0;    -- x dentro de la tecla blanca (0-39)
    signal s1_py     : natural range 0 to 127 := 0;   -- y dentro del piano
    signal s1_lab    : std_logic := '0';              -- etiqueta C<octava>
    signal s1_ldig   : std_logic := '0';              -- '1' en el digito de la etiqueta
    signal s1_lgx    : natural range 0 to 7 := 0;
    signal s1_lgy    : natural range 0 to 7 := 0;
    signal s1_resx   : std_logic := '0';              -- ancho del renglon resaltado
    signal s1_seg    : natural range 0 to 4 := 4;     -- segmento del volumen (4 = ninguno)
    signal s1_ocaja  : std_logic := '0';              -- caja de la onda con su marco
    signal s1_omarco : std_logic := '0';
    signal s1_eje    : std_logic := '0';
    signal s1_yw     : natural range 0 to 127 := 0;   -- y dentro de la caja de la onda
    signal s1_wini   : std_logic := '0';              -- primera columna de la onda
    signal s1_wy     : natural range 0 to 127 := 0;   -- y de la onda en esta columna
    signal s1_nv     : natural range 0 to 3 := 3;     -- barra de nivel de la voz (3 = ninguna)
    signal s1_nvm    : std_logic := '0';              -- marco de la barra de nivel
    signal s1_nvx    : natural range 0 to 127 := 0;   -- x dentro de la barra de nivel
    signal s1_rec    : std_logic := '0';              -- punto de grabacion
    signal s1_bar    : std_logic := '0';              -- barra del secuenciador con su marco
    signal s1_barm   : std_logic := '0';
    signal s1_prod   : natural range 0 to 2**18 - 1 := 0;

    ------------------------------------------------------------
    -- Etapa 2: contenido (letra y color de cada zona)
    ------------------------------------------------------------
    signal s2_hs, s2_vs : std_logic := '1';
    signal s2_vis    : std_logic := '0';
    signal s2_zona   : natural range 0 to 7 := Z_FONDO;
    signal s2_cd_t   : t_cod := 0;                    -- texto de la cuadricula
    signal s2_fg_t   : t_color := (others => '0');
    signal s2_gx_t   : natural range 0 to 7 := 0;
    signal s2_gy_t   : natural range 0 to 7 := 0;
    signal s2_ien    : std_logic := '0';              -- titulo
    signal s2_cd_i   : t_cod := 0;
    signal s2_igx    : natural range 0 to 7 := 0;
    signal s2_igy    : natural range 0 to 7 := 0;
    signal s2_lab    : std_logic := '0';              -- etiqueta del piano
    signal s2_cd_l   : t_cod := 0;
    signal s2_fg_l   : t_color := (others => '0');
    signal s2_lgx    : natural range 0 to 7 := 0;
    signal s2_lgy    : natural range 0 to 7 := 0;
    signal s2_bcol   : t_color := (others => '0');    -- color de cada zona
    signal s2_pcol   : t_color := (others => '0');
    signal s2_lcol   : t_color := (others => '0');
    signal s2_mcol   : t_color := (others => '0');
    signal s2_rcol   : t_color := (others => '0');
    signal s2_scol   : t_color := (others => '0');
    signal s2_wyp    : natural range 0 to 127 := 0;   -- y de la onda en la columna anterior

    ------------------------------------------------------------
    -- Etapa 3: color de fondo y letra que toca
    ------------------------------------------------------------
    signal s3_hs, s3_vs : std_logic := '1';
    signal s3_vis    : std_logic := '0';
    signal s3_cod    : t_cod := 0;
    signal s3_gx     : natural range 0 to 7 := 0;
    signal s3_gy     : natural range 0 to 7 := 0;
    signal s3_fg     : t_color := (others => '0');
    signal s3_base   : t_color := (others => '0');

    ------------------------------------------------------------
    -- Etapa 4: salidas
    ------------------------------------------------------------
    signal s4_rgb    : t_color := (others => '0');
    signal s4_hs, s4_vs : std_logic := '1';

begin

    assert PARPADEO <= 7
        report "vga_ui: PARPADEO debe ser de 0 a 7"
        severity failure;

    ------------------------------------------------------------
    -- Contadores de barrido
    ------------------------------------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pix_en  <= '0';
                hc      <= 0;
                vc      <= 0;
                cuadros <= (others => '0');
            else
                pix_en <= not pix_en;
                if pix_en = '1' then
                    if hc = H_TOT - 1 then
                        hc <= 0;
                        if vc = V_TOT - 1 then
                            vc      <= 0;
                            cuadros <= cuadros + 1;
                        else
                            vc <= vc + 1;
                        end if;
                    else
                        hc <= hc + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Foco del metronomo: DESTELLO ciclos desde cada tiempo
    ------------------------------------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dest_cnt <= 0;
                dest_ac  <= '0';
            elsif beat = '1' then
                dest_cnt <= DESTELLO;
                dest_ac  <= acento;
            elsif dest_cnt /= 0 then
                dest_cnt <= dest_cnt - 1;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Copia de las entradas, una vez por cuadro (inicio de la
    -- ultima linea), y conversion de eventos y posicion a BCD
    ------------------------------------------------------------
    process (clk)
        variable n    : natural range 0 to 127;
        variable base : natural range 0 to 127;
        variable d    : integer range -128 to 127;
        variable vol  : natural range 0 to 7;
        variable a    : unsigned(11 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bcd_paso <= 0;
            elsif pix_en = '1' and hc = 0 and vc = V_TOT - 1 then
                f_modo   <= to_integer(unsigned(modo));
                f_est    <= to_integer(unsigned(estado_sec));
                f_forma  <= to_integer(unsigned(forma));
                f_atk    <= to_integer(unsigned(atk));
                f_dec    <= to_integer(unsigned(dec));
                f_sus    <= to_integer(unsigned(sus));
                f_rel    <= to_integer(unsigned(rel));
                f_tempo  <= to_integer(unsigned(tempo));
                f_efecto <= to_integer(unsigned(efecto));
                f_oct    <= to_integer(unsigned(octava));
                f_param  <= to_integer(unsigned(parametro));
                f_metro  <= metro_on;
                vol := to_integer(unsigned(volumen));
                if vol > 4 then
                    f_vol <= 4;
                else
                    f_vol <= vol;
                end if;

                -- notas: nombre (octava y semitono), tecla y nivel
                base := to_integer(unsigned(octava)) * 12;
                for i in 0 to 2 loop
                    n := to_integer(unsigned(notas(7 * i + 6 downto 7 * i)));
                    d := n - base;
                    v_oct(i)   <= DIV12(n);
                    v_semi(i)  <= MOD12(n);
                    -- barra de 128 pixeles: nivel / 2 redondeado (255 la llena)
                    v_nivel(i) <= (to_integer(unsigned(niveles(8 * i + 7 downto 8 * i))) + 1) / 2;
                    v_gate(i)  <= gates(i);
                    if n = 0 then
                        v_nula(i) <= '1';
                    else
                        v_nula(i) <= '0';
                    end if;
                    if gates(i) = '1' and n /= 0 and d >= 0 and d <= 23 then
                        v_act(i)   <= '1';
                        v_tecla(i) <= d;
                    else
                        v_act(i)   <= '0';
                        v_tecla(i) <= 0;
                    end if;
                end loop;

                -- barra: reproduciendo, posicion / eventos; si no, eventos / 256
                if estado_sec = S_REPRODUCE then
                    umbral <= to_integer(unsigned(posicion)) * BAR_W;
                    den    <= to_integer(unsigned(eventos));
                else
                    umbral <= to_integer(unsigned(eventos)) * BAR_W;
                    den    <= 256;
                end if;

                -- foco y punto de grabacion
                if metro_on = '0' then
                    f_foco <= C_FOCO_OFF;
                elsif dest_cnt /= 0 then
                    if dest_ac = '1' then
                        f_foco <= C_FOCO_ACEN;
                    else
                        f_foco <= C_FOCO_BEAT;
                    end if;
                else
                    f_foco <= C_FOCO_APAG;
                end if;
                if estado_sec = S_GRABANDO and cuadros(PARPADEO) = '1' then
                    f_rec <= '1';
                else
                    f_rec <= '0';
                end if;

                -- arranca el BCD de eventos
                bcd_sh   <= unsigned(eventos);
                bcd_acc  <= (others => '0');
                bcd_paso <= 1;

            elsif bcd_paso /= 0 then
                -- doble-dabble: pasos 1-9 eventos, 10 guarda y carga
                -- posicion, 11-19 posicion, 20 guarda
                if bcd_paso = 10 then
                    bcd_ev   <= bcd_acc;
                    bcd_sh   <= unsigned(posicion);
                    bcd_acc  <= (others => '0');
                    bcd_paso <= 11;
                elsif bcd_paso = 20 then
                    bcd_pos  <= bcd_acc;
                    bcd_paso <= 0;
                else
                    a := bcd_acc;
                    if a(3 downto 0) > 4 then
                        a(3 downto 0) := a(3 downto 0) + 3;
                    end if;
                    if a(7 downto 4) > 4 then
                        a(7 downto 4) := a(7 downto 4) + 3;
                    end if;
                    if a(11 downto 8) > 4 then
                        a(11 downto 8) := a(11 downto 8) + 3;
                    end if;
                    bcd_acc  <= a(10 downto 0) & bcd_sh(8);
                    bcd_sh   <= bcd_sh(7 downto 0) & '0';
                    bcd_paso <= bcd_paso + 1;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Etapa 1: coordenadas y geometria
    ------------------------------------------------------------
    process (clk)
        variable x, y : natural range 0 to 1023;
        variable xr   : natural range 0 to 1023;
        variable yr   : natural range 0 to 1023;
        variable b    : natural range 0 to 255;
        variable pw   : natural range 0 to 31;
        variable po   : natural range 0 to 63;
        variable py   : natural range 0 to 127;
        variable pen  : boolean;
        variable hw   : natural range 0 to 127;
        variable dx   : natural range 0 to 1023;
        variable zona : natural range 0 to 7;
        variable seg  : natural range 0 to 4;
        variable nv   : natural range 0 to 3;
    begin
        if rising_edge(clk) then
            if pix_en = '1' then
                x := hc;
                y := vc;

                -- sincronias (en bajo) y zona visible
                if x >= H_VIS + H_FP and x < H_VIS + H_FP + H_SY then
                    s1_hs <= '0';
                else
                    s1_hs <= '1';
                end if;
                if y >= V_VIS + V_FP and y < V_VIS + V_FP + V_SY then
                    s1_vs <= '0';
                else
                    s1_vs <= '1';
                end if;
                s1_vis <= b2sl(x < H_VIS and y < V_VIS);

                -- zona: banda, piano, marco o interior de un panel
                if y < BANDA_Y1 then
                    zona := Z_BANDA;
                elsif dentro(x, y, PIA_X - 6, PIA_X + PIA_ANCHO + 5, PIA_Y - 8, PIA_Y + 125) then
                    zona := Z_PIANO;
                elsif dentro(x, y, PL_X0, PL_X1, PA_Y0, PA_Y1) then
                    if dentro(x, y, PL_X0 + 2, PL_X1 - 2, PA_Y0 + 2, PA_Y1 - 2) then
                        zona := Z_PL;
                    else
                        zona := Z_MARCO;
                    end if;
                elsif dentro(x, y, PM_X0, PM_X1, PA_Y0, PA_Y1) then
                    if dentro(x, y, PM_X0 + 2, PM_X1 - 2, PA_Y0 + 2, PA_Y1 - 2) then
                        zona := Z_PM;
                    else
                        zona := Z_MARCO;
                    end if;
                elsif dentro(x, y, PR_X0, PR_X1, PA_Y0, PA_Y1) then
                    if dentro(x, y, PR_X0 + 2, PR_X1 - 2, PA_Y0 + 2, PA_Y1 - 2) then
                        zona := Z_PR;
                    else
                        zona := Z_MARCO;
                    end if;
                elsif dentro(x, y, PL_X0, PR_X1, PS_Y0, PS_Y1) then
                    if dentro(x, y, PL_X0 + 2, PR_X1 - 2, PS_Y0 + 2, PS_Y1 - 2) then
                        zona := Z_PS;
                    else
                        zona := Z_MARCO;
                    end if;
                else
                    zona := Z_FONDO;
                end if;
                s1_zona <= zona;

                -- texto: celdas de 12x16 = 3 bloques de 4 pixeles
                b := x / 4;
                s1_tc  <= DIV3(b);
                s1_tgx <= 2 * MOD3(b) + (x / 2) mod 2;
                s1_tr  <= (y / 16) mod 32;
                s1_tgy <= (y / 2) mod 8;

                -- titulo: celdas de 24x32 = 3 bloques de 8, letras x4
                if x >= TIT_X then
                    xr := x - TIT_X;
                else
                    xr := 0;
                end if;
                b := (xr / 8) mod 128;
                s1_ic  <= DIV3(b);
                s1_igx <= 2 * MOD3(b) + (xr / 4) mod 2;
                if y >= TIT_Y then
                    yr := y - TIT_Y;
                else
                    yr := 0;
                end if;
                s1_igy <= (yr / 4) mod 8;
                s1_ien <= b2sl(x >= TIT_X and x < TIT_X + 24 * TIT_LEN and y >= TIT_Y and y < TIT_Y + 28);

                -- foco del metronomo: recuadro y circulo de 32x32
                s1_recu <= b2sl(dentro(x, y, RECU_X0, RECU_X1, RECU_Y0, RECU_Y1));
                s1_foco <= '0';
                if dentro(x, y, FOCO_X, FOCO_X + 31, FOCO_Y, FOCO_Y + 31) then
                    hw := CIRC16(y - FOCO_Y);
                    dx := x - FOCO_X;
                    s1_foco <= b2sl(dx + hw >= 16 and dx < 16 + hw);
                end if;

                -- piano: teclas blancas de 40 = 5 bloques de 8 pixeles
                if x >= PIA_X then
                    xr := x - PIA_X;
                else
                    xr := 0;
                end if;
                b  := (xr / 8) mod 128;
                pw := DIV5(b);
                po := 8 * MOD5(b) + xr mod 8;
                if y >= PIA_Y then
                    yr := y - PIA_Y;
                else
                    yr := 0;
                end if;
                py  := yr mod 128;
                pen := dentro(x, y, PIA_X, PIA_X + PIA_ANCHO - 1, PIA_Y, PIA_Y + 119);
                s1_pw     <= pw;
                s1_poff   <= po;
                s1_py     <= py;
                s1_pen    <= b2sl(pen);
                s1_franja <= b2sl(y < PIA_Y - 4);
                -- etiqueta C<octava> en las teclas blancas 0 y 7 (renglones 98-111)
                s1_lab  <= '0';
                s1_ldig <= '0';
                s1_lgx  <= 0;
                s1_lgy  <= 0;
                if pen and (pw = 0 or pw = 7) and py >= 98 and py < 112 then
                    s1_lgy <= ((py - 98) / 2) mod 8;
                    if po >= 8 and po < 18 then
                        s1_lab <= '1';
                        s1_lgx <= ((po - 8) / 2) mod 8;
                    elsif po >= 20 and po < 30 then
                        s1_lab  <= '1';
                        s1_ldig <= '1';
                        s1_lgx  <= ((po - 20) / 2) mod 8;
                    end if;
                end if;

                -- PARAMETROS: ancho del renglon resaltado y segmentos del volumen
                s1_resx <= b2sl(x >= PL_X0 + 4 and x <= PL_X1 - 4);
                seg := 4;
                if y >= VOL_Y and y < VOL_Y + 10 then
                    for i in 0 to 3 loop
                        if x >= VOL_X + 22 * i and x < VOL_X + 22 * i + 18 then
                            seg := i;
                        end if;
                    end loop;
                end if;
                s1_seg <= seg;

                -- FORMA DE ONDA: caja, marco, eje punteado y y de la columna
                s1_ocaja  <= b2sl(dentro(x, y, ONDA_X - 1, ONDA_X + 128, ONDA_Y - 1, ONDA_Y + 96));
                s1_omarco <= b2sl(not dentro(x, y, ONDA_X, ONDA_X + 127, ONDA_Y, ONDA_Y + 95));
                s1_eje    <= b2sl(y = ONDA_Y + 48 and (x / 4) mod 2 = 0);
                if y >= ONDA_Y then
                    yr := y - ONDA_Y;
                else
                    yr := 0;
                end if;
                s1_yw <= yr mod 128;
                if x >= ONDA_X then
                    xr := x - ONDA_X;
                else
                    xr := 0;
                end if;
                s1_wy   <= ONDA_TAB(128 * f_forma + xr mod 128);
                s1_wini <= b2sl(x = ONDA_X);

                -- VOCES: barra de nivel de cada voz
                nv := 3;
                for i in 0 to 2 loop
                    if dentro(x, y, NIV_X - 1, NIV_X + 128, NIV_Y + 32 * i - 1, NIV_Y + 32 * i + 8) then
                        nv := i;
                    end if;
                end loop;
                s1_nv  <= nv;
                s1_nvm <= b2sl(x < NIV_X or x > NIV_X + 127 or
                               y = NIV_Y - 1 or y = NIV_Y + 8 or
                               y = NIV_Y + 31 or y = NIV_Y + 40 or
                               y = NIV_Y + 63 or y = NIV_Y + 72);
                if x >= NIV_X then
                    xr := x - NIV_X;
                else
                    xr := 0;
                end if;
                s1_nvx <= xr mod 128;

                -- SECUENCIADOR: punto de grabacion y barra
                s1_rec <= '0';
                if dentro(x, y, REC_X, REC_X + 9, REC_Y, REC_Y + 9) then
                    hw := CIRC5(y - REC_Y);
                    dx := x - REC_X;
                    s1_rec <= b2sl(dx + hw >= 5 and dx < 5 + hw);
                end if;
                s1_bar  <= b2sl(dentro(x, y, BAR_X - 1, BAR_X + BAR_W, BAR_Y - 1, BAR_Y + 12));
                s1_barm <= b2sl(not dentro(x, y, BAR_X, BAR_X + BAR_W - 1, BAR_Y, BAR_Y + 11));
                if x >= BAR_X then
                    xr := x - BAR_X;
                else
                    xr := 0;
                end if;
                s1_prod <= (xr mod 512) * den;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Etapa 2: contenido (letra de la cuadricula y color de cada zona)
    ------------------------------------------------------------
    process (clk)
        variable r      : natural range 0 to 31;
        variable c      : natural range 0 to 127;
        variable p      : natural range 0 to 7;
        variable v      : natural range 0 to 2;
        variable cd     : t_cod;
        variable fg     : t_color;
        variable sel    : boolean;
        variable col    : t_color;
        variable k      : natural range 0 to 31;
        variable negra  : boolean;
        variable kcol   : t_color;
        variable yp, lo, hi : natural range 0 to 127;
    begin
        if rising_edge(clk) then
            if pix_en = '1' then
                r := s1_tr;
                c := s1_tc;

                ------------------------------------------------
                -- Texto de la cuadricula
                ------------------------------------------------
                cd := CH_ESP;
                fg := C_TEXTO;
                case r is
                    when 1 =>                               -- METRONOMO ON / OFF
                        fg := C_BLANCO;
                        if c >= 36 and c <= 48 then
                            if f_metro = '1' then
                                cd := T_METRO_ON(c - 36);
                            else
                                cd := T_METRO_OFF(c - 36);
                            end if;
                        end if;
                    when 2 =>                               -- tempo en BPM
                        fg := C_BLANCO;
                        if c >= 36 and c <= 42 then
                            cd := V_TEMPO(f_tempo)(c - 36);
                        end if;
                    when 5 =>                               -- teclados sobre el piano
                        fg := C_TENUE;
                        if c >= 10 and c <= 18 then
                            cd := T_TECLADO1(c - 10);
                        elsif c >= 34 and c <= 42 then
                            cd := T_TECLADO2(c - 34);
                        end if;
                    when 15 =>                              -- encabezados de los paneles
                        fg := C_ENCAB;
                        if c >= 2 and c <= 11 then
                            cd := T_PARAM(c - 2);
                        elsif c >= 23 and c <= 35 then
                            cd := T_FORMA(c - 23);
                        elsif c >= 37 and c <= 41 then
                            cd := T_VOCES(c - 37);
                        end if;
                    when 16 to 23 =>
                        p   := r - 16;
                        sel := f_modo = 3 and p = f_param;  -- CONFIGURACION
                        if c = 1 then                       -- flecha del parametro elegido
                            if sel then
                                cd := CH_FLECHA;
                                fg := C_NEGRO;
                            end if;
                        elsif c >= 2 and c <= 9 then        -- nombre del parametro
                            cd := ETIQ(p)(c - 2);
                            if sel then
                                fg := C_NEGRO;
                            else
                                fg := C_TENUE;
                            end if;
                        elsif c >= 10 and c <= 20 then      -- valor
                            case p is
                                when 0 => cd := V_FORMA(f_forma)(c - 10);
                                when 1 => cd := V_ATK(f_atk)(c - 10);
                                when 2 => cd := V_DEC(f_dec)(c - 10);
                                when 3 => cd := V_SUS(f_sus)(c - 10);
                                when 4 => cd := V_REL(f_rel)(c - 10);
                                when 5 =>
                                    if c = 10 then
                                        cd := CH_0 + f_vol;
                                    end if;
                                when 6 => cd := V_TEMPO(f_tempo)(c - 10);
                                when others => cd := V_EFECTO(f_efecto)(c - 10);
                            end case;
                            if sel then
                                fg := C_NEGRO;
                            else
                                fg := C_TEXTO;
                            end if;
                        elsif c >= 24 and c <= 33 then      -- nombre de la forma de onda
                            if r = 23 then
                                cd := N_FORMA(f_forma)(c - 24);
                                fg := C_ONDA;
                            end if;
                        elsif c >= 37 and c <= 44 then      -- voces y octava
                            if r = 16 or r = 18 or r = 20 then
                                if r = 16 then
                                    v := 0;
                                elsif r = 18 then
                                    v := 1;
                                else
                                    v := 2;
                                end if;
                                if c = 37 then
                                    cd := CH_V;
                                    fg := C_VOZ(v);
                                elsif c = 38 then
                                    cd := CH_0 + 1 + v;
                                    fg := C_VOZ(v);
                                elsif c >= 40 and c <= 42 then
                                    cd := car_nota(v_nula(v), v_semi(v), v_oct(v), c - 40);
                                    if v_gate(v) = '1' then
                                        fg := C_TEXTO;
                                    else
                                        fg := C_TENUE;
                                    end if;
                                end if;
                            elsif r = 23 then
                                if c <= 43 then
                                    cd := T_OCTAVA(c - 37);
                                    fg := C_TENUE;
                                else
                                    cd := CH_0 + f_oct;
                                    fg := C_TEXTO;
                                end if;
                            end if;
                        end if;
                    when 25 =>                              -- secuenciador
                        if c >= 2 and c <= 13 then
                            cd := T_SECUEN(c - 2);
                            fg := C_ENCAB;
                        elsif c >= 15 and c <= 27 then
                            cd := T_ESTADO(f_est)(c - 15);
                            fg := C_EST(f_est);
                        elsif c >= 31 and c <= 38 then
                            cd := T_EVENTOS(c - 31);
                            fg := C_TENUE;
                        elsif c >= 39 and c <= 41 then
                            cd := car_bcd(bcd_ev, c - 39);
                            fg := C_TEXTO;
                        elsif c >= 42 and c <= 45 then
                            cd := T_256(c - 42);
                            fg := C_TENUE;
                        end if;
                    when 27 =>
                        fg := C_TENUE;
                        if c >= 2 and c <= 8 then
                            if f_est = 2 then               -- reproduciendo
                                cd := T_AVANCE(c - 2);
                            else
                                cd := T_MEMORIA(c - 2);
                            end if;
                        elsif c >= 44 and c <= 47 then
                            cd := T_POS(c - 44);
                        elsif c >= 48 and c <= 50 then
                            cd := car_bcd(bcd_pos, c - 48);
                            fg := C_TEXTO;
                        end if;
                    when 29 =>                              -- pie
                        fg := C_PIE;
                        if c >= 13 and c <= 40 then
                            cd := T_PIE(c - 13);
                        end if;
                    when others =>
                        null;
                end case;
                s2_cd_t <= cd;
                s2_fg_t <= fg;
                s2_gx_t <= s1_tgx;
                s2_gy_t <= s1_tgy;

                -- titulo con el nombre del modo
                if s1_ien = '1' and s1_ic < TIT_LEN then
                    s2_ien  <= '1';
                    s2_cd_i <= TITULO(f_modo)(s1_ic);
                else
                    s2_ien  <= '0';
                    s2_cd_i <= CH_ESP;
                end if;
                s2_igx <= s1_igx;
                s2_igy <= s1_igy;

                -- banda: color del modo y foco del metronomo
                col := C_BANDA(f_modo);
                if s1_recu = '1' then
                    col := C_RECUADRO;
                    if s1_foco = '1' then
                        col := f_foco;
                    end if;
                end if;
                s2_bcol <= col;

                -- piano: tecla negra = 12 pixeles a cada lado del borde
                -- de dos blancas, en las 72 lineas de arriba
                negra := false;
                k := KW(s1_pw);
                if s1_py < NEGRA_ALTO then
                    if s1_poff >= 28 and HAY_NEGRA(s1_pw) = '1' then
                        negra := true;
                        k := KW(s1_pw) + 1;
                    elsif s1_poff < 12 and s1_pw >= 1 and HAY_NEGRA(s1_pw - 1) = '1' then
                        negra := true;
                        k := KW(s1_pw - 1) + 1;
                    end if;
                end if;
                if negra then
                    kcol := C_T_NEGRA;
                else
                    kcol := C_T_BLANCA;
                end if;
                -- color de la voz que toca la tecla (V1 primero)
                if v_act(0) = '1' and v_tecla(0) = k then
                    kcol := C_VOZ(0);
                elsif v_act(1) = '1' and v_tecla(1) = k then
                    kcol := C_VOZ(1);
                elsif v_act(2) = '1' and v_tecla(2) = k then
                    kcol := C_VOZ(2);
                end if;
                if s1_franja = '1' then
                    col := C_BANDA(f_modo);
                else
                    col := C_CAJA;
                end if;
                if s1_pen = '1' then
                    if not negra and s1_poff >= 38 then
                        col := C_CAJA;                      -- separacion entre blancas
                    else
                        col := kcol;
                    end if;
                end if;
                s2_pcol <= col;
                -- etiqueta C<octava> (blanca 0) y C<octava + 1> (blanca 7)
                s2_lab <= s1_lab;
                if s1_ldig = '0' then
                    s2_cd_l <= CH_C;
                elsif s1_pw = 0 then
                    s2_cd_l <= CH_0 + f_oct;
                else
                    s2_cd_l <= CH_0 + f_oct + 1;
                end if;
                if kcol = C_T_BLANCA then
                    s2_fg_l <= C_ETIQ;
                else
                    s2_fg_l <= C_BLANCO;
                end if;
                s2_lgx <= s1_lgx;
                s2_lgy <= s1_lgy;

                -- PARAMETROS: renglon resaltado y medidor de volumen
                col := C_PANEL;
                if f_modo = 3 and r = 16 + f_param and s1_resx = '1' then
                    col := C_RESALTE;
                end if;
                if s1_seg < 4 then
                    if s1_seg < f_vol then
                        col := C_SEG(s1_seg);
                    else
                        col := C_SEG_APAG;
                    end if;
                end if;
                s2_lcol <= col;

                -- FORMA DE ONDA: la linea une la y de la columna anterior
                -- con la de esta (asi salen los tramos verticales)
                col := C_PANEL;
                if s1_ocaja = '1' then
                    if s1_omarco = '1' then
                        col := C_ONDA_MARCO;
                    else
                        col := C_ONDA_FONDO;
                        if s1_eje = '1' then
                            col := C_ONDA_EJE;
                        end if;
                        if s1_wini = '1' then
                            yp := s1_wy;
                        else
                            yp := s2_wyp;
                        end if;
                        if yp < s1_wy then
                            lo := yp;
                            hi := s1_wy;
                        else
                            lo := s1_wy;
                            hi := yp;
                        end if;
                        if s1_yw >= lo and s1_yw <= hi + 1 then
                            col := C_ONDA;
                        end if;
                    end if;
                end if;
                s2_mcol <= col;
                s2_wyp  <= s1_wy;

                -- VOCES: barras de nivel
                col := C_PANEL;
                if s1_nv < 3 then
                    if s1_nvm = '1' then
                        col := C_BARRA_MARCO;
                    elsif s1_nvx < v_nivel(s1_nv) then
                        col := C_VOZ(s1_nv);
                    else
                        col := C_BARRA_FONDO;
                    end if;
                end if;
                s2_rcol <= col;

                -- SECUENCIADOR: punto rojo y barra, llena si
                -- (x - BAR_X) * den < umbral
                col := C_PANEL;
                if f_rec = '1' and s1_rec = '1' then
                    col := C_REC;
                end if;
                if s1_bar = '1' then
                    if s1_barm = '1' then
                        col := C_BARRA_MARCO;
                    elsif s1_prod < umbral then
                        col := C_AVAN(f_est);
                    else
                        col := C_BARRA_FONDO;
                    end if;
                end if;
                s2_scol <= col;

                s2_zona <= s1_zona;
                s2_hs   <= s1_hs;
                s2_vs   <= s1_vs;
                s2_vis  <= s1_vis;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Etapa 3: color de fondo segun la zona y letra que toca
    -- (titulo en la banda, etiqueta en el piano o cuadricula)
    ------------------------------------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            if pix_en = '1' then
                case s2_zona is
                    when Z_BANDA => s3_base <= s2_bcol;
                    when Z_PIANO => s3_base <= s2_pcol;
                    when Z_MARCO => s3_base <= C_MARCO;
                    when Z_PL    => s3_base <= s2_lcol;
                    when Z_PM    => s3_base <= s2_mcol;
                    when Z_PR    => s3_base <= s2_rcol;
                    when Z_PS    => s3_base <= s2_scol;
                    when others  => s3_base <= C_FONDO;
                end case;
                if s2_zona = Z_BANDA and s2_ien = '1' then
                    s3_cod <= s2_cd_i;
                    s3_gx  <= s2_igx;
                    s3_gy  <= s2_igy;
                    s3_fg  <= C_BLANCO;
                elsif s2_zona = Z_PIANO and s2_lab = '1' then
                    s3_cod <= s2_cd_l;
                    s3_gx  <= s2_lgx;
                    s3_gy  <= s2_lgy;
                    s3_fg  <= s2_fg_l;
                else
                    s3_cod <= s2_cd_t;
                    s3_gx  <= s2_gx_t;
                    s3_gy  <= s2_gy_t;
                    s3_fg  <= s2_fg_t;
                end if;
                s3_hs  <= s2_hs;
                s3_vs  <= s2_vs;
                s3_vis <= s2_vis;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- Etapa 4: fuente y color final
    ------------------------------------------------------------
    process (clk)
        variable bits : std_logic_vector(4 downto 0);
        variable px   : std_logic;
    begin
        if rising_edge(clk) then
            if pix_en = '1' then
                bits := fila_fuente(s3_cod, s3_gy);
                px := '0';
                if s3_gx <= 4 then
                    px := bits(4 - s3_gx);
                end if;
                if s3_vis = '0' then
                    s4_rgb <= C_NEGRO;
                elsif px = '1' then
                    s4_rgb <= s3_fg;
                else
                    s4_rgb <= s3_base;
                end if;
                s4_hs <= s3_hs;
                s4_vs <= s3_vs;
            end if;
        end if;
    end process;

    vga_r  <= s4_rgb(11 downto 8);
    vga_g  <= s4_rgb(7 downto 4);
    vga_b  <= s4_rgb(3 downto 0);
    vga_hs <= s4_hs;
    vga_vs <= s4_vs;

end architecture rtl;
