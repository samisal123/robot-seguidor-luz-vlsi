-- ============================================================
-- tb_vga_ui.vhd
-- Testbench de vga_ui. Arma cada cuadro como lo veria un monitor
-- (a partir de VSYNC y HSYNC, leyendo cada pixel a la mitad de sus
-- 40 ns) y revisa:
--   - tiempos: HSYNC de 96 pixeles cada 800, VSYNC de 2 lineas,
--     cuadro de 525 lineas, VSYNC al inicio de la linea, color 0
--     fuera de la zona visible;
--   - en los cuatro modos: color de la banda, titulo (letra por
--     letra con la fuente), textos de parametros, voces y
--     secuenciador (incluidos los numeros en BCD), teclas del
--     piano encendidas por voz (blancas y negras, notas fuera de
--     rango, gate en 0), etiquetas C<octava>, la onda dibujada en
--     puntos calculados a mano para las cuatro formas, medidor de
--     volumen (y su tope de 4), barras de nivel, barra del
--     secuenciador justo en el limite de llenado, foco del
--     metronomo (tiempo, acento, apagado), punto de grabacion que
--     parpadea y el renglon resaltado en CONFIGURACION.
-- DESTELLO = 200 000 ciclos (8 ms a 25 MHz) y PARPADEO = 0 (cambia cada
-- cuadro) para no simular segundos.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;
use work.fuente_5x7.all;

entity tb_vga_ui is
end entity tb_vga_ui;

