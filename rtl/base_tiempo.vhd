-- ============================================================
-- base_tiempo.vhd
-- Pulsos de habilitacion de un ciclo de reloj:
--   tick_fs  : uno cada FS_DIV ciclos (synth_pkg), la frecuencia
--              de muestreo del audio: 50 MHz / 1024 = 48 828 Hz
--   tick_1ms : uno cada CLK_HZ / 1000 ciclos
-- Todo el diseno usa estos pulsos como habilitacion en lugar de
-- relojes divididos, asi solo existe el dominio de 50 MHz.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.synth_pkg.all;

entity base_tiempo is
    generic (
        CLK_HZ : natural := 50_000_000
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_fs  : out std_logic;
        tick_1ms : out std_logic
    );
end entity base_tiempo;

architecture rtl of base_tiempo is
    constant CICLOS_MS : natural := CLK_HZ / 1000;

    signal c_fs : natural range 0 to FS_DIV - 1 := 0;
    signal c_ms : natural range 0 to CICLOS_MS - 1 := 0;
    signal t_fs : std_logic := '0';
    signal t_ms : std_logic := '0';
begin

    assert CLK_HZ mod 1000 = 0 and CLK_HZ >= 2000
        report "base_tiempo: CLK_HZ debe ser multiplo de 1 kHz"
        severity failure;

    process (clk)
    begin
        if rising_edge(clk) then
            t_fs <= '0';
            t_ms <= '0';
            if rst = '1' then
                c_fs <= 0;
                c_ms <= 0;
            else
                if c_fs = FS_DIV - 1 then
                    c_fs <= 0;
                    t_fs <= '1';
                else
                    c_fs <= c_fs + 1;
                end if;
                if c_ms = CICLOS_MS - 1 then
                    c_ms <= 0;
                    t_ms <= '1';
                else
                    c_ms <= c_ms + 1;
                end if;
            end if;
        end if;
    end process;

    tick_fs  <= t_fs;
    tick_1ms <= t_ms;

end architecture rtl;
