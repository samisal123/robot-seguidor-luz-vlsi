-- ============================================================
-- selector_notas.vhd
-- Elige que notas piden las voces: mientras el secuenciador
-- reproduce, las grabadas; en cualquier otro momento, las del
-- teclado (en vivo). Asi la reproduccion no se mezcla con lo
-- que se toque encima.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity selector_notas is
    port (
        estado_sec : in  std_logic_vector(1 downto 0);
        vivo       : in  std_logic_vector(20 downto 0);
        grabado    : in  std_logic_vector(20 downto 0);
        pedidas    : out std_logic_vector(20 downto 0)
    );
end entity selector_notas;

architecture rtl of selector_notas is
begin

    pedidas <= grabado when estado_sec = S_REPRODUCE else vivo;

end architecture rtl;
