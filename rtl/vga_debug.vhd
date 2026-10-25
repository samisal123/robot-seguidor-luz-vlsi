-- ============================================================
-- vga_debug.vhd
-- Tablero de depuracion por VGA, 640 x 480 a 60 Hz (caracteristica
-- extra). El pixel avanza cada 2 ciclos de 50 MHz (25 MHz; el
-- estandar pide 25.175 MHz y los monitores lo aceptan).
-- Color de 4 bits por canal (DAC de resistencias de la DE10-Lite).
--
-- Contenido:
--   Banda superior (y < 70): color segun el estado, con el codigo
--     de estado y el ultimo evento como digitos de 7 segmentos.
--   4 barras horizontales: distancia de frente, diagonal izq,
--     diagonal der y atras (1 pixel por cm). Verde = libre,
--     rojo = obstaculo, gris = sin eco.
--   Cruz de LDR: frente arriba, izquierda, derecha y atras abajo;
--     amarillo = luz. El cuadro del frente lleva marco blanco con
--     luz cerca.
--   2 barras verticales: duty izquierdo y derecho (azul adelante,
--     magenta reversa).
--   Cuadro rojo cuando el robot esta en ESCAPE (atasco).
-- Sincronias negativas (modo 640 x 480).
-- Dos etapas registradas: A calcula que zona toca cada pixel y B
-- elige el color; las sincronias pasan por las mismas dos etapas,
-- asi que color y sincronias quedan alineados.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity vga_debug is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;   -- sincrono, activo en alto
        estado : in  std_logic_vector(2 downto 0);
        evento : in  std_logic_vector(2 downto 0);
        luz    : in  std_logic_vector(3 downto 0);
        cerca  : in  std_logic;
        obs    : in  std_logic_vector(3 downto 0);
        dist   : in  std_logic_vector(35 downto 0);
        duty_l : in  std_logic_vector(7 downto 0);
        duty_r : in  std_logic_vector(7 downto 0);
        dir_l  : in  std_logic;
        dir_r  : in  std_logic;
        vga_r  : out std_logic_vector(3 downto 0);
        vga_g  : out std_logic_vector(3 downto 0);
        vga_b  : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic
    );
end entity vga_debug;

