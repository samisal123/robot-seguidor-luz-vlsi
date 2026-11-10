-- ============================================================
-- debounce.vhd
-- Filtro antirrebote para botones y switches. La salida clean
-- toma el valor de raw solo despues de que raw se mantuvo
-- distinto de clean durante N_MS ticks de 1 ms seguidos (entre
-- N_MS-1 y N_MS ms, segun la fase del tick). Cualquier rebote
-- reinicia la cuenta.
-- raw ya debe venir sincronizado (sync_2ff).
-- rise y fall son pulsos de un ciclo cuando clean sube o baja;
-- sirven, por ejemplo, para que un boton de una sola orden por pulsacion.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity debounce is
    generic (
        N_MS : positive  := 20;
        INIT : std_logic := '0'   -- valor de clean tras reset
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        raw      : in  std_logic;
        clean    : out std_logic;
        rise     : out std_logic;
        fall     : out std_logic
    );
end entity debounce;

architecture rtl of debounce is
    signal cuenta : natural range 0 to N_MS - 1 := 0;
    signal estado : std_logic := INIT;
    signal sube   : std_logic := '0';
    signal baja   : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            sube <= '0';
            baja <= '0';
            if rst = '1' then
                cuenta <= 0;
                estado <= INIT;
            elsif raw = estado then
                cuenta <= 0;
            elsif tick_1ms = '1' then
                if cuenta = N_MS - 1 then
                    cuenta <= 0;
                    estado <= raw;
                    sube   <= raw;
                    baja   <= not raw;
                else
                    cuenta <= cuenta + 1;
                end if;
            end if;
        end if;
    end process;

    clean <= estado;
    rise  <= sube;
    fall  <= baja;

end architecture rtl;
