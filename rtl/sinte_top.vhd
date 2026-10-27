-- ============================================================
-- sinte_top.vhd
-- Sintetizador musical digital sobre la DE10-Lite (MAX 10).
-- ARCHIVO GENERADO por tools/genera_top.py junto con
-- quartus/sintetizador.bdf (el mismo circuito como diagrama de
-- bloques). Para cambiar conexiones, editar el script.
--
--   teclados -> interfaz_teclados -> teclas_notas --+-> secuenciador
--                                                   v       |
--                   selector_notas (vivo o grabado) <-------+
--                                |
--                          gestor_voces -> voz 0, voz 1, voz 2
--                                               |
--   audio_salida: mezcla -> efectos -> volumen -> + metronomo -> PWM
--
--   control: modos (SW9-SW8), teclas de funcion, KEY0 y KEY1,
--   parametros y ordenes al secuenciador
--   display_hex, vga_ui y leds_estado: interfaz de usuario
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity sinte_top is
    port (
        MAX10_CLK1_50 : in  std_logic;
        KEY           : in  std_logic_vector(1 downto 0);
        SW            : in  std_logic_vector(9 downto 0);
        TEC1_COL      : in  std_logic_vector(3 downto 0);
        TEC2_COL      : in  std_logic_vector(3 downto 0);
        LEDR          : out std_logic_vector(9 downto 0);
        HEX0          : out std_logic_vector(7 downto 0);
        HEX1          : out std_logic_vector(7 downto 0);
        HEX2          : out std_logic_vector(7 downto 0);
        HEX3          : out std_logic_vector(7 downto 0);
        HEX4          : out std_logic_vector(7 downto 0);
        HEX5          : out std_logic_vector(7 downto 0);
        TEC1_FIL      : out std_logic_vector(3 downto 0);
        TEC2_FIL      : out std_logic_vector(3 downto 0);
        AUDIO_PWM     : out std_logic;
        VGA_R         : out std_logic_vector(3 downto 0);
        VGA_G         : out std_logic_vector(3 downto 0);
        VGA_B         : out std_logic_vector(3 downto 0);
        VGA_HS        : out std_logic;
        VGA_VS        : out std_logic
    );
end entity sinte_top;

architecture estructural of sinte_top is
    signal rst            : std_logic;
    signal tick_fs        : std_logic;
    signal tick_1ms       : std_logic;
    signal accion         : std_logic;
    signal metro_btn      : std_logic;
    signal modo           : std_logic_vector(1 downto 0);
    signal teclas         : std_logic_vector(31 downto 0);
    signal vivo           : std_logic_vector(20 downto 0);
    signal func           : std_logic_vector(7 downto 0);
    signal ultima         : std_logic_vector(6 downto 0);
    signal forma          : std_logic_vector(1 downto 0);
    signal atk            : std_logic_vector(1 downto 0);
    signal dec            : std_logic_vector(1 downto 0);
    signal sus            : std_logic_vector(1 downto 0);
    signal rel            : std_logic_vector(1 downto 0);
    signal volumen        : std_logic_vector(2 downto 0);
    signal tempo          : std_logic_vector(1 downto 0);
    signal efecto         : std_logic_vector(1 downto 0);
    signal metro_on       : std_logic;
    signal metro_suena    : std_logic;
    signal octava         : std_logic_vector(2 downto 0);
    signal parametro      : std_logic_vector(2 downto 0);
    signal cmd_grabar     : std_logic;
    signal cmd_reproducir : std_logic;
    signal cmd_parar      : std_logic;
    signal grabado        : std_logic_vector(20 downto 0);
    signal estado_sec     : std_logic_vector(1 downto 0);
    signal eventos        : std_logic_vector(8 downto 0);
    signal posicion       : std_logic_vector(8 downto 0);
    signal llena          : std_logic;
    signal pedidas        : std_logic_vector(20 downto 0);
    signal notas_v        : std_logic_vector(20 downto 0);
    signal gates          : std_logic_vector(2 downto 0);
    signal activas        : std_logic_vector(2 downto 0);
    signal muestras       : std_logic_vector(23 downto 0);
    signal niveles        : std_logic_vector(23 downto 0);
    signal beat           : std_logic;
    signal acento         : std_logic;
    signal clip           : std_logic;
