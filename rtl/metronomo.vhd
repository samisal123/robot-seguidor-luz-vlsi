-- ============================================================
-- metronomo.vhd
-- Metronomo de 60, 90, 120 o 150 BPM con clic audible.
-- Tiempos: cuenta milisegundos con tick_1ms y marca un tiempo cada
-- periodo_beat_ms(tempo) ms (1000, 667, 500, 400; synth_pkg).
-- Al encender metro_on el primer tiempo es inmediato y lleva
-- acento; despues hay acento en 1 de cada 4 tiempos (compas de 4).
-- Si tempo cambia a uno mas rapido, el siguiente tiempo cae en el
-- siguiente milisegundo si la cuenta ya paso el nuevo periodo.
--   beat   : pulso de 1 ciclo por tiempo
--   acento : '1' junto con beat en el primer tiempo del compas
-- Clic: tono cuadrado de 2 kHz (3 kHz en el acento) de unos 25 ms
-- cuya amplitud baja en linea recta de CLIC_AMP a 0. Se calcula una
-- muestra por tick_fs:
--   fase : acumulador de 16 bits, f = inc * Fs / 2**16
--          (2684 -> 1999.7 Hz, 4027 -> 3000.2 Hz)
--   env  : envolvente de 16 bits; arranca en CLIC_AMP * 1024 y baja
--          DEC_ENV por muestra; amplitud = env / 1024
--          (48 -> 0 en 1204 muestras = 24.7 ms)
--   clic = +amplitud o -amplitud segun el bit alto de la fase
-- Al apagar metro_on ya no hay tiempos nuevos; el clic que sonaba
-- termina solo.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity metronomo is
    generic (
        CLK_HZ   : natural := CLK_HZ_SIS;
        CLIC_AMP : natural := 48          -- amplitud inicial del clic, de 127
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_fs  : in  std_logic;
        tick_1ms : in  std_logic;
        metro_on : in  std_logic;
        tempo    : in  std_logic_vector(1 downto 0);
        beat     : out std_logic;
        acento   : out std_logic;
        clic     : out std_logic_vector(7 downto 0)   -- con signo, cambia con tick_fs
    );
end entity metronomo;

architecture rtl of metronomo is
    constant FS_HZ   : natural := CLK_HZ / FS_DIV;                     -- 48 828
    constant INC_2K  : natural := (2000 * 65536 + FS_HZ / 2) / FS_HZ;  -- 2684
    constant INC_3K  : natural := (3000 * 65536 + FS_HZ / 2) / FS_HZ;  -- 4027
    constant N_CLIC  : natural := (25 * (CLK_HZ / 1000)) / FS_DIV;     -- 1220 muestras
    constant ENV_INI : natural := CLIC_AMP * 1024;                      -- 49 152
    constant DEC_ENV : natural := ENV_INI / N_CLIC;                     -- 40

    signal on_r     : std_logic := '0';
    signal cuenta   : natural range 0 to 1023 := 0;   -- ms desde el ultimo tiempo
    signal num      : natural range 0 to 3 := 0;      -- tiempo siguiente dentro del compas
    signal s_beat   : std_logic := '0';
    signal s_acento : std_logic := '0';
    signal inc      : unsigned(15 downto 0) := to_unsigned(INC_2K, 16);
    signal fase     : unsigned(15 downto 0) := (others => '0');
    signal env      : unsigned(15 downto 0) := (others => '0');
    signal s_clic   : signed(7 downto 0) := (others => '0');
begin

    process (clk)
        variable dispara   : boolean;
        variable es_acento : boolean;
        variable amp       : signed(7 downto 0);
    begin
        if rising_edge(clk) then
            s_beat   <= '0';
            s_acento <= '0';
            if rst = '1' then
                on_r   <= '0';
                cuenta <= 0;
                num    <= 0;
                inc    <= to_unsigned(INC_2K, 16);
                fase   <= (others => '0');
                env    <= (others => '0');
                s_clic <= (others => '0');
            else
                on_r      <= metro_on;
                dispara   := false;
                es_acento := false;

                -- Tiempos del metronomo
                if metro_on = '1' then
                    if on_r = '0' then
                        -- recien encendido: tiempo inmediato con acento
                        dispara   := true;
                        es_acento := true;
                        cuenta    <= 0;
                        num       <= 1;
                    elsif tick_1ms = '1' then
                        if cuenta >= periodo_beat_ms(tempo) - 1 then
                            dispara   := true;
                            es_acento := (num = 0);
                            cuenta    <= 0;
                            if num = 3 then
                                num <= 0;
                            else
                                num <= num + 1;
                            end if;
                        else
                            cuenta <= cuenta + 1;
                        end if;
                    end if;
                end if;

                -- Clic: una muestra por tick_fs
                if tick_fs = '1' then
                    amp := signed(resize(env(15 downto 10), 8));
                    if fase(15) = '0' then
                        s_clic <= amp;
                    else
                        s_clic <= -amp;
                    end if;
                    fase <= fase + inc;
                    if env > DEC_ENV then
                        env <= env - DEC_ENV;
                    else
                        env <= (others => '0');
                    end if;
                end if;

                -- Un tiempo nuevo arranca el clic desde el principio
                if dispara then
                    s_beat <= '1';
                    if es_acento then
                        s_acento <= '1';
                        inc      <= to_unsigned(INC_3K, 16);
                    else
                        inc      <= to_unsigned(INC_2K, 16);
                    end if;
                    fase <= (others => '0');
                    env  <= to_unsigned(ENV_INI, 16);
                end if;
            end if;
        end if;
    end process;

    beat   <= s_beat;
    acento <= s_acento;
    clic   <= std_logic_vector(s_clic);

end architecture rtl;
