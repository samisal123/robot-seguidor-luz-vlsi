-- ============================================================
-- robot_top.vhd
-- Top del robot seguidor de luz para la DE10-Lite (MAX 10).
-- Un solo reloj de 50 MHz; todo lo lento usa los pulsos de
-- tick_gen. Toda entrada externa pasa por sync_2ff.
--
-- Botones y switches (todos con debounce):
--   KEY0  arranca / detiene el recorrido
--   KEY1  reset
--   SW0-1 sensor que se muestra con SW9 (0 frente, 1 diag izq,
--         2 diag der, 3 atras)
--   SW2   control PI de velocidad con encoders (extra)
--   SW7   prueba de motores: ambas ruedas adelante a V_AVANCE
--   SW8   motores habilitados (STBY del TB6612FNG); en '0' el
--         robot piensa pero no se mueve, sirve para el banco
--   SW9   displays en modo distancia
-- LEDs: LEDR0-3 LDR frente, izq, der, atras; LEDR4-7 obstaculo
--   frente, diag izq, diag der, atras; LEDR8 ESCAPE (atasco);
--   LEDR9 latido de 1 Hz. En META parpadean todos.
-- Displays: HEX5 estado, HEX4 ultimo evento, HEX3-2 y HEX1-0
--   % de duty izq y der (o distancia con SW9).
-- UART_TX: bitacora a 115200 8N1 (ver telemetria.vhd).
-- VGA: tablero de depuracion (ver vga_debug.vhd).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity robot_top is
    generic (
        CLK_HZ   : positive := 50_000_000;
        BAUD     : positive := 115_200;
        DEB_MS   : positive := 20;      -- antirrebote de KEY y SW
        TURNO_MS : positive := 30;      -- turno de cada HC-SR04
        V_AVANCE : natural  := 170;
        VMAX_ENC : positive := 64;      -- transiciones por ventana a duty 255
        UN_CANAL : boolean  := true     -- encoders de ranura (solo canal A)
    );
    port (
        MAX10_CLK1_50 : in  std_logic;
        KEY           : in  std_logic_vector(1 downto 0);
        SW            : in  std_logic_vector(9 downto 0);
        LEDR          : out std_logic_vector(9 downto 0);
        HEX0          : out std_logic_vector(7 downto 0);
        HEX1          : out std_logic_vector(7 downto 0);
        HEX2          : out std_logic_vector(7 downto 0);
        HEX3          : out std_logic_vector(7 downto 0);
        HEX4          : out std_logic_vector(7 downto 0);
        HEX5          : out std_logic_vector(7 downto 0);
        -- Sensores
        US_TRIG       : out std_logic_vector(3 downto 0);
        US_ECHO       : in  std_logic_vector(3 downto 0);
        LDR_VE        : in  std_logic_vector(3 downto 0);
        LDR_CERCA     : in  std_logic;
        -- Driver TB6612FNG: canal A rueda izquierda, B derecha
        MOT_PWMA      : out std_logic;
        MOT_AIN1      : out std_logic;
        MOT_AIN2      : out std_logic;
        MOT_PWMB      : out std_logic;
        MOT_BIN1      : out std_logic;
        MOT_BIN2      : out std_logic;
        MOT_STBY      : out std_logic;
        -- Encoders: (0) canal A, (1) canal B
        ENC_L         : in  std_logic_vector(1 downto 0);
        ENC_R         : in  std_logic_vector(1 downto 0);
        -- Depuracion
        UART_TX       : out std_logic;
        VGA_R         : out std_logic_vector(3 downto 0);
        VGA_G         : out std_logic_vector(3 downto 0);
        VGA_B         : out std_logic_vector(3 downto 0);
        VGA_HS        : out std_logic;
        VGA_VS        : out std_logic
    );
end entity robot_top;

