-- ============================================================
-- tb_vga_debug.vhd
-- Reloj de 50 MHz (2 ciclos por pixel). Verifica las sincronias
-- de 640 x 480 @ 60 Hz:
--   linea de 800 pixeles (1600 ciclos), HSYNC de 96 pixeles,
--   cuadro de 525 lineas, VSYNC de 2 lineas,
-- y muestrea pixeles en zonas conocidas: banda superior con el
-- color del estado, barra de distancia verde, fondo negro y
-- negro fuera del area visible.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity tb_vga_debug is
end entity tb_vga_debug;

architecture sim of tb_vga_debug is
    constant T_CLK : time := 20 ns;
    constant T_PIX : time := 2 * T_CLK;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal dist  : std_logic_vector(35 downto 0);
    signal r, g, b : std_logic_vector(3 downto 0);
    signal hs, vs  : std_logic;
    signal fin   : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    -- frente a 100 cm (barra verde), demas sin eco
    dist <= "111111111" & "111111111" & "111111111" & std_logic_vector(to_unsigned(100, 9));

    dut : entity work.vga_debug
        port map (clk => clk, rst => rst, estado => E_SEGUIR, evento => EV_LUZ,
                  luz => "0001", cerca => '0', obs => "0000", dist => dist,
                  duty_l => x"80", duty_r => x"80", dir_l => '1', dir_r => '1',
                  vga_r => r, vga_g => g, vga_b => b, vga_hs => hs, vga_vs => vs);

    estimulo : process
        variable t_h1, t_h2, t_v1, t_v2 : time;
        variable rgb : std_logic_vector(11 downto 0);

        -- Color del pixel (x, y) del cuadro que empieza al subir VSYNC.
        -- La subida de HSYNC ocurre en el pixel 752 de cada linea;
        -- la subida de VSYNC, al empezar la linea 492.
        procedure pixel (x, y : natural; variable c : out std_logic_vector(11 downto 0)) is
            variable lineas : natural;
        begin
            wait until rising_edge(vs);
            -- lineas 492..524 y luego 0..y-1 terminan antes de la linea y
            lineas := (525 - 492) + y;
            for k in 1 to lineas loop
                wait until rising_edge(hs);
            end loop;
            -- de la subida de HSYNC (pixel 752 de la linea anterior) al pixel x
            wait for (800 - 752 + x) * T_PIX + T_PIX / 2;
            c := r & g & b;
        end procedure;
    begin
        wait for 5 * T_CLK;
        rst <= '0';

        -- Sincronia horizontal
        wait until falling_edge(hs);
        t_h1 := now;
        wait until rising_edge(hs);
        assert now - t_h1 = 96 * T_PIX
            report "HSYNC dura " & time'image(now - t_h1) severity error;
        wait until falling_edge(hs);
        t_h2 := now;
        assert t_h2 - t_h1 = 800 * T_PIX
            report "Linea dura " & time'image(t_h2 - t_h1) severity error;

        -- Sincronia vertical
        wait until falling_edge(vs);
        t_v1 := now;
        wait until rising_edge(vs);
        assert now - t_v1 = 2 * 800 * T_PIX
            report "VSYNC dura " & time'image(now - t_v1) severity error;
        wait until falling_edge(vs);
        t_v2 := now;
        assert t_v2 - t_v1 = 525 * 800 * T_PIX
            report "Cuadro dura " & time'image(t_v2 - t_v1) severity error;

        -- Pixeles
        pixel(300, 30, rgb);
        assert rgb = x"060" report "Banda de SEGUIR: color incorrecto" severity error;
        pixel(100, 100, rgb);
        assert rgb = x"0C0" report "Barra del frente (100 cm) deberia ser verde" severity error;
        pixel(200, 100, rgb);
        assert rgb = x"000" report "Fondo despues de la barra deberia ser negro" severity error;
        pixel(180, 320, rgb);
        assert rgb = x"FD0" report "LDR del frente deberia verse amarilla" severity error;
        pixel(645, 100, rgb);
        assert rgb = x"000" report "Fuera del area visible debe ser negro" severity error;

        report "tb_vga_debug: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
