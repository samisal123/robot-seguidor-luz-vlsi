-- ============================================================
-- stall_detect.vhd
-- Detecta atasco: la FSM ordena moverse (moviendo = '1') pero
-- durante N_MS ninguna distancia cambia mas de DELTA_CM.
-- Por cada sensor guarda una referencia. Cuando llega una
-- medicion nueva (nuevo(i)):
--   - si la referencia o la medicion son "sin eco" (511), solo
--     actualiza la referencia: un eco que aparece y desaparece
--     no prueba que el robot avance;
--   - si ambas son validas y difieren mas de DELTA_CM, hubo
--     avance: reinicia el tiempo y actualiza la referencia.
-- Si el tiempo llega a N_MS, da un pulso en atasco y vuelve a
-- empezar. Con moviendo = '0' el tiempo se queda en cero, y al
-- volver a '1' todas las referencias se toman de nuevo.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity stall_detect is
    generic (
        N_MS     : positive := 3000;
        DELTA_CM : natural  := 3
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        moviendo : in  std_logic;
        dist     : in  std_logic_vector(35 downto 0);
        nuevo    : in  std_logic_vector(3 downto 0);
        atasco   : out std_logic
    );
end entity stall_detect;

architecture rtl of stall_detect is
    type t_ref is array (0 to 3) of natural range 0 to 511;
    signal ref      : t_ref := (others => DIST_SIN_ECO);
    signal tiempo   : natural range 0 to N_MS - 1 := 0;
    signal mov_ant  : std_logic := '0';
    signal s_atasco : std_logic := '0';

    function d (v : std_logic_vector(35 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(9 * i + 8 downto 9 * i)));
    end function;
begin

    process (clk)
        variable avance : boolean;
        variable a, b   : natural range 0 to 511;
    begin
        if rising_edge(clk) then
            s_atasco <= '0';
            mov_ant  <= moviendo;
            if rst = '1' then
                tiempo <= 0;
                ref    <= (others => DIST_SIN_ECO);
            elsif moviendo = '0' then
                tiempo <= 0;
            elsif mov_ant = '0' then
                -- empieza a moverse: nueva ventana con las distancias actuales
                tiempo <= 0;
                for i in 0 to 3 loop
                    ref(i) <= d(dist, i);
                end loop;
            else
                avance := false;
                for i in 0 to 3 loop
                    if nuevo(i) = '1' then
                        a := ref(i);
                        b := d(dist, i);
                        if a = DIST_SIN_ECO or b = DIST_SIN_ECO then
                            ref(i) <= b;
                        elsif (a > b and a - b > DELTA_CM) or
                              (b > a and b - a > DELTA_CM) then
                            ref(i) <= b;
                            avance := true;
                        end if;
                    end if;
                end loop;
                if avance then
                    tiempo <= 0;
                elsif tick_1ms = '1' then
                    if tiempo = N_MS - 1 then
                        tiempo   <= 0;
                        s_atasco <= '1';
                    else
                        tiempo <= tiempo + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    atasco <= s_atasco;

end architecture rtl;
