-- ============================================================
-- robot_pkg.vhd
-- Codigos compartidos entre modulos. Los puertos de todas las
-- entidades usan solo std_logic y std_logic_vector (para que el
-- Block Editor de Quartus genere sus simbolos); estas constantes
-- solo dan nombre a los valores.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

package robot_pkg is

    -- Indices de sensores (ultrasonicos y bits de obstaculo)
    constant S_FRENTE   : natural := 0;
    constant S_DIAG_IZQ : natural := 1;
    constant S_DIAG_DER : natural := 2;
    constant S_ATRAS    : natural := 3;

    -- Indices de las LDR
    constant L_FRENTE : natural := 0;
    constant L_IZQ    : natural := 1;
    constant L_DER    : natural := 2;
    constant L_ATRAS  : natural := 3;

    -- Estados de fsm_nav (se ven en HEX5)
    constant E_INICIO  : std_logic_vector(2 downto 0) := "000";
    constant E_BUSCAR  : std_logic_vector(2 downto 0) := "001";
    constant E_SEGUIR  : std_logic_vector(2 downto 0) := "010";
    constant E_ESQUIVA : std_logic_vector(2 downto 0) := "011";
    constant E_ESQUINA : std_logic_vector(2 downto 0) := "100";
    constant E_ESCAPE  : std_logic_vector(2 downto 0) := "101";
    constant E_META    : std_logic_vector(2 downto 0) := "110";

    -- Acciones de movimiento (fsm_nav -> drive_cmd)
    constant A_PARO      : std_logic_vector(2 downto 0) := "000";
    constant A_AVANZA    : std_logic_vector(2 downto 0) := "001";
    constant A_CURVA_IZQ : std_logic_vector(2 downto 0) := "010";
    constant A_CURVA_DER : std_logic_vector(2 downto 0) := "011";
    constant A_GIRO_IZQ  : std_logic_vector(2 downto 0) := "100";
    constant A_GIRO_DER  : std_logic_vector(2 downto 0) := "101";
    constant A_REVERSA   : std_logic_vector(2 downto 0) := "110";
    constant A_BUSCA     : std_logic_vector(2 downto 0) := "111";

    -- Direccion de la luz (ldr_dir -> fsm_nav)
    constant D_NINGUNA    : std_logic_vector(2 downto 0) := "000";
    constant D_FRENTE     : std_logic_vector(2 downto 0) := "001";
    constant D_FRENTE_IZQ : std_logic_vector(2 downto 0) := "010";
    constant D_FRENTE_DER : std_logic_vector(2 downto 0) := "011";
    constant D_IZQ        : std_logic_vector(2 downto 0) := "100";
    constant D_DER        : std_logic_vector(2 downto 0) := "101";
    constant D_ATRAS      : std_logic_vector(2 downto 0) := "110";

    -- Eventos (se ven en HEX4 y salen por UART)
    constant EV_NINGUNO   : std_logic_vector(2 downto 0) := "000";
    constant EV_LUZ       : std_logic_vector(2 downto 0) := "001";
    constant EV_PERDIDA   : std_logic_vector(2 downto 0) := "010";
    constant EV_OBSTACULO : std_logic_vector(2 downto 0) := "011";
    constant EV_ESQUINA   : std_logic_vector(2 downto 0) := "100";
    constant EV_ATASCO    : std_logic_vector(2 downto 0) := "101";
    constant EV_META      : std_logic_vector(2 downto 0) := "110";

    -- Distancia que entrega hcsr04 cuando no hubo eco
    constant DIST_SIN_ECO : natural := 511;

end package robot_pkg;
