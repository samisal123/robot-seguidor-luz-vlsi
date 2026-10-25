-- ============================================================
-- ultra_sched.vhd
-- Maneja los 4 HC-SR04 por turnos para que el eco de uno no lo
-- escuche otro: cada TURNO_MS dispara un solo sensor, en orden
-- 0 (frente), 1 (diagonal izq), 2 (diagonal der), 3 (atras).
-- Cada sensor se lee cada 4 * TURNO_MS (120 ms por defecto).
-- Salidas:
--   dist    : 4 distancias de 9 bits, sensor i en (9i+8 .. 9i);
--             511 = sin eco.
--   nuevo   : pulso de un ciclo cuando llega la medicion del
--             sensor i.
--   sin_eco : la ultima medicion del sensor i no tuvo eco.
-- echo ya debe venir sincronizado (sync_2ff) y bajado a 3.3 V.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity ultra_sched is
    generic (
        TURNO_MS   : positive := 30;
        TRIG_US    : positive := 10;
        TIMEOUT_US : positive := 25_000
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1us : in  std_logic;
        tick_1ms : in  std_logic;
        echo     : in  std_logic_vector(3 downto 0);
        trig     : out std_logic_vector(3 downto 0);
        dist     : out std_logic_vector(35 downto 0);
        nuevo    : out std_logic_vector(3 downto 0);
        sin_eco  : out std_logic_vector(3 downto 0)
    );
end entity ultra_sched;

architecture rtl of ultra_sched is
    signal cuenta : natural range 0 to TURNO_MS - 1 := 0;
    signal turno  : natural range 0 to 3 := 0;
    signal start  : std_logic_vector(3 downto 0) := (others => '0');
begin

    assert TIMEOUT_US + TRIG_US + 100 < TURNO_MS * 1000
        report "ultra_sched: el timeout del sensor debe caber en su turno"
        severity failure;

    process (clk)
    begin
        if rising_edge(clk) then
            start <= (others => '0');
            if rst = '1' then
                cuenta <= 0;
                turno  <= 0;
            elsif tick_1ms = '1' then
                if cuenta = TURNO_MS - 1 then
                    cuenta       <= 0;
                    start(turno) <= '1';
                    if turno = 3 then
                        turno <= 0;
                    else
                        turno <= turno + 1;
                    end if;
                else
                    cuenta <= cuenta + 1;
                end if;
            end if;
        end if;
    end process;

    sensores : for i in 0 to 3 generate
        u_hc : entity work.hcsr04
            generic map (TRIG_US => TRIG_US, TIMEOUT_US => TIMEOUT_US)
            port map (
                clk      => clk,
                rst      => rst,
                tick_1us => tick_1us,
                start    => start(i),
                echo     => echo(i),
                trig     => trig(i),
                dist_cm  => dist(9 * i + 8 downto 9 * i),
                valid    => nuevo(i),
                timeout  => sin_eco(i),
                busy     => open
            );
    end generate;

end architecture rtl;
