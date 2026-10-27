-- ============================================================
-- dds.vhd
-- Acumulador de fase de la sintesis digital directa (DDS).
-- En cada muestra (tick_fs) suma el incremento:
--     fase = fase + inc   (modulo 2**24)
-- La frecuencia de salida es f = inc * Fs / 2**24, con
-- Fs = 48 828.125 Hz (resolucion de 0.0029 Hz). El incremento se
-- puede cambiar en cualquier momento: la fase sigue desde donde
-- iba, sin saltos (cambio de nota sin volver a programar).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dds is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;   -- sincrono, activo en alto
        tick_fs : in  std_logic;
        inc     : in  std_logic_vector(23 downto 0);
        fase    : out std_logic_vector(23 downto 0)
    );
end entity dds;

architecture rtl of dds is
    signal acc : unsigned(23 downto 0) := (others => '0');
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                acc <= (others => '0');
            elsif tick_fs = '1' then
                acc <= acc + unsigned(inc);
            end if;
        end if;
    end process;

    fase <= std_logic_vector(acc);

end architecture rtl;
