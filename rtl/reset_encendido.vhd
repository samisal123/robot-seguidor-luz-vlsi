-- ============================================================
-- reset_encendido.vhd
-- Reset de encendido: rst = '1' durante los primeros 16 ciclos
-- despues de configurar la FPGA y luego '0' para siempre. Los
-- registros de la MAX 10 arrancan con su valor inicial; este
-- reset solo garantiza que todos los modulos empiecen juntos.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_encendido is
    port (
        clk : in  std_logic;
        rst : out std_logic
    );
end entity reset_encendido;

architecture rtl of reset_encendido is
    signal cuenta : unsigned(3 downto 0) := (others => '0');
    signal r      : std_logic := '1';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if cuenta /= 15 then
                cuenta <= cuenta + 1;
                r      <= '1';
            else
                r <= '0';
            end if;
        end if;
    end process;

    rst <= r;

end architecture rtl;
