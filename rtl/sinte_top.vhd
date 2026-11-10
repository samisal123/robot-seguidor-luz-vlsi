-- ============================================================
-- sinte_top.vhd
-- Sintetizador musical digital sobre la tarjeta EP2C5T144
-- (Cyclone II). Reloj de 50 MHz -> PLL -> 25 MHz.
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
--   control: modo, teclas de funcion (MODO, ACCION, METRONOMO y
--   VOLUMEN en el teclado 2), parametros y ordenes al secuenciador
--   leds_estado: modo y estado en los 3 LEDs de la tarjeta
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity sinte_top is
    port (
        CLOCK_50      : in  std_logic;                    -- oscilador de 50 MHz de la tarjeta (pin 17)
        BTN_RESET     : in  std_logic;                    -- boton RESET de la tarjeta, 0 = presionado (pin 144)
        TEC1_COL      : in  std_logic_vector(3 downto 0); -- columnas del teclado 1, 0 = tecla (pull-up)
        TEC2_COL      : in  std_logic_vector(3 downto 0); -- columnas del teclado 2
        LED           : out std_logic_vector(2 downto 0); -- LEDs D5, D4, D2 de la tarjeta (2..0), activos en bajo
        TEC1_FIL      : out std_logic_vector(3 downto 0); -- filas del teclado 1 (0 o alta impedancia)
        TEC2_FIL      : out std_logic_vector(3 downto 0); -- filas del teclado 2
        AUDIO_PWM     : out std_logic                     -- PWM de audio de 97.7 kHz (pin 93)
    );
end entity sinte_top;

architecture estructural of sinte_top is
    signal clk            : std_logic;
    signal pll_listo      : std_logic;
    signal rst            : std_logic;
    signal tick_fs        : std_logic;
    signal tick_1ms       : std_logic;
    signal modo           : std_logic_vector(1 downto 0);
    signal teclas         : std_logic_vector(31 downto 0);
    signal vivo           : std_logic_vector(20 downto 0);
    signal func           : std_logic_vector(7 downto 0);
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
    signal pedidas        : std_logic_vector(20 downto 0);
    signal notas_v        : std_logic_vector(20 downto 0);
    signal gates          : std_logic_vector(2 downto 0);
    signal activas        : std_logic_vector(2 downto 0);
    signal muestras       : std_logic_vector(23 downto 0);
    signal beat           : std_logic;
begin

    u_pll : entity work.pll_25mhz
        port map (
            inclk0 => CLOCK_50,
            c0     => clk,
            locked => pll_listo
        );

    u_rst : entity work.reset_encendido
        port map (
            clk     => clk,
            listo   => pll_listo,
            boton_n => BTN_RESET,
            rst     => rst
        );

    u_tiempo : entity work.base_tiempo
        port map (
            clk      => clk,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms
        );

    u_teclados : entity work.interfaz_teclados
        port map (
            clk      => clk,
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
            clk    => clk,
            rst    => rst,
            teclas => teclas,
            octava => octava,
            notas  => vivo,
            func   => func
        );

    u_control : entity work.control
        port map (
            clk            => clk,
            rst            => rst,
            func           => func,
            estado_sec     => estado_sec,
            modo           => modo,
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
            clk            => clk,
            rst            => rst,
            tick_1ms       => tick_1ms,
            cmd_grabar     => cmd_grabar,
            cmd_reproducir => cmd_reproducir,
            cmd_parar      => cmd_parar,
            conjunto       => vivo,
            salida         => grabado,
            estado         => estado_sec,
            eventos        => open,
            posicion       => open,
            llena          => open
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
            clk      => clk,
            rst      => rst,
            conjunto => pedidas,
            activas  => activas,
            notas_v  => notas_v,
            gates    => gates
        );

    u_voz0 : entity work.voz
        port map (
            clk     => clk,
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
            nivel   => open,
            activa  => activas(0)
        );

    u_voz1 : entity work.voz
        port map (
            clk     => clk,
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
            nivel   => open,
            activa  => activas(1)
        );

    u_voz2 : entity work.voz
        port map (
            clk     => clk,
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
            nivel   => open,
            activa  => activas(2)
        );

    u_audio : entity work.audio_salida
        port map (
            clk      => clk,
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
            acento   => open,
            clip     => open,
            nivel    => open
        );

    u_leds : entity work.leds_estado
        port map (
            clk        => clk,
            rst        => rst,
            tick_1ms   => tick_1ms,
            metro_on   => metro_on,
            beat       => beat,
            modo       => modo,
            estado_sec => estado_sec,
            parametro  => parametro,
            led_n      => LED
        );

end architecture estructural;
