-- ============================================================
-- obst_eval.vhd
-- Convierte las 4 distancias en banderas de obstaculo con
-- histeresis, para que una lectura que oscila alrededor del
-- umbral no haga titubear a la FSM:
--   la bandera sube cuando dist <  UMBRAL
--   y baja cuando       dist >= UMBRAL + HIST_CM.
-- Sin eco (511) cuenta como libre.
-- lado_libre compara las diagonales: '1' si la derecha esta mas
-- libre que la izquierda, '0' en otro caso.
-- Indices: 0 frente, 1 diagonal izq, 2 diagonal der, 3 atras.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity obst_eval is
    generic (
        UMBRAL_F_CM : natural := 25;
        UMBRAL_D_CM : natural := 18;
        UMBRAL_A_CM : natural := 12;
        HIST_CM     : natural := 5
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        dist       : in  std_logic_vector(35 downto 0);
        obs        : out std_logic_vector(3 downto 0);
        lado_libre : out std_logic
    );
end entity obst_eval;

architecture rtl of obst_eval is
    type t_umbral is array (0 to 3) of natural;
    constant UMBRAL : t_umbral := (UMBRAL_F_CM, UMBRAL_D_CM, UMBRAL_D_CM, UMBRAL_A_CM);

    signal s_obs  : std_logic_vector(3 downto 0) := (others => '0');
    signal s_lado : std_logic := '0';

    function d (v : std_logic_vector(35 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(9 * i + 8 downto 9 * i)));
    end function;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_obs  <= (others => '0');
                s_lado <= '0';
            else
                for i in 0 to 3 loop
                    if s_obs(i) = '0' and d(dist, i) < UMBRAL(i) then
                        s_obs(i) <= '1';
                    elsif s_obs(i) = '1' and d(dist, i) >= UMBRAL(i) + HIST_CM then
                        s_obs(i) <= '0';
                    end if;
                end loop;
                if d(dist, S_DIAG_DER) > d(dist, S_DIAG_IZQ) then
                    s_lado <= '1';
                else
                    s_lado <= '0';
                end if;
            end if;
        end if;
    end process;

    obs        <= s_obs;
    lado_libre <= s_lado;

end architecture rtl;