architecture rtl of vga_debug is
    -- Tiempos de 640 x 480 @ 60 Hz (en pixeles y lineas)
    constant H_VIS : natural := 640;
    constant H_FP  : natural := 16;
    constant H_SY  : natural := 96;
    constant H_TOT : natural := 800;
    constant V_VIS : natural := 480;
    constant V_FP  : natural := 10;
    constant V_SY  : natural := 2;
    constant V_TOT : natural := 525;

    signal pix_en : std_logic := '0';
    signal hc     : natural range 0 to H_TOT - 1 := 0;
    signal vc     : natural range 0 to V_TOT - 1 := 0;

    subtype t_rgb is std_logic_vector(11 downto 0);
    constant NEGRO    : t_rgb := x"000";
    constant BLANCO   : t_rgb := x"FFF";
    constant GRIS     : t_rgb := x"444";
    constant VERDE    : t_rgb := x"0C0";
    constant ROJO     : t_rgb := x"F00";
    constant AMARILLO : t_rgb := x"FD0";
    constant AZUL     : t_rgb := x"25F";
    constant MAGENTA  : t_rgb := x"C0C";

    function color_estado (e : std_logic_vector(2 downto 0)) return t_rgb is
    begin
        case e is
            when E_INICIO  => return x"333";
            when E_BUSCAR  => return x"036";
            when E_SEGUIR  => return x"060";
            when E_ESQUIVA => return x"660";
            when E_ESQUINA => return x"630";
            when E_ESCAPE  => return x"600";
            when E_META    => return x"0AA";
            when others    => return x"000";
        end case;
    end function;

    -- Digito de 7 segmentos en una celda de 36 x 60, trazo de 6
    function segmento (dig : std_logic_vector(2 downto 0); x, y : natural) return boolean is
        variable p : std_logic_vector(6 downto 0);   -- gfedcba
    begin
        case dig is
            when "000"  => p := "0111111";
            when "001"  => p := "0000110";
            when "010"  => p := "1011011";
            when "011"  => p := "1001111";
            when "100"  => p := "1100110";
            when "101"  => p := "1101101";
            when "110"  => p := "1111101";
            when others => p := "0000111";
        end case;
        return (p(0) = '1' and y < 6 and x >= 6 and x < 30) or
               (p(1) = '1' and x >= 30 and y >= 6 and y < 30) or
               (p(2) = '1' and x >= 30 and y >= 30 and y < 54) or
               (p(3) = '1' and y >= 54 and x >= 6 and x < 30) or
               (p(4) = '1' and x < 6 and y >= 30 and y < 54) or
               (p(5) = '1' and x < 6 and y >= 6 and y < 30) or
               (p(6) = '1' and y >= 27 and y < 33 and x >= 6 and x < 30);
    end function;

    function d (v : std_logic_vector(35 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(9 * i + 8 downto 9 * i)));
    end function;

    function dentro (x, y, x0, y0, x1, y1 : natural) return boolean is
    begin
        return x >= x0 and x < x1 and y >= y0 and y < y1;
    end function;
    -- Etapa A: banderas de cada zona para el pixel (hc, vc)
    signal a_vis, a_banda, a_digito    : std_logic := '0';
    signal a_marca, a_barra            : std_logic_vector(3 downto 0) := (others => '0');
    signal a_gris, a_rojo              : std_logic_vector(3 downto 0) := (others => '0');
    signal a_marco, a_ldr_f, a_ldr_i   : std_logic := '0';
    signal a_ldr_d, a_ldr_t            : std_logic := '0';
    signal a_luz                       : std_logic_vector(3 downto 0) := (others => '0');
    signal a_dl, a_dr, a_dir_l, a_dir_r : std_logic := '0';
    signal a_base, a_atasco            : std_logic := '0';
    signal a_color                     : t_rgb := (others => '0');
    signal a_hs, a_vs                  : std_logic := '1';

    -- Etapa B: color final y sincronias
    signal r, g, b : std_logic_vector(3 downto 0) := (others => '0');
    signal hs, vs  : std_logic := '1';

    function bit_de (c : boolean) return std_logic is
    begin
        if c then
            return '1';
        else
            return '0';
        end if;
    end function;