architecture sim of tb_vga_ui is
    constant T_CLK : time := 40 ns;    -- 25 MHz
    constant T_PIX : time := T_CLK;    -- un pixel por ciclo

    subtype t_color is std_logic_vector(2 downto 0);   -- R G B, un bit cada uno

    constant NEGRO    : t_color := "000";
    constant AZUL     : t_color := "001";
    constant VERDE    : t_color := "010";
    constant CIAN     : t_color := "011";
    constant ROJO     : t_color := "100";
    constant MAGENTA  : t_color := "101";
    constant AMARILLO : t_color := "110";
    constant BLANCO   : t_color := "111";

    -- colores esperados (la especificacion de la pantalla)
    constant C_FONDO   : t_color := NEGRO;
    constant C_PANEL   : t_color := NEGRO;
    constant C_MARCO   : t_color := AZUL;
    constant C_TEXTO   : t_color := BLANCO;
    constant C_TENUE   : t_color := CIAN;
    constant C_PIE     : t_color := AZUL;
    constant C_ENCAB   : t_color := AMARILLO;
    constant C_RESALTE : t_color := AMARILLO;
    constant C_NEGRO   : t_color := NEGRO;
    constant C_BLANCO  : t_color := BLANCO;
    constant C_B_INT   : t_color := AZUL;
    constant C_B_GRA   : t_color := ROJO;
    constant C_B_REP   : t_color := VERDE;
    constant C_B_CONF  : t_color := MAGENTA;
    constant C_RECUA   : t_color := NEGRO;
    constant C_F_OFF   : t_color := AZUL;
    constant C_F_APAG  : t_color := BLANCO;
    constant C_F_BEAT  : t_color := VERDE;
    constant C_F_ACEN  : t_color := ROJO;
    constant C_CAJA    : t_color := NEGRO;
    constant C_BLANCA  : t_color := BLANCO;
    constant C_NEGRA   : t_color := NEGRO;
    constant C_ETIQ    : t_color := NEGRO;
    constant C_V1      : t_color := ROJO;
    constant C_V2      : t_color := VERDE;
    constant C_V3      : t_color := CIAN;
    constant C_ONDA    : t_color := AMARILLO;
    constant C_O_FONDO : t_color := NEGRO;
    constant C_O_EJE   : t_color := AZUL;
    constant C_O_MARCO : t_color := AZUL;
    constant C_BA_FON  : t_color := NEGRO;
    constant C_BA_MAR  : t_color := AZUL;
    constant C_SEG0    : t_color := VERDE;
    constant C_SEG1    : t_color := VERDE;
    constant C_SEG2    : t_color := AMARILLO;
    constant C_SEG3    : t_color := ROJO;
    constant C_SEG_OFF : t_color := AZUL;
    constant C_REC     : t_color := ROJO;
    constant C_EST_GRA : t_color := ROJO;
    constant C_EST_REP : t_color := VERDE;
    constant C_AV_ESP  : t_color := CIAN;
    constant C_AV_GRA  : t_color := ROJO;
    constant C_AV_REP  : t_color := VERDE;

    -- geometria que se revisa
    constant ONDA_X : natural := 288;
    constant ONDA_Y : natural := 264;
    constant PIA_X  : natural := 40;
    constant PIA_Y  : natural := 104;
    constant NIV_X  : natural := 445;
    constant BAR_X  : natural := 120;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal modo       : std_logic_vector(1 downto 0) := M_INT;
    signal estado_sec : std_logic_vector(1 downto 0) := S_ESPERA;
    signal forma      : std_logic_vector(1 downto 0) := W_CUADRADA;
    signal atk        : std_logic_vector(1 downto 0) := "00";
    signal dec        : std_logic_vector(1 downto 0) := "00";
    signal sus        : std_logic_vector(1 downto 0) := "00";
    signal rel        : std_logic_vector(1 downto 0) := "00";
    signal volumen    : std_logic_vector(2 downto 0) := "000";
    signal tempo      : std_logic_vector(1 downto 0) := "00";
    signal efecto     : std_logic_vector(1 downto 0) := E_NINGUNO;
    signal metro_on   : std_logic := '0';
    signal beat       : std_logic := '0';
    signal acento     : std_logic := '0';
    signal octava     : std_logic_vector(2 downto 0) := "100";
    signal notas      : std_logic_vector(20 downto 0) := (others => '0');
    signal gates      : std_logic_vector(2 downto 0) := "000";
    signal niveles    : std_logic_vector(23 downto 0) := (others => '0');
    signal parametro  : std_logic_vector(2 downto 0) := "000";
    signal eventos    : std_logic_vector(8 downto 0) := (others => '0');
    signal posicion   : std_logic_vector(8 downto 0) := (others => '0');
    signal vga_r, vga_g, vga_b : std_logic;
    signal vga_hs, vga_vs : std_logic;
    signal fin        : boolean := false;

    function n7 (n : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(n, 7));
    end function;

    function n8 (n : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(n, 8));
    end function;

    function n9 (n : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(n, 9));
    end function;

    function hex (v : t_color) return string is
        variable s : string(1 to 3);
    begin
        for i in 0 to 2 loop
            if v(2 - i) = '1' then
                s(i + 1) := '1';
            elsif v(2 - i) = '0' then
                s(i + 1) := '0';
            else
                s(i + 1) := 'X';
            end if;
        end loop;
        return s;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin else '0';

    dut : entity work.vga_ui
        generic map (DESTELLO => 200_000, PARPADEO => 0)
        port map (
            clk => clk, rst => rst, modo => modo, estado_sec => estado_sec,
            forma => forma, atk => atk, dec => dec, sus => sus, rel => rel,
            volumen => volumen, tempo => tempo, efecto => efecto,
            metro_on => metro_on, beat => beat, acento => acento,
            octava => octava, notas => notas, gates => gates, niveles => niveles,
            parametro => parametro, eventos => eventos, posicion => posicion,
            vga_r => vga_r, vga_g => vga_g, vga_b => vga_b,
            vga_hs => vga_hs, vga_vs => vga_vs);

    process
        type t_linea  is array (0 to 639) of t_color;
        type t_cuadro is array (0 to 479) of t_linea;
        variable q       : t_cuadro;
        variable errores : natural := 0;
        variable t0, t1, t2 : time;
        variable t_cuadro_ant : time;
        variable rec_ant : boolean;

        procedure falla (msg : string) is
        begin
            errores := errores + 1;
            report "tb_vga_ui: " & msg severity error;
        end procedure;

        -- arma el cuadro que empieza; se llama justo despues del
        -- flanco de subida de VSYNC (linea 492)
        procedure capturar is
        begin
            for i in 1 to 33 loop                   -- lineas 492 a 524
                wait until falling_edge(vga_hs);
            end loop;
            for yy in 0 to 479 loop
                if yy > 0 then
                    wait until falling_edge(vga_hs);
                end if;
                wait for 144 * T_PIX + T_PIX / 2;   -- 160 - 16 pixeles
                for xx in 0 to 639 loop
                    q(yy)(xx) := vga_r & vga_g & vga_b;
                    if xx < 639 then
                        wait for T_PIX;
                    end if;
                end loop;
            end loop;
        end procedure;

        -- espera el inicio del cuadro siguiente (si no se esta ya en
        -- el flanco de VSYNC), da un tiempo del metronomo si se pide y
        -- arma el cuadro
        procedure cuadro (pulso : boolean; ac : std_logic; esperar : boolean) is
        begin
            if esperar then
                wait until rising_edge(vga_vs);
            end if;
            t_cuadro_ant := now;
            if pulso then
                wait until rising_edge(clk);
                beat   <= '1';
                acento <= ac;
                wait until rising_edge(clk);
                beat   <= '0';
                acento <= '0';
            end if;
            capturar;
        end procedure;

        procedure px (x, y : natural; c : t_color; que : string) is
        begin
            if q(y)(x) /= c then
                falla(que & ": pixel (" & integer'image(x) & "," & integer'image(y) & ") = " &
                      hex(q(y)(x)) & ", se esperaba " & hex(c));
            end if;
        end procedure;

        -- letra de 5x7 al doble (bloques de 2x2) con esquina en (x0, y0);
        -- ancho y alto revisados: 6x8 bloques (incluye el hueco)
        procedure letra2 (x0, y0 : natural; cd : t_cod; fg, bg : t_color;
                          huecos : boolean; ok : out boolean) is
            variable bits : std_logic_vector(4 downto 0);
            variable esp  : t_color;
            variable nx, ny : natural;
        begin
            ok := true;
            if huecos then
                nx := 5;
                ny := 7;
            else
                nx := 4;
                ny := 6;
            end if;
            for gy in 0 to ny loop
                bits := fila_fuente(cd, gy);
                for gx in 0 to nx loop
                    if gx <= 4 and bits(4 - gx) = '1' then
                        esp := fg;
                    else
                        esp := bg;
                    end if;
                    for d in 0 to 3 loop
                        if q(y0 + 2 * gy + d / 2)(x0 + 2 * gx + d mod 2) /= esp then
                            ok := false;
                        end if;
                    end loop;
                end loop;
            end loop;
        end procedure;

        -- texto en la cuadricula de 12x16 desde (renglon r, columna c0)
        procedure texto (r, c0 : natural; s : string; fg, bg : t_color) is
            variable ok : boolean;
        begin
            for i in s'range loop
                letra2(12 * (c0 + i - s'low), 16 * r, cod_car(s(i)), fg, bg, true, ok);
                if not ok then
                    falla("texto '" & s & "' en renglon " & integer'image(r) & ", columna " &
                          integer'image(c0) & ": la letra " & integer'image(i - s'low + 1) &
                          " no coincide (letra " & hex(fg) & " sobre " & hex(bg) & ")");
                    exit;
                end if;
            end loop;
        end procedure;

        -- titulo x4: celdas de 24x32 desde (24, 18), 28 lineas de alto
        procedure titulo (s : string; bg : t_color) is
            variable bits : std_logic_vector(4 downto 0);
            variable esp  : t_color;
            variable ok   : boolean;
        begin
            for i in 0 to 13 loop
                ok := true;
                for gy in 0 to 6 loop
                    bits := fila_fuente(cod_car(s(s'low + i)), gy);
                    for gx in 0 to 5 loop
                        if gx <= 4 and bits(4 - gx) = '1' then
                            esp := C_BLANCO;
                        else
                            esp := bg;
                        end if;
                        for d in 0 to 15 loop
                            if q(18 + 4 * gy + d / 4)(24 + 24 * i + 4 * gx + d mod 4) /= esp then
                                ok := false;
                            end if;
                        end loop;
                    end loop;
                end loop;
                if not ok then
                    falla("titulo '" & s & "': la letra " & integer'image(i + 1) & " no coincide");
                    exit;
                end if;
            end loop;
            -- abajo del titulo (lineas 46 a 63) solo hay banda
            for x in 24 to 359 loop
                if q(46)(x) /= bg or q(63)(x) /= bg then
                    falla("titulo '" & s & "': la banda abajo del titulo no es lisa");
                    exit;
                end if;
            end loop;
        end procedure;

        -- etiqueta C<n> de una tecla C del piano (letras x2)
        procedure etiqueta (w : natural; dig : natural; fg, bg : t_color) is
            variable ok : boolean;
        begin
            letra2(PIA_X + 40 * w + 8, PIA_Y + 98, cod_car('C'), fg, bg, false, ok);
            if ok then
                letra2(PIA_X + 40 * w + 20, PIA_Y + 98, CH_0 + dig, fg, bg, false, ok);
            end if;
            if not ok then
                falla("etiqueta C" & integer'image(dig) & " de la tecla blanca " & integer'image(w));
            end if;
        end procedure;

        -- punto de la onda: columna xw (0-127), y relativa (0-95)
        procedure onda (xw, yw : natural; c : t_color; que : string) is
        begin
            px(ONDA_X + xw, ONDA_Y + yw, c, que);
        end procedure;

        -- limite de la barra del secuenciador: lleno hasta xb_lleno
        procedure barra (xb_lleno : natural; c : t_color; que : string) is
        begin
            px(BAR_X + xb_lleno, 440, c, que & " (ultimo pixel lleno)");
            px(BAR_X + xb_lleno + 1, 440, C_BA_FON, que & " (primer pixel vacio)");
        end procedure;

    begin
        wait for 10 * T_CLK;
        wait until rising_edge(clk);
        rst <= '0';

        --------------------------------------------------------
        -- Tiempos de las sincronias
        --------------------------------------------------------
        wait until falling_edge(vga_hs);
        t0 := now;
        wait until rising_edge(vga_hs);
        t1 := now;
        wait until falling_edge(vga_hs);
        t2 := now;
        if t1 - t0 /= 96 * T_PIX then
            falla("HSYNC dura " & time'image(t1 - t0) & ", se esperaban 96 pixeles");
        end if;
        if t2 - t0 /= 800 * T_PIX then
            falla("la linea dura " & time'image(t2 - t0) & ", se esperaban 800 pixeles");
        end if;
        wait for 48 * T_PIX;
        if vga_r & vga_g & vga_b /= C_NEGRO then
            falla("el color no es 0 durante HSYNC");
        end if;
        wait until falling_edge(vga_vs);
        t0 := now;
        wait for 300 * T_PIX;
        if vga_r & vga_g & vga_b /= C_NEGRO then
            falla("el color no es 0 durante VSYNC");
        end if;
        wait until falling_edge(vga_hs);
        t2 := now;
        wait until rising_edge(vga_vs);
        t1 := now;
        if t1 - t0 /= 2 * 800 * T_PIX then
            falla("VSYNC dura " & time'image(t1 - t0) & ", se esperaban 2 lineas");
        end if;
        if t2 - t0 /= 656 * T_PIX then
            falla("VSYNC no empieza al inicio de la linea");
        end if;

        --------------------------------------------------------
        -- Cuadro 1: INTERPRETACION
        --------------------------------------------------------
        modo <= M_INT;
        estado_sec <= S_ESPERA;
        forma <= W_CUADRADA;
        atk <= "00";
        dec <= "11";
        sus <= "01";
        rel <= "10";
        volumen <= "010";
        tempo <= "10";
        efecto <= E_TREMOLO;
        metro_on <= '1';
        octava <= "100";                                -- base 48 = C4
        notas <= n7(0) & n7(49) & n7(48);               -- V1 C4, V2 C#4, V3 nada
        gates <= "011";
        niveles <= n8(0) & n8(101) & n8(200);
        parametro <= "011";
        eventos <= n9(123);
        posicion <= n9(45);
        cuadro(true, '0', false);              -- ya en el flanco de VSYNC

        px(300, 4, C_B_INT, "banda INTERPRETACION");
        px(2, 300, C_FONDO, "fondo");
        px(6, 300, C_MARCO, "marco del panel PARAMETROS");
        px(267, 300, C_MARCO, "marco del panel FORMA DE ONDA");
        px(633, 300, C_MARCO, "marco del panel VOCES");
        px(300, 393, C_MARCO, "marco del panel SECUENCIADOR");
        px(264, 300, C_FONDO, "fondo entre paneles");
        titulo("INTERPRETACION", C_B_INT);
        texto(1, 36, "METRONOMO ON ", C_BLANCO, C_B_INT);
        texto(2, 36, "120 BPM", C_BLANCO, C_B_INT);
        px(612, 32, C_F_BEAT, "foco en un tiempo sin acento");
        px(593, 13, C_RECUA, "recuadro del foco");
        px(608, 16, C_F_BEAT, "orilla del foco (renglon de arriba)");
        px(607, 16, C_RECUA, "fuera del foco (renglon de arriba)");
        px(623, 47, C_RECUA, "fuera del foco (renglon de abajo)");
        texto(5, 10, "TECLADO 1", C_TENUE, C_FONDO);
        texto(5, 34, "TECLADO 2", C_TENUE, C_FONDO);
        -- piano: V1 en C (blanca 0), V2 en C# (negra entre 0 y 1)
        px(300, 97, C_B_INT, "franja del piano");
        px(60, 180, C_V1, "tecla C con V1");
        px(50, 130, C_V1, "tecla C con V1 junto a la negra");
        px(70, 130, C_V2, "tecla C# con V2 (lado izquierdo)");
        px(85, 130, C_V2, "tecla C# con V2 (lado derecho)");
        px(70, PIA_Y + 71, C_V2, "ultima linea de la tecla negra");
        px(70, PIA_Y + 72, C_V1, "tecla blanca abajo de la negra");
        px(60, PIA_Y + 119, C_V1, "ultima linea de la tecla blanca");
        px(60, PIA_Y + 120, C_CAJA, "caja abajo de las teclas");
        px(100, 180, C_BLANCA, "tecla D sin voz");
        px(120, 130, C_NEGRA, "tecla D# sin voz");
        px(77, 200, C_V1, "tecla C hasta su pixel 37");
        px(78, 200, C_CAJA, "separacion entre blancas");
        px(PIA_X + 2 * 40 + 20, 130, C_BLANCA, "tecla E (sin negra a los lados)");
        etiqueta(0, 4, C_BLANCO, C_V1);
        etiqueta(7, 5, C_ETIQ, C_BLANCA);
        -- parametros
        texto(15, 2, "PARAMETROS", C_ENCAB, C_PANEL);
        texto(16, 2, "FORMA   ", C_TENUE, C_PANEL);
        texto(16, 10, "CUADRADA   ", C_TEXTO, C_PANEL);
        texto(17, 2, "ATTACK  ", C_TENUE, C_PANEL);
        texto(17, 10, "2 MS       ", C_TEXTO, C_PANEL);
        texto(18, 2, "DECAY   ", C_TENUE, C_PANEL);
        texto(18, 10, "1500 MS    ", C_TEXTO, C_PANEL);
        texto(19, 1, " SUSTAIN ", C_TENUE, C_PANEL);    -- sin resalte fuera de CONF
        texto(19, 10, "50 %       ", C_TEXTO, C_PANEL);
        texto(20, 2, "RELEASE ", C_TENUE, C_PANEL);
        texto(20, 10, "500 MS     ", C_TEXTO, C_PANEL);
        texto(21, 2, "VOLUMEN ", C_TENUE, C_PANEL);
        texto(21, 10, "2 ", C_TEXTO, C_PANEL);
        texto(22, 2, "TEMPO   ", C_TENUE, C_PANEL);
        texto(22, 10, "120 BPM    ", C_TEXTO, C_PANEL);
        texto(23, 2, "EFECTO  ", C_TENUE, C_PANEL);
        texto(23, 10, "TREMOLO    ", C_TEXTO, C_PANEL);
        px(150, 343, C_SEG0, "volumen 2: segmento 1");
        px(172, 343, C_SEG1, "volumen 2: segmento 2");
        px(194, 343, C_SEG_OFF, "volumen 2: segmento 3");
        px(216, 343, C_SEG_OFF, "volumen 2: segmento 4");
        px(163, 343, C_PANEL, "hueco entre segmentos");
        -- cuadrada: arriba (y 17) en la primera mitad, abajo (80) en
        -- la segunda, tramo vertical en la columna 64
        texto(15, 23, "FORMA DE ONDA", C_ENCAB, C_PANEL);
        onda(10, 17, C_ONDA, "cuadrada arriba");
        onda(10, 18, C_ONDA, "cuadrada arriba, 2 pixeles");
        onda(10, 19, C_O_FONDO, "cuadrada arriba, sin 3er pixel");
        onda(10, 16, C_O_FONDO, "cuadrada arriba, nada encima");
        onda(64, 40, C_ONDA, "cuadrada tramo vertical");
        onda(100, 80, C_ONDA, "cuadrada abajo");
        onda(100, 79, C_O_FONDO, "cuadrada abajo, nada encima");
        onda(8, 48, C_O_EJE, "eje punteado (raya)");
        onda(12, 48, C_O_FONDO, "eje punteado (hueco)");
        px(ONDA_X - 1, 300, C_O_MARCO, "marco de la onda");
        px(ONDA_X + 128, 300, C_O_MARCO, "marco de la onda");
        texto(23, 24, " CUADRADA ", C_ONDA, C_PANEL);
        -- voces
        texto(15, 37, "VOCES", C_ENCAB, C_PANEL);
        texto(16, 37, "V1", C_V1, C_PANEL);
        texto(16, 39, " C4 ", C_TEXTO, C_PANEL);
        texto(18, 37, "V2", C_V2, C_PANEL);
        texto(18, 39, " C#4", C_TEXTO, C_PANEL);
        texto(20, 37, "V3", C_V3, C_PANEL);
        texto(20, 39, " ---", C_TENUE, C_PANEL);
        texto(23, 37, "OCTAVA ", C_TENUE, C_PANEL);
        texto(23, 44, "4", C_TEXTO, C_PANEL);
        px(NIV_X + 99, 280, C_V1, "nivel V1 = 200: pixel 99");
        px(NIV_X + 100, 280, C_BA_FON, "nivel V1 = 200: pixel 100");
        px(NIV_X - 1, 280, C_BA_MAR, "marco de la barra de nivel");
        for i in 0 to 2 loop
            px(500, 275 + 32 * i, C_BA_MAR, "marco de arriba de la barra de nivel " & integer'image(i + 1));
            px(500, 284 + 32 * i, C_BA_MAR, "marco de abajo de la barra de nivel " & integer'image(i + 1));
        end loop;
        px(NIV_X + 50, 312, C_V2, "nivel V2 = 101: pixel 50");
        px(NIV_X + 51, 312, C_BA_FON, "nivel V2 = 101: pixel 51");
        px(NIV_X, 344, C_BA_FON, "nivel V3 = 0");
        -- secuenciador: EN ESPERA, barra = eventos / 256
        -- 123 * 384 / 256 = 184.5 -> lleno hasta el pixel 184
        texto(25, 2, "SECUENCIADOR", C_ENCAB, C_PANEL);
        texto(25, 15, "EN ESPERA    ", C_TEXTO, C_PANEL);
        texto(25, 31, "EVENTOS ", C_TENUE, C_PANEL);
        texto(25, 39, "123", C_TEXTO, C_PANEL);
        texto(25, 42, "/256", C_TENUE, C_PANEL);
        texto(27, 2, "MEMORIA", C_TENUE, C_PANEL);
        texto(27, 44, "POS ", C_TENUE, C_PANEL);
        texto(27, 48, "045", C_TEXTO, C_PANEL);
        barra(184, C_AV_ESP, "barra en espera 123/256");
        px(BAR_X - 1, 440, C_BA_MAR, "marco de la barra");
        px(353, 407, C_PANEL, "sin punto de grabacion en espera");
        texto(29, 13, "DISENO DIGITAL VLSI  FI UNAM", C_PIE, C_FONDO);

        --------------------------------------------------------
        -- Cuadros 2 y 3: GRABACION (el punto rojo parpadea)
        --------------------------------------------------------
        modo <= M_GRA;
        estado_sec <= S_GRABANDO;
        forma <= W_TRIANGULAR;
        eventos <= n9(7);
        posicion <= n9(7);
        cuadro(true, '1', true);

        px(300, 4, C_B_GRA, "banda GRABACION");
        titulo("GRABACION     ", C_B_GRA);
        px(612, 32, C_F_ACEN, "foco en el tiempo con acento");
        px(300, 97, C_B_GRA, "franja del piano en GRABACION");
        texto(25, 15, "GRABANDO     ", C_EST_GRA, C_PANEL);
        texto(25, 39, "007", C_TEXTO, C_PANEL);
        texto(27, 2, "MEMORIA", C_TENUE, C_PANEL);
        -- 7 * 384 / 256 = 10.5 -> lleno hasta el pixel 10
        barra(10, C_AV_GRA, "barra grabando 7/256");
        -- triangular: sube de 80 a 17 y baja
        onda(0, 80, C_ONDA, "triangular columna 0");
        onda(32, 48, C_ONDA, "triangular columna 32");
        onda(63, 17, C_ONDA, "triangular columna 63");
        onda(64, 17, C_ONDA, "triangular columna 64");
        onda(96, 49, C_ONDA, "triangular columna 96");
        onda(32, 20, C_O_FONDO, "triangular lejos de la linea");
        texto(23, 24, "TRIANGULAR", C_ONDA, C_PANEL);
        rec_ant := q(407)(353) = C_REC;
        if not rec_ant and q(407)(353) /= C_PANEL then
            falla("punto de grabacion de color " & hex(q(407)(353)));
        end if;
        t0 := t_cuadro_ant;

        cuadro(false, '0', true);
        if t_cuadro_ant - t0 /= 525 * 800 * T_PIX then
            falla("el cuadro dura " & time'image(t_cuadro_ant - t0) & ", se esperaban 525 lineas");
        end if;
        if rec_ant then
            px(353, 407, C_PANEL, "punto de grabacion apagado en el cuadro siguiente");
        else
            px(353, 407, C_REC, "punto de grabacion encendido en el cuadro siguiente");
        end if;
        px(349, 407, C_PANEL, "orilla del punto de grabacion");
        px(612, 32, C_F_APAG, "foco apagado entre tiempos");

        --------------------------------------------------------
        -- Cuadro 4: REPRODUCCION
        --------------------------------------------------------
        modo <= M_REP;
        estado_sec <= S_REPRODUCE;
        forma <= W_SIERRA;
        metro_on <= '0';
        notas <= n7(64) & n7(60) & n7(57);              -- A4, C5, E5
        gates <= "111";
        niveles <= n8(2) & n8(1) & n8(255);             -- V1 255, V2 1, V3 2
        eventos <= n9(200);
        posicion <= n9(100);
        cuadro(false, '0', true);

        px(300, 4, C_B_REP, "banda REPRODUCCION");
        titulo("REPRODUCCION  ", C_B_REP);
        texto(1, 36, "METRONOMO OFF", C_BLANCO, C_B_REP);
        px(612, 32, C_F_OFF, "foco con el metronomo apagado");
        texto(25, 15, "REPRODUCIENDO", C_EST_REP, C_PANEL);
        texto(25, 39, "200", C_TEXTO, C_PANEL);
        texto(27, 2, "AVANCE ", C_TENUE, C_PANEL);
        texto(27, 48, "100", C_TEXTO, C_PANEL);
        -- 100 * 384 / 200 = 192 -> lleno hasta el pixel 191
        barra(191, C_AV_REP, "barra reproduciendo 100/200");
        px(PIA_X + 5 * 40 + 20, 180, C_V1, "tecla A (blanca 5) con V1");
        px(PIA_X + 7 * 40 + 20, 180, C_V2, "tecla C5 (blanca 7) con V2");
        px(PIA_X + 9 * 40 + 20, 180, C_V3, "tecla E5 (blanca 9) con V3");
        etiqueta(7, 5, C_BLANCO, C_V2);
        texto(16, 39, " A4 ", C_TEXTO, C_PANEL);
        texto(18, 39, " C5 ", C_TEXTO, C_PANEL);
        texto(20, 39, " E5 ", C_TEXTO, C_PANEL);
        px(NIV_X + 0, 344, C_V3, "nivel V3 = 2: pixel 0");
        px(NIV_X + 1, 344, C_BA_FON, "nivel V3 = 2: pixel 1");
        px(NIV_X + 0, 312, C_V2, "nivel V2 = 1: pixel 0");
        px(NIV_X + 1, 312, C_BA_FON, "nivel V2 = 1: pixel 1");
        px(NIV_X + 127, 280, C_V1, "nivel V1 = 255: lleno");
        -- sierra: de 80 a 17
        onda(0, 80, C_ONDA, "sierra columna 0");
        onda(64, 48, C_ONDA, "sierra columna 64");
        onda(127, 17, C_ONDA, "sierra columna 127");
        onda(127, 30, C_O_FONDO, "sierra lejos de la linea");
        texto(23, 24, "  SIERRA  ", C_ONDA, C_PANEL);

        --------------------------------------------------------
        -- Cuadro 5: CONFIGURACION con SUSTAIN elegido mientras el
        -- secuenciador graba; notas fuera del piano (B3 y C6 con
        -- octava 4) y F4 sin gate
        --------------------------------------------------------
        modo <= M_CONF;
        estado_sec <= S_GRABANDO;
        forma <= W_SENO;
        metro_on <= '1';
        parametro <= "011";
        sus <= "11";
        volumen <= "100";
        efecto <= E_AMBOS;
        notas <= n7(53) & n7(72) & n7(47);
        gates <= "011";
        niveles <= (others => '0');
        eventos <= n9(37);
        posicion <= n9(0);
        cuadro(false, '0', true);

        px(300, 4, C_B_CONF, "banda CONFIGURACION");
        titulo("CONFIGURACION ", C_B_CONF);
        texto(19, 1, ">SUSTAIN 100 %      ", C_NEGRO, C_RESALTE);
        px(10, 312, C_RESALTE, "orilla izquierda del resalte");
        px(9, 312, C_PANEL, "fuera del resalte (izquierda)");
        px(257, 312, C_RESALTE, "orilla derecha del resalte");
        px(258, 312, C_PANEL, "fuera del resalte (derecha)");
        texto(18, 1, " DECAY   ", C_TENUE, C_PANEL);
        texto(20, 1, " RELEASE ", C_TENUE, C_PANEL);
        texto(21, 10, "4 ", C_TEXTO, C_PANEL);
        px(216, 343, C_SEG3, "volumen 4: segmento 4");
        texto(23, 10, "TREMOLO+ECO", C_TEXTO, C_PANEL);
        texto(23, 24, "   SENO   ", C_ONDA, C_PANEL);
        -- seno: 0 en la columna 0, maximo en la 32, minimo en la 96
        onda(0, 48, C_ONDA, "seno columna 0");
        onda(32, 17, C_ONDA, "seno columna 32");
        onda(96, 80, C_ONDA, "seno columna 96");
        onda(64, 20, C_O_FONDO, "seno lejos de la linea");
        -- B3 y C6 quedan fuera de C4..B5: ninguna tecla encendida
        px(PIA_X + 13 * 40 + 20, 180, C_BLANCA, "B5 sin voz");
        px(60, 180, C_BLANCA, "C4 sin voz");
        px(PIA_X + 3 * 40 + 20, 180, C_BLANCA, "F4 con gate en 0");
        texto(16, 39, " B3 ", C_TEXTO, C_PANEL);
        texto(18, 39, " C6 ", C_TEXTO, C_PANEL);
        texto(20, 39, " F4 ", C_TENUE, C_PANEL);
        texto(25, 15, "GRABANDO     ", C_EST_GRA, C_PANEL);
        texto(27, 2, "MEMORIA", C_TENUE, C_PANEL);
        -- 37 * 384 / 256 = 55.5 -> lleno hasta el pixel 55, color de grabacion
        barra(55, C_AV_GRA, "barra grabando en CONFIGURACION 37/256");
        texto(25, 39, "037", C_TEXTO, C_PANEL);
        texto(27, 48, "000", C_TEXTO, C_PANEL);
        px(612, 32, C_F_APAG, "foco encendido pero sin tiempo");

        --------------------------------------------------------
        -- Cuadro 6: CONFIGURACION con EFECTO elegido, octava 2,
        -- teclas de la orilla derecha, negra con gate en 0,
        -- volumen 5 -> 4, memoria llena y posicion 511
        --------------------------------------------------------
        estado_sec <= S_ESPERA;
        parametro <= "111";
        efecto <= E_NINGUNO;
        octava <= "010";                                -- base 24 = C2
        notas <= n7(46) & n7(47) & n7(30);              -- V1 F#2 sin gate, V2 B3, V3 A#3
        gates <= "110";
        volumen <= "101";
        eventos <= n9(256);
        posicion <= n9(511);
        cuadro(false, '0', true);

        texto(23, 1, ">EFECTO  NINGUNO    ", C_NEGRO, C_RESALTE);
        texto(19, 1, " SUSTAIN ", C_TENUE, C_PANEL);
        etiqueta(0, 2, C_ETIQ, C_BLANCA);
        etiqueta(7, 3, C_ETIQ, C_BLANCA);
        texto(23, 37, "OCTAVA ", C_TENUE, C_PANEL);
        texto(23, 44, "2", C_TEXTO, C_PANEL);
        px(60, 180, C_BLANCA, "C2 sin voz");
        px(PIA_X + 3 * 40 + 40, 130, C_NEGRA, "F#2 (negra) con gate en 0");
        px(PIA_X + 13 * 40 + 20, 180, C_V2, "B3 (blanca 13) con V2");
        px(PIA_X + 12 * 40 + 30, 130, C_V3, "A#3 (negra a la derecha de la blanca 12) con V3");
        px(PIA_X + 13 * 40 + 5, 130, C_V3, "A#3, parte sobre la blanca 13");
        px(PIA_X + 13 * 40 + 20, 130, C_V2, "B3 junto a la negra");
        texto(16, 39, " F#2", C_TENUE, C_PANEL);
        texto(18, 39, " B3 ", C_TEXTO, C_PANEL);
        texto(20, 39, " A#3", C_TEXTO, C_PANEL);
        texto(21, 10, "4 ", C_TEXTO, C_PANEL);
        px(216, 343, C_SEG3, "volumen 5 se muestra como 4");
        texto(25, 39, "256", C_TEXTO, C_PANEL);
        texto(27, 48, "511", C_TEXTO, C_PANEL);
        -- 256 * 384 / 256 = 384 -> barra llena
        px(BAR_X + 383, 440, C_AV_ESP, "barra llena con 256 eventos");

        --------------------------------------------------------
        if errores = 0 then
            report "tb_vga_ui: OK";
        else
            report "tb_vga_ui: " & integer'image(errores) & " errores" severity error;
        end if;
        fin <= true;
        wait;
    end process;

end architecture sim;
