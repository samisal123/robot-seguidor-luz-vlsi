-- ============================================================
-- hcsr04.vhd
-- Controlador de un sensor ultrasonico HC-SR04.
-- Con un pulso en start:
--   1. TRIG en alto entre TRIG_US y TRIG_US+1 us.
--   2. Espera el flanco de subida de ECHO.
--   3. Mide el ancho de ECHO en cm (1 cm = 58 us de eco). La
--      cuenta de 58 us arranca en el flanco del eco con medio
--      periodo de ventaja, asi dist_cm = round(t_eco / 58).
--   4. Entrega dist_cm con un pulso valid de un ciclo.
-- Si no hay eco, o el eco no termina, dentro de TIMEOUT_US
-- despues del TRIG: dist_cm = 511 (todo en 1) y timeout = '1'.
-- start se ignora mientras busy = '1'.
-- echo ya debe venir sincronizado (sync_2ff) y bajado a 3.3 V.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hcsr04 is
    generic (
        TRIG_US    : positive := 10;
        TIMEOUT_US : positive := 25_000     -- unos 4.3 m
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1us : in  std_logic;
        start    : in  std_logic;
        echo     : in  std_logic;
        trig     : out std_logic;
        dist_cm  : out std_logic_vector(8 downto 0);
        valid    : out std_logic;
        timeout  : out std_logic;   -- la ultima medicion no tuvo eco
        busy     : out std_logic
    );
end entity hcsr04;

architecture rtl of hcsr04 is
    type t_estado is (REPOSO, DISPARO, ESPERA, MIDE);
    constant DIST_MAX : unsigned(8 downto 0) := (others => '1');

    signal estado    : t_estado := REPOSO;
    signal cuenta_us : natural range 0 to TIMEOUT_US := 0;  -- TRIG y timeout
    signal sub58     : natural range 0 to 57 := 0;
    signal cm        : unsigned(8 downto 0) := (others => '0');
    signal echo_ant  : std_logic := '0';
    signal dist_reg  : unsigned(8 downto 0) := DIST_MAX;
    signal valid_reg : std_logic := '0';
    signal sin_eco   : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            echo_ant  <= echo;
            valid_reg <= '0';
            if rst = '1' then
                estado    <= REPOSO;
                cuenta_us <= 0;
                dist_reg  <= DIST_MAX;
                sin_eco   <= '0';
            else
                case estado is
                    when REPOSO =>
                        if start = '1' then
                            estado    <= DISPARO;
                            cuenta_us <= 0;
                        end if;

                    when DISPARO =>
                        if tick_1us = '1' then
                            if cuenta_us = TRIG_US then
                                estado    <= ESPERA;
                                cuenta_us <= 0;
                            else
                                cuenta_us <= cuenta_us + 1;
                            end if;
                        end if;

                    when ESPERA | MIDE =>
                        if estado = ESPERA and echo = '1' and echo_ant = '0' then
                            estado <= MIDE;
                            cm     <= (others => '0');
                            sub58  <= 29;              -- redondeo
                        elsif estado = MIDE and echo = '0' then
                            estado    <= REPOSO;
                            dist_reg  <= cm;
                            sin_eco   <= '0';
                            valid_reg <= '1';
                        elsif tick_1us = '1' then
                            if cuenta_us = TIMEOUT_US - 1 then
                                estado    <= REPOSO;
                                dist_reg  <= DIST_MAX;
                                sin_eco   <= '1';
                                valid_reg <= '1';
                            else
                                cuenta_us <= cuenta_us + 1;
                            end if;
                            if estado = MIDE then
                                if sub58 = 57 then
                                    sub58 <= 0;
                                    if cm /= DIST_MAX - 1 then
                                        cm <= cm + 1;
                                    end if;
                                else
                                    sub58 <= sub58 + 1;
                                end if;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    trig    <= '1' when estado = DISPARO else '0';
    busy    <= '0' when estado = REPOSO  else '1';
    dist_cm <= std_logic_vector(dist_reg);
    valid   <= valid_reg;
    timeout <= sin_eco;

end architecture rtl;
