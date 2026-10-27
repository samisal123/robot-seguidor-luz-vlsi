-- ============================================================
-- interfaz_teclados.vhd
-- Conexion de los dos teclados 4x4 con los pines del GPIO:
--   - sincroniza las 8 columnas (sync_2ff)
--   - barre las filas y filtra rebotes (teclado_scan)
--   - maneja las filas en colector abierto: la fila activa va a
--     '0' y las demas a alta impedancia, para que dos teclas de
--     la misma columna nunca pongan en corto dos salidas
-- Las columnas necesitan pull-up (el interno de la MAX 10, ver
-- quartus/pines.tcl).
-- teclas: '1' = presionada; teclado k, fila r, columna c en el
-- bit 16k + 4r + c.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity interfaz_teclados is
    generic (
        N_DEB : positive := 5
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        tec1_col : in  std_logic_vector(3 downto 0);
        tec2_col : in  std_logic_vector(3 downto 0);
        tec1_fil : out std_logic_vector(3 downto 0);   -- '0' o 'Z'
        tec2_fil : out std_logic_vector(3 downto 0);   -- '0' o 'Z'
        teclas   : out std_logic_vector(31 downto 0)
    );
end entity interfaz_teclados;

architecture estructural of interfaz_teclados is
    signal col_raw : std_logic_vector(7 downto 0);
    signal col_s   : std_logic_vector(7 downto 0);
    signal filas   : std_logic_vector(3 downto 0);
begin

    col_raw <= tec2_col & tec1_col;

    u_sync : entity work.sync_2ff
        generic map (WIDTH => 8, INIT => '1')
        port map (clk => clk, d => col_raw, q => col_s);

    u_scan : entity work.teclado_scan
        generic map (
            N_DEB => N_DEB
        )
        port map (
            clk      => clk,
            rst      => rst,
            tick_1ms => tick_1ms,
            filas    => filas,
            col1     => col_s(3 downto 0),
            col2     => col_s(7 downto 4),
            teclas   => teclas
        );

    colector_abierto : for r in 0 to 3 generate
        tec1_fil(r) <= '0' when filas(r) = '0' else 'Z';
        tec2_fil(r) <= '0' when filas(r) = '0' else 'Z';
    end generate;

end architecture estructural;
