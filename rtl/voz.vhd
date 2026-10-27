-- ============================================================
-- voz.vhd
-- Una voz completa del sintetizador:
--
--   nota -> ROM de incrementos -> DDS -> forma de onda --+
--                                                         x -> muestra
--   gate -------------------------------> ADSR ----------+
--
-- La ROM da el incremento de fase de la nota (synth_pkg); el DDS
-- genera la fase, forma_onda la convierte en muestra (-127..127)
-- y la envolvente la escala:
--     muestra = onda * nivel / 256
-- El producto (8 x 9 bits con signo) cabe en un multiplicador
-- embebido de la MAX 10.
-- La nota debe quedarse fija mientras dure la liberacion; el
-- gestor de voces solo baja el gate al soltar la tecla.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity voz is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;   -- sincrono, activo en alto
        tick_fs : in  std_logic;
        nota    : in  std_logic_vector(6 downto 0);
        gate    : in  std_logic;
        forma   : in  std_logic_vector(1 downto 0);
        atk     : in  std_logic_vector(1 downto 0);
        dec     : in  std_logic_vector(1 downto 0);
        sus     : in  std_logic_vector(1 downto 0);
        rel     : in  std_logic_vector(1 downto 0);
        muestra : out std_logic_vector(7 downto 0);   -- con signo
        nivel   : out std_logic_vector(7 downto 0);   -- envolvente 0..255
        activa  : out std_logic
    );
end entity voz;

architecture estructural of voz is
    constant TABLA : t_tabla_inc := tabla_inc;

    signal inc    : std_logic_vector(23 downto 0);
    signal fase   : std_logic_vector(23 downto 0);
    signal onda   : std_logic_vector(7 downto 0);
    signal env    : std_logic_vector(7 downto 0);
    signal prod_c : signed(16 downto 0);
    signal prod   : signed(16 downto 0) := (others => '0');
begin

    -- ROM de incrementos (combinacional: 128 x 24 bits en LUTs)
    inc <= std_logic_vector(to_unsigned(TABLA(to_integer(unsigned(nota))), 24));

    u_dds : entity work.dds
        port map (
            clk     => clk,
            rst     => rst,
            tick_fs => tick_fs,
            inc     => inc,
            fase    => fase
        );

    u_onda : entity work.forma_onda
        port map (
            clk     => clk,
            forma   => forma,
            fase    => fase,
            muestra => onda
        );

    u_adsr : entity work.adsr
        port map (
            clk     => clk,
            rst     => rst,
            tick_fs => tick_fs,
            gate    => gate,
            atk     => atk,
            dec     => dec,
            sus     => sus,
            rel     => rel,
            nivel   => env,
            etapa   => open,
            activa  => activa
        );

    -- onda (con signo) por nivel (sin signo, se extiende con un 0),
    -- con el producto registrado
    prod_c <= signed(onda) * signed('0' & env);

    process (clk)
    begin
        if rising_edge(clk) then
            prod <= prod_c;
        end if;
    end process;

    -- |prod| < 2**15, asi que los bits 15..8 son prod / 256 con signo
    muestra <= std_logic_vector(prod(15 downto 8));
    nivel   <= env;

end architecture estructural;
