-- ============================================================
-- captura_vga.vhd
-- Banco auxiliar (no es testbench de correr.sh): simula vga_ui en
-- los cuatro modos y guarda un cuadro de cada uno como imagen PPM
-- (vga_modo0.ppm ... vga_modo3.ppm, en la carpeta donde se corre).
-- Sirve para ver la pantalla sin la tarjeta. Desde una carpeta
-- vacia, con R = carpeta del repositorio (tarda unos 20 s):
--   ghdl -i $R/rtl/synth_pkg.vhd $R/rtl/fuente_5x7.vhd \
--        $R/rtl/vga_ui.vhd $R/sim/captura_vga.vhd
--   ghdl -m captura_vga
--   ghdl -r captura_vga
-- y despues, por ejemplo: convert vga_modo0.ppm vga_modo0.png
--
-- El cuadro se arma como lo veria un monitor: tras el flanco de
-- subida de VSYNC (linea 492) se cuentan 33 bajadas de HSYNC y la
-- linea 0 empieza 144 pixeles despues de la ultima; cada pixel se
-- lee a la mitad de su tiempo (40 ns).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.synth_pkg.all;

entity captura_vga is
end entity captura_vga;

architecture sim of captura_vga is
    constant T_CLK : time := 20 ns;
    constant T_PIX : time := 2 * T_CLK;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal modo       : std_logic_vector(1 downto 0) := M_INT;
    signal estado_sec : std_logic_vector(1 downto 0) := S_ESPERA;
    signal forma      : std_logic_vector(1 downto 0) := W_SENO;
    signal atk        : std_logic_vector(1 downto 0) := "01";
    signal dec        : std_logic_vector(1 downto 0) := "01";
    signal sus        : std_logic_vector(1 downto 0) := "10";
    signal rel        : std_logic_vector(1 downto 0) := "01";
    signal volumen    : std_logic_vector(2 downto 0) := "011";
    signal tempo      : std_logic_vector(1 downto 0) := "10";
    signal efecto     : std_logic_vector(1 downto 0) := E_TREMOLO;
    signal metro_on   : std_logic := '1';
    signal beat       : std_logic := '0';
    signal acento     : std_logic := '0';
    signal octava     : std_logic_vector(2 downto 0) := "100";
    signal notas      : std_logic_vector(20 downto 0) := (others => '0');
    signal gates      : std_logic_vector(2 downto 0) := "000";
    signal niveles    : std_logic_vector(23 downto 0) := (others => '0');
    signal parametro  : std_logic_vector(2 downto 0) := "000";
    signal eventos    : std_logic_vector(8 downto 0) := (others => '0');
    signal posicion   : std_logic_vector(8 downto 0) := (others => '0');
    signal vga_r, vga_g, vga_b : std_logic_vector(3 downto 0);
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
begin

    clk <= not clk after T_CLK / 2 when not fin else '0';

    dut : entity work.vga_ui
        generic map (DESTELLO => 400_000, PARPADEO => 0)
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
        type t_linea  is array (0 to 639) of std_logic_vector(11 downto 0);
        type t_cuadro is array (0 to 479) of t_linea;
        variable cuadro : t_cuadro;

        -- arma un cuadro completo a partir de las sincronias; se llama
        -- justo despues del flanco de subida de VSYNC
        procedure capturar is
        begin
            for i in 1 to 33 loop
                wait until falling_edge(vga_hs);
            end loop;
            for yy in 0 to 479 loop
                if yy > 0 then
                    wait until falling_edge(vga_hs);
                end if;
                wait for 144 * T_PIX + T_PIX / 2;
                for xx in 0 to 639 loop
                    cuadro(yy)(xx) := vga_r & vga_g & vga_b;
                    if xx < 639 then
                        wait for T_PIX;
                    end if;
                end loop;
            end loop;
        end procedure;

        -- un pixel por renglon del archivo (renglones cortos)
        procedure escribir_ppm (nombre : string) is
            file f    : text open write_mode is nombre;
            variable ln : line;
            variable v  : std_logic_vector(11 downto 0);
        begin
            write(ln, string'("P3"));
            writeline(f, ln);
            write(ln, string'("640 480"));
            writeline(f, ln);
            write(ln, string'("255"));
            writeline(f, ln);
            for yy in 0 to 479 loop
                for xx in 0 to 639 loop
                    v := cuadro(yy)(xx);
                    write(ln, to_integer(unsigned(v(11 downto 8))) * 17);
                    write(ln, ' ');
                    write(ln, to_integer(unsigned(v(7 downto 4))) * 17);
                    write(ln, ' ');
                    write(ln, to_integer(unsigned(v(3 downto 0))) * 17);
                    writeline(f, ln);
                end loop;
            end loop;
            file_close(f);
        end procedure;

        -- un tiempo del metronomo al empezar el cuadro
        procedure tiempo (ac : std_logic) is
        begin
            wait until rising_edge(clk);
            beat   <= '1';
            acento <= ac;
            wait until rising_edge(clk);
            beat   <= '0';
            acento <= '0';
        end procedure;
    begin
        wait for 10 * T_CLK;
        wait until rising_edge(clk);
        rst <= '0';

        -- 0: INTERPRETACION, acorde C4 E4 G4, onda seno, tiempo normal
        modo <= M_INT;
        estado_sec <= S_ESPERA;
        forma <= W_SENO;
        notas <= n7(55) & n7(52) & n7(48);
        gates <= "111";
        niveles <= n8(120) & n8(180) & n8(230);
        eventos <= n9(37);
        posicion <= n9(37);
        wait until rising_edge(vga_vs);
        tiempo('0');
        capturar;
        escribir_ppm("vga_modo0.ppm");
        report "captura: modo 0 listo";

        -- 1: GRABACION, dos notas, cuadrada, tiempo con acento y punto rojo
        modo <= M_GRA;
        estado_sec <= S_GRABANDO;
        forma <= W_CUADRADA;
        notas <= n7(0) & n7(64) & n7(61);
        gates <= "011";
        niveles <= n8(0) & n8(150) & n8(250);
        eventos <= n9(12);
        posicion <= n9(12);
        for i in 1 to 3 loop
            wait until rising_edge(vga_vs);
            tiempo('1');
            capturar;
            exit when cuadro(407)(353) = x"F11";
        end loop;
        escribir_ppm("vga_modo1.ppm");
        report "captura: modo 1 listo";

        -- 2: REPRODUCCION, acorde A4 C5 E5, sierra, metronomo apagado
        modo <= M_REP;
        estado_sec <= S_REPRODUCE;
        forma <= W_SIERRA;
        metro_on <= '0';
        notas <= n7(64) & n7(60) & n7(57);
        gates <= "111";
        niveles <= n8(90) & n8(160) & n8(210);
        eventos <= n9(37);
        posicion <= n9(15);
        wait until rising_edge(vga_vs);
        capturar;
        escribir_ppm("vga_modo2.ppm");
        report "captura: modo 2 listo";

        -- 3: CONFIGURACION, SUSTAIN elegido, triangular, sin notas
        modo <= M_CONF;
        estado_sec <= S_ESPERA;
        forma <= W_TRIANGULAR;
        metro_on <= '1';
        parametro <= "011";
        sus <= "11";
        volumen <= "100";
        efecto <= E_AMBOS;
        notas <= (others => '0');
        gates <= "000";
        niveles <= (others => '0');
        eventos <= n9(37);
        posicion <= n9(37);
        wait until rising_edge(vga_vs);
        capturar;
        escribir_ppm("vga_modo3.ppm");
        report "captura: modo 3 listo";

        fin <= true;
        wait;
    end process;

end architecture sim;
