-- ============================================================
-- audio_salida.vhd
-- Etapa de salida de audio del sintetizador:
--
--   voz0..2 -> mezclador -> tremolo -> eco -> volumen -> (+) -> PWM
--                                                         ^
--                                     metronomo (clic) ---+
--
-- Formato interno: 12 bits con signo = muestra de 8 bits con 4 bits
-- de fraccion (escala completa +-2032 = +-127.0).
--   mezclador : (voz0 + voz1 + voz2) / 2, saturado
--   efecto    : 00 ninguno, 01 tremolo, 10 eco, 11 los dos
--               (tremolo primero, luego eco)
--   volumen   : 0, 25, 50, 75 o 100 %
--   final     : y / 16 (a 8 bits) + clic del metronomo, saturado a
--               +-127; el clic no pasa por el volumen
--   salida_pwm: PWM de 8 bits a 195.3 kHz con duty = muestra + 128
-- Todo avanza con tick_fs (una muestra cada 1024 ciclos); la cadena
-- tarda 9 ciclos desde tick_fs hasta la muestra final y el PWM la
-- toma al empezar su siguiente periodo de 256 ciclos.
--   clip  : '1' si hubo saturacion (mezcla, eco o suma final) en
--           los ultimos ~100 ms
--   nivel : |muestra final| (0..127), para medidores
--   beat, acento: pulsos del metronomo
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity audio_salida is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_fs  : in  std_logic;   -- pulso de 1 ciclo cada FS_DIV ciclos
        tick_1ms : in  std_logic;   -- pulso de 1 ciclo cada 1 ms
        voz0     : in  std_logic_vector(7 downto 0);   -- con signo
        voz1     : in  std_logic_vector(7 downto 0);
        voz2     : in  std_logic_vector(7 downto 0);
        volumen  : in  std_logic_vector(2 downto 0);   -- 0..4
        efecto   : in  std_logic_vector(1 downto 0);   -- E_*
        metro_on : in  std_logic;
        tempo    : in  std_logic_vector(1 downto 0);   -- periodo_beat_ms
        pwm      : out std_logic;
        beat     : out std_logic;
        acento   : out std_logic;
        clip     : out std_logic;
        nivel    : out std_logic_vector(7 downto 0)
    );
end entity audio_salida;

architecture estructural of audio_salida is
    constant CLIP_MS : natural := 100;

    signal act_tre, act_eco : std_logic;
    signal mez, tre, eco_y, vol_y : std_logic_vector(11 downto 0);
    signal v_mez, v_tre, v_eco, v_vol : std_logic;
    signal sat_mez, sat_eco : std_logic;
    signal clic : std_logic_vector(7 downto 0);

    signal muestra   : signed(7 downto 0) := (others => '0');
    signal muestra_v : std_logic_vector(7 downto 0);
    signal s_nivel   : unsigned(7 downto 0) := (others => '0');
    signal clip_cnt  : natural range 0 to CLIP_MS := 0;
begin

    act_tre <= '1' when efecto = E_TREMOLO or efecto = E_AMBOS else '0';
    act_eco <= '1' when efecto = E_ECO or efecto = E_AMBOS else '0';

    u_mez : entity work.mezclador
        port map (
            clk        => clk,
            rst        => rst,
            ent_valida => tick_fs,
            voz0       => voz0,
            voz1       => voz1,
            voz2       => voz2,
            mezcla     => mez,
            sal_valida => v_mez,
            satura     => sat_mez
        );

    u_tre : entity work.tremolo
        port map (
            clk        => clk,
            rst        => rst,
            activo     => act_tre,
            ent_valida => v_mez,
            x          => mez,
            y          => tre,
            sal_valida => v_tre
        );

    u_eco : entity work.eco
        generic map (RETARDO => 8192)
        port map (
            clk        => clk,
            rst        => rst,
            activo     => act_eco,
            ent_valida => v_tre,
            x          => tre,
            y          => eco_y,
            sal_valida => v_eco,
            satura     => sat_eco
        );

    u_vol : entity work.volumen
        port map (
            clk        => clk,
            rst        => rst,
            ent_valida => v_eco,
            x          => eco_y,
            vol        => volumen,
            y          => vol_y,
            sal_valida => v_vol
        );

    u_met : entity work.metronomo
        port map (
            clk      => clk,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms,
            metro_on => metro_on,
            tempo    => tempo,
            beat     => beat,
            acento   => acento,
            clic     => clic
        );

    -- Etapa final: a 8 bits, suma del clic, saturacion, nivel y clip
    process (clk)
        variable f       : integer range -256 to 256;
        variable fsat    : integer range -127 to 127;
        variable sat_fin : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                muestra  <= (others => '0');
                s_nivel  <= (others => '0');
                clip_cnt <= 0;
            else
                sat_fin := false;
                if v_vol = '1' then
                    f := to_integer(shift_right(signed(vol_y), 4)) +
                         to_integer(signed(clic));
                    if f > 127 then
                        fsat    := 127;
                        sat_fin := true;
                    elsif f < -127 then
                        fsat    := -127;
                        sat_fin := true;
                    else
                        fsat := f;
                    end if;
                    muestra <= to_signed(fsat, 8);
                    if fsat < 0 then
                        s_nivel <= to_unsigned(-fsat, 8);
                    else
                        s_nivel <= to_unsigned(fsat, 8);
                    end if;
                end if;

                -- clip se sostiene CLIP_MS ms despues de la ultima saturacion
                if (v_mez = '1' and sat_mez = '1') or
                   (v_eco = '1' and sat_eco = '1') or sat_fin then
                    clip_cnt <= CLIP_MS;
                elsif tick_1ms = '1' and clip_cnt /= 0 then
                    clip_cnt <= clip_cnt - 1;
                end if;
            end if;
        end if;
    end process;

    u_pwm : entity work.salida_pwm
        port map (
            clk     => clk,
            rst     => rst,
            muestra => muestra_v,
            pwm     => pwm
        );

    muestra_v <= std_logic_vector(muestra);
    clip      <= '1' when clip_cnt /= 0 else '0';
    nivel     <= std_logic_vector(s_nivel);

end architecture estructural;