begin

    u_rst : entity work.reset_encendido
        port map (
            clk => MAX10_CLK1_50,
            rst => rst
        );

    u_tiempo : entity work.base_tiempo
        port map (
            clk      => MAX10_CLK1_50,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms
        );

    u_placa : entity work.entradas_placa
        port map (
            clk       => MAX10_CLK1_50,
            rst       => rst,
            tick_1ms  => tick_1ms,
            key       => KEY,
            sw        => SW,
            accion    => accion,
            metro_btn => metro_btn,
            modo      => modo
        );

    u_teclados : entity work.interfaz_teclados
        port map (
            clk      => MAX10_CLK1_50,
            rst      => rst,
            tick_1ms => tick_1ms,
            tec1_col => TEC1_COL,
            tec2_col => TEC2_COL,
            tec1_fil => TEC1_FIL,
            tec2_fil => TEC2_FIL,
            teclas   => teclas
        );

    u_notas : entity work.teclas_notas
        port map (
            clk    => MAX10_CLK1_50,
            rst    => rst,
            teclas => teclas,
            octava => octava,
            notas  => vivo,
            func   => func,
            ultima => ultima
        );

    u_control : entity work.control
        port map (
            clk            => MAX10_CLK1_50,
            rst            => rst,
            modo           => modo,
            func           => func,
            accion         => accion,
            metro_btn      => metro_btn,
            estado_sec     => estado_sec,
            forma          => forma,
            atk            => atk,
            dec            => dec,
            sus            => sus,
            rel            => rel,
            volumen        => volumen,
            tempo          => tempo,
            efecto         => efecto,
            metro_on       => metro_on,
            metro_suena    => metro_suena,
            octava         => octava,
            parametro      => parametro,
            cmd_grabar     => cmd_grabar,
            cmd_reproducir => cmd_reproducir,
            cmd_parar      => cmd_parar
        );

    u_sec : entity work.secuenciador
        port map (
            clk            => MAX10_CLK1_50,
            rst            => rst,
            tick_1ms       => tick_1ms,
            cmd_grabar     => cmd_grabar,
            cmd_reproducir => cmd_reproducir,
            cmd_parar      => cmd_parar,
            conjunto       => vivo,
            salida         => grabado,
            estado         => estado_sec,
            eventos        => eventos,
            posicion       => posicion,
            llena          => llena
        );

    u_sel : entity work.selector_notas
        port map (
            estado_sec => estado_sec,
            vivo       => vivo,
            grabado    => grabado,
            pedidas    => pedidas
        );

    u_gestor : entity work.gestor_voces
        port map (
            clk      => MAX10_CLK1_50,
            rst      => rst,
            conjunto => pedidas,
            activas  => activas,
            notas_v  => notas_v,
            gates    => gates
        );

    u_voz0 : entity work.voz
        port map (
            clk     => MAX10_CLK1_50,
            rst     => rst,
            tick_fs => tick_fs,
            nota    => notas_v(6 downto 0),
            gate    => gates(0),
            forma   => forma,
            atk     => atk,
            dec     => dec,
            sus     => sus,
            rel     => rel,
            muestra => muestras(7 downto 0),
            nivel   => niveles(7 downto 0),
            activa  => activas(0)
        );

    u_voz1 : entity work.voz
        port map (
            clk     => MAX10_CLK1_50,
            rst     => rst,
            tick_fs => tick_fs,
            nota    => notas_v(13 downto 7),
            gate    => gates(1),
            forma   => forma,
            atk     => atk,
            dec     => dec,
            sus     => sus,
            rel     => rel,
            muestra => muestras(15 downto 8),
            nivel   => niveles(15 downto 8),
            activa  => activas(1)
        );

    u_voz2 : entity work.voz
        port map (
            clk     => MAX10_CLK1_50,
            rst     => rst,
            tick_fs => tick_fs,
            nota    => notas_v(20 downto 14),
            gate    => gates(2),
            forma   => forma,
            atk     => atk,
            dec     => dec,
            sus     => sus,
            rel     => rel,
            muestra => muestras(23 downto 16),
            nivel   => niveles(23 downto 16),
            activa  => activas(2)
        );

    u_audio : entity work.audio_salida
        port map (
            clk      => MAX10_CLK1_50,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms,
            voz0     => muestras(7 downto 0),
            voz1     => muestras(15 downto 8),
            voz2     => muestras(23 downto 16),
            volumen  => volumen,
            efecto   => efecto,
            metro_on => metro_suena,
            tempo    => tempo,
            pwm      => AUDIO_PWM,
            beat     => beat,
            acento   => acento,
            clip     => clip,
            nivel    => open
        );

    u_hex : entity work.display_hex
        port map (
            clk       => MAX10_CLK1_50,
            modo      => modo,
            parametro => parametro,
            forma     => forma,
            atk       => atk,
            dec       => dec,
            sus       => sus,
            rel       => rel,
            volumen   => volumen,
            tempo     => tempo,
            efecto    => efecto,
            octava    => octava,
            ultima    => ultima,
            posicion  => posicion,
            hex0      => HEX0,
            hex1      => HEX1,
            hex2      => HEX2,
            hex3      => HEX3,
            hex4      => HEX4,
            hex5      => HEX5
        );

    u_vga : entity work.vga_ui
        port map (
            clk        => MAX10_CLK1_50,
            rst        => rst,
            modo       => modo,
            estado_sec => estado_sec,
            forma      => forma,
            atk        => atk,
            dec        => dec,
            sus        => sus,
            rel        => rel,
            volumen    => volumen,
            tempo      => tempo,
            efecto     => efecto,
            metro_on   => metro_on,
            beat       => beat,
            acento     => acento,
            octava     => octava,
            notas      => notas_v,
            gates      => gates,
            niveles    => niveles,
            parametro  => parametro,
            eventos    => eventos,
            posicion   => posicion,
            vga_r      => VGA_R,
            vga_g      => VGA_G,
            vga_b      => VGA_B,
            vga_hs     => VGA_HS,
            vga_vs     => VGA_VS
        );

    u_leds : entity work.leds_estado
        port map (
            clk        => MAX10_CLK1_50,
            rst        => rst,
            tick_1ms   => tick_1ms,
            activas    => activas,
            metro_on   => metro_on,
            beat       => beat,
            estado_sec => estado_sec,
            llena      => llena,
            efecto     => efecto,
            clip       => clip,
            ledr       => LEDR
        );

end architecture estructural;