architecture rtl of robot_top is
    signal clk : std_logic;
    signal rst : std_logic;

    -- reset de encendido: 16 ciclos
    signal por_cnt : unsigned(3 downto 0) := (others => '0');
    signal por     : std_logic := '1';

    signal tick_1us, tick_1ms : std_logic;

    signal key_s    : std_logic_vector(1 downto 0);
    signal arranque : std_logic;
    signal sw_s     : std_logic_vector(9 downto 0);
    signal sw_d     : std_logic_vector(9 downto 0);

    signal echo_s  : std_logic_vector(3 downto 0);
    signal ldr_s   : std_logic_vector(4 downto 0);
    signal enc_s   : std_logic_vector(3 downto 0);

    signal dist    : std_logic_vector(35 downto 0);
    signal nuevo   : std_logic_vector(3 downto 0);
    signal luz     : std_logic_vector(3 downto 0);
    signal dir_luz : std_logic_vector(2 downto 0);
    signal hay_luz, luz_cerca : std_logic;
    signal obs     : std_logic_vector(3 downto 0);
    signal lado_libre, atasco : std_logic;

    signal estado, accion, evento, acc_mot : std_logic_vector(2 downto 0);
    signal ev_nuevo, moviendo : std_logic;

    signal dir_l, dir_r       : std_logic;
    signal obj_l, obj_r       : std_logic_vector(7 downto 0);
    signal duty_l, duty_r     : std_logic_vector(7 downto 0);
    signal vel_l, vel_r       : std_logic_vector(9 downto 0);
    signal listo_l, listo_r   : std_logic;
    signal pwm_l, pwm_r       : std_logic;

    signal dist_sel : std_logic_vector(8 downto 0);

    signal t_led   : natural range 0 to 499 := 0;
    signal latido  : std_logic := '0';
    signal t_blink : natural range 0 to 124 := 0;
    signal blink   : std_logic := '0';
