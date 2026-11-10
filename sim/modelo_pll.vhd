-- ============================================================
-- modelo_pll.vhd
-- Modelo de simulacion del PLL (misma entidad que
-- quartus/ip/pll_25mhz.vhd): c0 es inclk0 dividido entre 2 y
-- locked sube despues de 20 periodos de la entrada, como un PLL
-- que tarda en engancharse.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity pll_25mhz is
    port (
        inclk0 : in  std_logic;   -- 50 MHz
        c0     : out std_logic;   -- 25 MHz
        locked : out std_logic
    );
end entity pll_25mhz;

architecture modelo of pll_25mhz is
    signal r      : std_logic := '0';
    signal cuenta : natural range 0 to 20 := 0;
    signal l      : std_logic := '0';
begin

    process (inclk0)
    begin
        if rising_edge(inclk0) then
            r <= not r;
            if cuenta = 20 then
                l <= '1';
            else
                cuenta <= cuenta + 1;
            end if;
        end if;
    end process;

    c0     <= r;
    locked <= l;

end architecture modelo;
