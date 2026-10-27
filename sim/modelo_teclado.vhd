-- ============================================================
-- modelo_teclado.vhd
-- Modelo de un teclado matricial 4x4 de membrana para las
-- pruebas del sistema completo. La FPGA maneja las filas con '0'
-- o 'Z'; cada columna tiene pull-up (se modela con 'H') y lee
-- '0' cuando una tecla presionada la une con una fila en '0'.
-- presion: tecla 4*fila + columna en '1' = presionada.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity modelo_teclado is
    port (
        filas   : in  std_logic_vector(3 downto 0);
        cols    : out std_logic_vector(3 downto 0);
        presion : in  std_logic_vector(15 downto 0)
    );
end entity modelo_teclado;

architecture modelo of modelo_teclado is
begin

    process (filas, presion)
        variable v : std_logic;
    begin
        for c in 0 to 3 loop
            v := 'H';
            for r in 0 to 3 loop
                if filas(r) = '0' and presion(4 * r + c) = '1' then
                    v := '0';
                end if;
            end loop;
            cols(c) <= v;
        end loop;
    end process;

end architecture modelo;
