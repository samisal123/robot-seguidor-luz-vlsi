-- ============================================================
-- tb_selector_notas.vhd
-- Prueba del selector de notas: las voces piden las notas
-- grabadas solo mientras el secuenciador reproduce; en espera y
-- grabando, las del teclado.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity tb_selector_notas is
end entity tb_selector_notas;

architecture sim of tb_selector_notas is
    signal estado_sec : std_logic_vector(1 downto 0) := S_ESPERA;
    signal vivo       : std_logic_vector(20 downto 0) := "000000000000000111001";
    signal grabado    : std_logic_vector(20 downto 0) := "100000110000001000000";
    signal pedidas    : std_logic_vector(20 downto 0);
begin

    dut : entity work.selector_notas
        port map (
            estado_sec => estado_sec,
            vivo       => vivo,
            grabado    => grabado,
            pedidas    => pedidas
        );

    estimulo : process
    begin
        wait for 1 ns;
        assert pedidas = vivo report "tb_selector_notas: en espera van las notas en vivo" severity error;
        estado_sec <= S_GRABANDO;
        wait for 1 ns;
        assert pedidas = vivo report "tb_selector_notas: grabando van las notas en vivo" severity error;
        estado_sec <= S_REPRODUCE;
        wait for 1 ns;
        assert pedidas = grabado report "tb_selector_notas: reproduciendo van las grabadas" severity error;
        grabado <= (others => '0');
        wait for 1 ns;
        assert pedidas = grabado report "tb_selector_notas: el silencio grabado tambien pasa" severity error;
        report "tb_selector_notas: OK";
        wait;
    end process;

end architecture sim;
