-- ============================================================
-- robot_top.vhd
-- Top de prueba (smoke test) para validar la cadena de Quartus.
-- LEDR0 parpadea a 1 Hz y LEDR1 refleja KEY0 (activo en bajo).
-- Se reemplaza por el top real del robot en la Semana 2.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity robot_top is
    generic (
        CLK_HZ : natural := 50_000_000
    );
    port (
        MAX10_CLK1_50 : in  std_logic;
        KEY           : in  std_logic_vector(1 downto 0);
        LEDR          : out std_logic_vector(9 downto 0)
    );
end entity robot_top;

architecture rtl of robot_top is
    constant MEDIO_PERIODO : natural := CLK_HZ / 2;
    signal cuenta : natural range 0 to MEDIO_PERIODO - 1 := 0;
    signal latido : std_logic := '0';
begin

    process (MAX10_CLK1_50)
    begin
        if rising_edge(MAX10_CLK1_50) then
            if cuenta = MEDIO_PERIODO - 1 then
                cuenta <= 0;
                latido <= not latido;
            else
                cuenta <= cuenta + 1;
            end if;
        end if;
    end process;

    LEDR(0)          <= latido;
    LEDR(1)          <= not KEY(0);
    LEDR(9 downto 2) <= (others => '0');

end architecture rtl;