begin

    -- Contadores de pixel y linea (avanzan cada 2 ciclos)
    process (clk)
    begin
        if rising_edge(clk) then
            pix_en <= not pix_en;
            if rst = '1' then
                hc <= 0;
                vc <= 0;
            elsif pix_en = '1' then
                if hc = H_TOT - 1 then
                    hc <= 0;
                    if vc = V_TOT - 1 then
                        vc <= 0;
                    else
                        vc <= vc + 1;
                    end if;
                else
                    hc <= hc + 1;
                end if;
            end if;
        end if;
    end process;

    -- Etapa A: que zona del tablero toca el pixel actual. Va en un
    -- registro aparte del color para que comparaciones y prioridades
    -- no queden en el mismo ciclo de 20 ns.
    process (clk)
        variable x, y : natural range 0 to 1023;
        variable y0   : natural range 0 to 1023;
        variable alto : natural range 0 to 255;
    begin
        if rising_edge(clk) then
            x := hc;
            y := vc;
            a_vis <= bit_de(hc < H_VIS and vc < V_VIS);
            a_hs  <= bit_de(not (hc >= H_VIS + H_FP and hc < H_VIS + H_FP + H_SY));
            a_vs  <= bit_de(not (vc >= V_VIS + V_FP and vc < V_VIS + V_FP + V_SY));

            a_banda  <= bit_de(y < 70);
            a_digito <= bit_de((dentro(x, y, 20, 5, 56, 65) and segmento(estado, x - 20, y - 5)) or
                               (dentro(x, y, 80, 5, 116, 65) and segmento(evento, x - 80, y - 5)));
            a_color  <= color_estado(estado);

            for i in 0 to 3 loop
                y0 := 90 + 50 * i;
                a_marca(i) <= bit_de(y >= y0 and y < y0 + 30 and x >= 20 and x < 50);
                a_barra(i) <= bit_de(y >= y0 and y < y0 + 30 and x >= 60 and x < 60 + d(dist, i));
                a_gris(i)  <= bit_de(d(dist, i) = DIST_SIN_ECO);
                a_rojo(i)  <= obs(i);
            end loop;

            a_marco <= bit_de(dentro(x, y, 156, 296, 204, 344) and cerca = '1');
            a_ldr_f <= bit_de(dentro(x, y, 160, 300, 200, 340));
            a_ldr_i <= bit_de(dentro(x, y, 110, 350, 150, 390));
            a_ldr_d <= bit_de(dentro(x, y, 210, 350, 250, 390));
            a_ldr_t <= bit_de(dentro(x, y, 160, 400, 200, 440));
            a_luz   <= luz;

            alto := to_integer(unsigned(duty_l));
            a_dl <= bit_de(x >= 400 and x < 440 and y < 460 and y >= 460 - alto);
            alto := to_integer(unsigned(duty_r));
            a_dr <= bit_de(x >= 480 and x < 520 and y < 460 and y >= 460 - alto);
            a_dir_l <= dir_l;
            a_dir_r <= dir_r;
            a_base  <= bit_de(dentro(x, y, 390, 460, 530, 462));
            a_atasco <= bit_de(dentro(x, y, 560, 300, 620, 360) and estado = E_ESCAPE);
        end if;
    end process;

    -- Etapa B: color por prioridad (lo ultimo que se asigna gana)
    process (clk)
        variable c : t_rgb;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                hs <= '1';
                vs <= '1';
                r  <= (others => '0');
                g  <= (others => '0');
                b  <= (others => '0');
            else
                hs <= a_hs;
                vs <= a_vs;
                c  := NEGRO;
                if a_vis = '1' then
                    if a_banda = '1' then
                        c := a_color;
                        if a_digito = '1' then
                            c := BLANCO;
                        end if;
                    end if;

                    for i in 0 to 3 loop
                        if a_marca(i) = '1' then
                            c := GRIS;                    -- marca del sensor
                        elsif a_barra(i) = '1' then
                            if a_gris(i) = '1' then
                                c := GRIS;
                            elsif a_rojo(i) = '1' then
                                c := ROJO;
                            else
                                c := VERDE;
                            end if;
                        end if;
                    end loop;

                    if a_marco = '1' then
                        c := BLANCO;                      -- marco de luz cerca
                    end if;
                    if a_ldr_f = '1' then
                        if a_luz(L_FRENTE) = '1' then c := AMARILLO; else c := GRIS; end if;
                    elsif a_ldr_i = '1' then
                        if a_luz(L_IZQ) = '1' then c := AMARILLO; else c := GRIS; end if;
                    elsif a_ldr_d = '1' then
                        if a_luz(L_DER) = '1' then c := AMARILLO; else c := GRIS; end if;
                    elsif a_ldr_t = '1' then
                        if a_luz(L_ATRAS) = '1' then c := AMARILLO; else c := GRIS; end if;
                    end if;

                    if a_dl = '1' then
                        if a_dir_l = '1' then c := AZUL; else c := MAGENTA; end if;
                    end if;
                    if a_dr = '1' then
                        if a_dir_r = '1' then c := AZUL; else c := MAGENTA; end if;
                    end if;
                    if a_base = '1' then
                        c := GRIS;
                    end if;
                    if a_atasco = '1' then
                        c := ROJO;
                    end if;
                end if;
                r <= c(11 downto 8);
                g <= c(7 downto 4);
                b <= c(3 downto 0);
            end if;
        end if;
    end process;

    vga_r  <= r;
    vga_g  <= g;
    vga_b  <= b;
    vga_hs <= hs;
    vga_vs <= vs;

end architecture rtl;
