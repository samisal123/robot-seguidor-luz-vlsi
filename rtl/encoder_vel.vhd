-- ============================================================
-- encoder_vel.vhd
-- Mide la velocidad de una rueda como numero de transiciones del
-- encoder en una ventana de VENTANA_MS.
--   UN_CANAL = false: encoder de cuadratura A/B; cuenta cada
--     cambio valido de A o de B (x4). Si A y B cambian en el mismo
--     ciclo la transicion es invalida (ruido) y no se cuenta.
--   UN_CANAL = true: sensor de ranura con disco (solo A); cuenta
--     los dos flancos de A (x2). B se ignora.
-- Solo mide magnitud: el sentido lo sabe drive_cmd.
-- vel satura en 1023. listo da un pulso al cerrar cada ventana.
-- a y b ya deben venir sincronizadas (sync_2ff).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder_vel is
    generic (
        VENTANA_MS : positive := 50;
        UN_CANAL   : boolean  := false
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        a        : in  std_logic;
        b        : in  std_logic;
        vel      : out std_logic_vector(9 downto 0);
        listo    : out std_logic
    );
end entity encoder_vel;

architecture rtl of encoder_vel is
    signal a_ant, b_ant : std_logic := '0';
    signal cuenta : natural range 0 to 1023 := 0;
    signal t_ms   : natural range 0 to VENTANA_MS - 1 := 0;
    signal s_vel  : natural range 0 to 1023 := 0;
    signal s_list : std_logic := '0';
begin

    process (clk)
        variable paso : boolean;
    begin
        if rising_edge(clk) then
            a_ant  <= a;
            b_ant  <= b;
            s_list <= '0';

            if UN_CANAL then
                paso := a /= a_ant;
            else
                paso := (a /= a_ant) xor (b /= b_ant);
            end if;

            if rst = '1' then
                cuenta <= 0;
                t_ms   <= 0;
                s_vel  <= 0;
            elsif tick_1ms = '1' and t_ms = VENTANA_MS - 1 then
                t_ms   <= 0;
                s_vel  <= cuenta;
                s_list <= '1';
                if paso then
                    cuenta <= 1;
                else
                    cuenta <= 0;
                end if;
            else
                if tick_1ms = '1' then
                    t_ms <= t_ms + 1;
                end if;
                if paso and cuenta < 1023 then
                    cuenta <= cuenta + 1;
                end if;
            end if;
        end if;
    end process;

    vel   <= std_logic_vector(to_unsigned(s_vel, 10));
    listo <= s_list;

end architecture rtl;
