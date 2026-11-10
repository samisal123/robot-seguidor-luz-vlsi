-- ============================================================
-- reset_encendido.vhd
-- Reset del sistema: rst = '1' desde que se configura la FPGA
-- hasta 16 ciclos despues de que el PLL se engancha (listo = '1').
-- El boton RESET de la tarjeta (boton_n, activo en bajo) repite
-- lo mismo: rst sube mientras esta presionado y baja 16 ciclos
-- despues de soltarlo. Las dos entradas son asincronas y pasan
-- por un sincronizador de 2 flip-flops. Los registros de la
-- Cyclone II arrancan con su valor inicial; este reset garantiza
-- que todos los modulos empiecen juntos y con el reloj estable.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_encendido is
    port (
        clk     : in  std_logic;
        listo   : in  std_logic;   -- PLL enganchado
        boton_n : in  std_logic;   -- boton RESET, '0' = presionado
        rst     : out std_logic
    );
end entity reset_encendido;

architecture rtl of reset_encendido is
    signal ent    : std_logic_vector(1 downto 0);
    signal ent_s  : std_logic_vector(1 downto 0);
    signal cuenta : unsigned(3 downto 0) := (others => '0');
    signal r      : std_logic := '1';
begin

    ent <= boton_n & listo;

    u_sync : entity work.sync_2ff
        generic map (WIDTH => 2, INIT => '0')
        port map (clk => clk, d => ent, q => ent_s);

    process (clk)
    begin
        if rising_edge(clk) then
            if ent_s /= "11" then
                cuenta <= (others => '0');
                r      <= '1';
            elsif cuenta /= 15 then
                cuenta <= cuenta + 1;
                r      <= '1';
            else
                r <= '0';
            end if;
        end if;
    end process;

    rst <= r;

end architecture rtl;