begin

    clk <= MAX10_CLK1_50;

    -- ---------------- Reset ----------------
    process (clk)
    begin
        if rising_edge(clk) then
            if por_cnt /= 15 then
                por_cnt <= por_cnt + 1;
                por     <= '1';
            else
                por <= '0';
            end if;
        end if;
    end process;

    u_sync_key : entity work.sync_2ff
        generic map (WIDTH => 2, INIT => '1')
        port map (clk => clk, d => KEY, q => key_s);

    rst <= por or not key_s(1);

    u_ticks : entity work.tick_gen
        generic map (CLK_HZ => CLK_HZ)
        port map (clk => clk, rst => rst, tick_1us => tick_1us,
                  tick_58us => open, tick_1ms => tick_1ms);

    -- KEY0 es activo en bajo: arranque = flanco de bajada filtrado
    u_deb_key0 : entity work.debounce
        generic map (N_MS => DEB_MS, INIT => '1')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => key_s(0),
                  clean => open, rise => open, fall => arranque);

    u_sync_sw : entity work.sync_2ff
        generic map (WIDTH => 10, INIT => '0')
        port map (clk => clk, d => SW, q => sw_s);

    deb_sw : for i in 0 to 9 generate
        u_deb : entity work.debounce
            generic map (N_MS => DEB_MS, INIT => '0')
            port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => sw_s(i),
                      clean => sw_d(i), rise => open, fall => open);
    end generate;

    -- ---------------- Sensores ----------------
    u_sync_echo : entity work.sync_2ff
        generic map (WIDTH => 4, INIT => '0')
        port map (clk => clk, d => US_ECHO, q => echo_s);

    u_ultra : entity work.ultra_sched
        generic map (TURNO_MS => TURNO_MS)
        port map (clk => clk, rst => rst, tick_1us => tick_1us, tick_1ms => tick_1ms,
                  echo => echo_s, trig => US_TRIG, dist => dist, nuevo => nuevo,
                  sin_eco => open);

    u_sync_ldr : entity work.sync_2ff
        generic map (WIDTH => 5, INIT => '0')
        port map (clk => clk, d(3 downto 0) => LDR_VE, d(4) => LDR_CERCA, q => ldr_s);

    u_ldr : entity work.ldr_dir
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms,
                  ve => ldr_s(3 downto 0), cerca => ldr_s(4), luz => luz,
                  dir_luz => dir_luz, hay_luz => hay_luz, luz_cerca => luz_cerca);

    u_obs : entity work.obst_eval
        port map (clk => clk, rst => rst, dist => dist, obs => obs,
                  lado_libre => lado_libre);

    u_stall : entity work.stall_detect
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, moviendo => moviendo,
                  dist => dist, nuevo => nuevo, atasco => atasco);

    -- ---------------- Control ----------------
    u_fsm : entity work.fsm_nav
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, arranque => arranque,
                  hay_luz => hay_luz, luz_cerca => luz_cerca, dir_luz => dir_luz,
                  obs => obs, lado_libre => lado_libre, atasco => atasco,
                  estado => estado, accion => accion, evento => evento,
                  ev_nuevo => ev_nuevo, moviendo => moviendo);

    -- SW7: prueba de motores (adelante, sin importar la FSM)
    acc_mot <= A_AVANZA when sw_d(7) = '1' else accion;

    u_drive : entity work.drive_cmd
        generic map (V_AVANCE => V_AVANCE)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, accion => acc_mot,
                  habilitado => sw_d(8), dir_l => dir_l, duty_l => obj_l,
                  dir_r => dir_r, duty_r => obj_r);

    -- ---------------- Motores ----------------
    u_sync_enc : entity work.sync_2ff
        generic map (WIDTH => 4, INIT => '0')
        port map (clk => clk, d(1 downto 0) => ENC_L, d(3 downto 2) => ENC_R, q => enc_s);

    u_vel_l : entity work.encoder_vel
        generic map (UN_CANAL => UN_CANAL)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, a => enc_s(0), b => enc_s(1),
                  vel => vel_l, listo => listo_l);

    u_vel_r : entity work.encoder_vel
        generic map (UN_CANAL => UN_CANAL)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, a => enc_s(2), b => enc_s(3),
                  vel => vel_r, listo => listo_r);

    u_pi_l : entity work.pi_ctrl
        generic map (VMAX => VMAX_ENC)
        port map (clk => clk, rst => rst, habilitado => sw_d(2), actualizar => listo_l,
                  objetivo => obj_l, medida => vel_l, duty => duty_l);

    u_pi_r : entity work.pi_ctrl
        generic map (VMAX => VMAX_ENC)
        port map (clk => clk, rst => rst, habilitado => sw_d(2), actualizar => listo_r,
                  objetivo => obj_r, medida => vel_r, duty => duty_r);

    u_pwm_l : entity work.pwm_8b
        port map (clk => clk, rst => rst, duty => duty_l, pwm => pwm_l);

    u_pwm_r : entity work.pwm_8b
        port map (clk => clk, rst => rst, duty => duty_r, pwm => pwm_r);

    u_mot_l : entity work.motor_if
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, dir => dir_l, pwm => pwm_l,
                  in1 => MOT_AIN1, in2 => MOT_AIN2, en => MOT_PWMA);

    u_mot_r : entity work.motor_if
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, dir => dir_r, pwm => pwm_r,
                  in1 => MOT_BIN1, in2 => MOT_BIN2, en => MOT_PWMB);

    MOT_STBY <= sw_d(8) and not rst;

    -- ---------------- Visualizacion ----------------
    with sw_d(1 downto 0) select
        dist_sel <= dist(8 downto 0)   when "00",
                    dist(17 downto 9)  when "01",
                    dist(26 downto 18) when "10",
                    dist(35 downto 27) when others;

    u_disp : entity work.seg7_disp
        port map (clk => clk, estado => estado, evento => evento,
                  duty_l => duty_l, duty_r => duty_r, modo_dist => sw_d(9),
                  sensor => sw_d(1 downto 0), dist_cm => dist_sel,
                  hex0 => HEX0, hex1 => HEX1, hex2 => HEX2,
                  hex3 => HEX3, hex4 => HEX4, hex5 => HEX5);

    process (clk)
    begin
        if rising_edge(clk) then
            if tick_1ms = '1' then
                if t_led = 499 then
                    t_led  <= 0;
                    latido <= not latido;
                else
                    t_led <= t_led + 1;
                end if;
                if t_blink = 124 then
                    t_blink <= 0;
                    blink   <= not blink;
                else
                    t_blink <= t_blink + 1;
                end if;
            end if;
            if estado = E_META then
                LEDR <= (others => blink);
            else
                LEDR(3 downto 0) <= luz;
                LEDR(7 downto 4) <= obs;
                if estado = E_ESCAPE then
                    LEDR(8) <= '1';
                else
                    LEDR(8) <= '0';
                end if;
                LEDR(9) <= latido;
            end if;
        end if;
    end process;

    u_tel : entity work.telemetria
        generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, ev_nuevo => ev_nuevo,
                  estado => estado, evento => evento, dist => dist, luz => luz,
                  cerca => luz_cerca, duty_l => duty_l, duty_r => duty_r, tx => UART_TX);

    u_vga : entity work.vga_debug
        port map (clk => clk, rst => rst, estado => estado, evento => evento, luz => luz,
                  cerca => luz_cerca, obs => obs, dist => dist, duty_l => duty_l,
                  duty_r => duty_r, dir_l => dir_l, dir_r => dir_r,
                  vga_r => VGA_R, vga_g => VGA_G, vga_b => VGA_B,
                  vga_hs => VGA_HS, vga_vs => VGA_VS);

end architecture rtl;
