-- ============================================================
-- leds_estado.vhd
-- Los 3 LEDs de la tarjeta EP2C5T144 (se encienden con '0'):
--   led_n(0)  D2  tiempo del metronomo: destello de 100 ms en cada
--                 tiempo, solo con el metronomo encendido
--   led_n(1)  D4  grabando
--   led_n(2)  D5  reproduciendo
-- El resto del estado se ve en la pantalla VGA.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity leds_estado is
    generic (
        BEAT_MS : positive := 100
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        tick_1ms   : in  std_logic;
        metro_on   : in  std_logic;
        beat       : in  std_logic;
        estado_sec : in  std_logic_vector(1 downto 0);
        led_n      : out std_logic_vector(2 downto 0)   -- '0' = encendido
    );
end entity leds_estado;

architecture rtl of leds_estado is
    signal destello : natural range 0 to BEAT_MS := 0;
    signal l        : std_logic_vector(2 downto 0) := (others => '0');   -- '1' = encendido
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                destello <= 0;
                l        <= (others => '0');
            else
                if beat = '1' then
                    destello <= BEAT_MS;
                elsif tick_1ms = '1' and destello > 0 then
                    destello <= destello - 1;
                end if;
                if metro_on = '1' and destello > 0 then
                    l(0) <= '1';
                else
                    l(0) <= '0';
                end if;
                if estado_sec = S_GRABANDO then
                    l(1) <= '1';
                else
                    l(1) <= '0';
                end if;
                if estado_sec = S_REPRODUCE then
                    l(2) <= '1';
                else
                    l(2) <= '0';
                end if;
            end if;
        end if;
    end process;

    led_n <= not l;

end architecture rtl;
