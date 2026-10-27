-- ============================================================
-- leds_estado.vhd
-- Indicadores en LEDR0-LEDR9:
--   0-2 voces sonando (cada una con su LED)
--   3   metronomo encendido
--   4   tiempo del metronomo (destello de 100 ms por tiempo)
--   5   grabando
--   6   reproduciendo
--   7   memoria de eventos llena
--   8   efecto activo (tremolo, eco o los dos)
--   9   saturacion del audio en los ultimos 100 ms
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
        activas    : in  std_logic_vector(2 downto 0);
        metro_on   : in  std_logic;
        beat       : in  std_logic;
        estado_sec : in  std_logic_vector(1 downto 0);
        llena      : in  std_logic;
        efecto     : in  std_logic_vector(1 downto 0);
        clip       : in  std_logic;
        ledr       : out std_logic_vector(9 downto 0)
    );
end entity leds_estado;

architecture rtl of leds_estado is
    signal destello : natural range 0 to BEAT_MS := 0;
    signal l        : std_logic_vector(9 downto 0) := (others => '0');
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                destello <= 0;
            elsif beat = '1' then
                destello <= BEAT_MS;
            elsif tick_1ms = '1' and destello > 0 then
                destello <= destello - 1;
            end if;

            l(2 downto 0) <= activas;
            l(3) <= metro_on;
            if destello > 0 then
                l(4) <= '1';
            else
                l(4) <= '0';
            end if;
            if estado_sec = S_GRABANDO then
                l(5) <= '1';
            else
                l(5) <= '0';
            end if;
            if estado_sec = S_REPRODUCE then
                l(6) <= '1';
            else
                l(6) <= '0';
            end if;
            l(7) <= llena;
            if efecto = E_NINGUNO then
                l(8) <= '0';
            else
                l(8) <= '1';
            end if;
            l(9) <= clip;
        end if;
    end process;

    ledr <= l;

end architecture rtl;
