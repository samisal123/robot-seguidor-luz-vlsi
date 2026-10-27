-- ============================================================
-- sync_2ff.vhd
-- Sincronizador de 2 flip-flops para entradas asincronas
-- (columnas de los teclados, botones y switches). Un cambio en
-- d aparece en q en el segundo flanco de reloj despues del
-- cambio. El primer flip-flop puede quedar metaestable; el
-- segundo le da un ciclo completo para resolverse.
-- No lleva reset: arranca en INIT por valor de encendido.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity sync_2ff is
    generic (
        WIDTH : positive  := 1;
        INIT  : std_logic := '0'
    );
    port (
        clk : in  std_logic;
        d   : in  std_logic_vector(WIDTH - 1 downto 0);
        q   : out std_logic_vector(WIDTH - 1 downto 0)
    );
end entity sync_2ff;

architecture rtl of sync_2ff is
    signal meta : std_logic_vector(WIDTH - 1 downto 0) := (others => INIT);
    signal sinc : std_logic_vector(WIDTH - 1 downto 0) := (others => INIT);

    -- Le dice a Quartus que es una cadena de sincronizacion: la deja
    -- junta y la incluye en el reporte de metaestabilidad (MTBF)
    attribute altera_attribute : string;
    attribute altera_attribute of meta : signal is
        "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
begin

    process (clk)
    begin
        if rising_edge(clk) then
            meta <= d;
            sinc <= meta;
        end if;
    end process;

    q <= sinc;

end architecture rtl;
