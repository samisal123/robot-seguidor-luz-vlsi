-- ============================================================
-- memoria_eventos.vhd
-- Memoria de eventos musicales del secuenciador: RAM de un
-- puerto, 2**N_DIR palabras de ANCHO bits, escritura sincrona y
-- lectura registrada (el dato de dir sale un ciclo despues).
-- Quartus la mapea en bloques M9K (256 x 37 bits = 2 bloques).
-- Formato de cada evento (ANCHO = 37):
--   bits 36..16 : las 3 notas que sonaban (7 bits cada una,
--                 0 = vacia; las 3 en 0 = silencio)
--   bits 15..0  : duracion en ms (1 a 65 535)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memoria_eventos is
    generic (
        ANCHO : positive := 37;
        N_DIR : positive := 8
    );
    port (
        clk  : in  std_logic;
        we   : in  std_logic;
        dir  : in  std_logic_vector(N_DIR - 1 downto 0);
        din  : in  std_logic_vector(ANCHO - 1 downto 0);
        dout : out std_logic_vector(ANCHO - 1 downto 0)
    );
end entity memoria_eventos;

architecture rtl of memoria_eventos is
    type t_ram is array (0 to 2 ** N_DIR - 1) of std_logic_vector(ANCHO - 1 downto 0);
    signal ram : t_ram;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(dir))) <= din;
            end if;
            dout <= ram(to_integer(unsigned(dir)));
        end if;
    end process;

end architecture rtl;
