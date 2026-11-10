-- ============================================================
-- leds_estado.vhd
-- Los 3 LEDs de la tarjeta EP2C5T144 (se encienden con '0')
-- muestran el modo y el estado, porque el sintetizador no tiene
-- pantalla:
--   Interpretacion, grabacion y reproduccion:
--     led_n(0) D2  tiempo del metronomo: destello de 100 ms en
--                  cada tiempo, solo con el metronomo encendido
--     led_n(1) D4  grabacion: parpadea lento (1 Hz) mientras espera
--                  la orden y queda fijo mientras graba
--     led_n(2) D5  reproduccion: parpadea lento mientras espera y
--                  queda fijo mientras reproduce
--   Configuracion: los 3 LEDs parpadean rapido (4 Hz) con el numero
--   del parametro elegido en binario (D2 = bit 0, D4 = bit 1,
--   D5 = bit 2): 1 forma, 2 attack, 3 decay, 4 sustain, 5 release,
--   6 volumen, 7 tempo.
--   Interpretacion sin metronomo: los 3 apagados.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity leds_estado is
    generic (
        BEAT_MS   : positive := 100;  -- destello del metronomo
        PERIODO_MS : positive := 1000   -- parpadeo lento; el rapido es 4 veces mas rapido
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        tick_1ms   : in  std_logic;
        metro_on   : in  std_logic;
        beat       : in  std_logic;
        modo       : in  std_logic_vector(1 downto 0);
        estado_sec : in  std_logic_vector(1 downto 0);
        parametro  : in  std_logic_vector(2 downto 0);   -- 0 forma .. 6 tempo
        led_n      : out std_logic_vector(2 downto 0)    -- '0' = encendido
    );
end entity leds_estado;

architecture rtl of leds_estado is
    signal destello : natural range 0 to BEAT_MS := 0;
    signal ms       : natural range 0 to PERIODO_MS - 1 := 0;
    signal l        : std_logic_vector(2 downto 0) := (others => '0');   -- '1' = encendido
begin

    process (clk)
        variable lento, rapido : std_logic;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                destello <= 0;
                ms       <= 0;
                l        <= (others => '0');
            else
                if beat = '1' then
                    destello <= BEAT_MS;
                elsif tick_1ms = '1' and destello > 0 then
                    destello <= destello - 1;
                end if;
                if tick_1ms = '1' then
                    if ms = PERIODO_MS - 1 then
                        ms <= 0;
                    else
                        ms <= ms + 1;
                    end if;
                end if;

                -- encendido la primera mitad de cada periodo
                if ms < PERIODO_MS / 2 then lento := '1'; else lento := '0'; end if;
                if (ms mod (PERIODO_MS / 4)) < PERIODO_MS / 8 then rapido := '1'; else rapido := '0'; end if;

                if modo = M_CONF then
                    if rapido = '1' then
                        l <= std_logic_vector(unsigned(parametro) + 1);
                    else
                        l <= (others => '0');
                    end if;
                else
                    if metro_on = '1' and destello > 0 then
                        l(0) <= '1';
                    else
                        l(0) <= '0';
                    end if;
                    if estado_sec = S_GRABANDO then
                        l(1) <= '1';
                    elsif modo = M_GRA then
                        l(1) <= lento;
                    else
                        l(1) <= '0';
                    end if;
                    if estado_sec = S_REPRODUCE then
                        l(2) <= '1';
                    elsif modo = M_REP then
                        l(2) <= lento;
                    else
                        l(2) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    led_n <= not l;

end architecture rtl;
