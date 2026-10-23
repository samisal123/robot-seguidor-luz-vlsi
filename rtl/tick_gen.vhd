-- ============================================================
-- tick_gen.vhd
-- Pulsos de habilitacion de un ciclo de reloj cada 1 us, 58 us
-- y 1 ms. Todo el diseno usa estos pulsos en lugar de relojes
-- divididos, asi solo existe el dominio de 50 MHz.
--   tick_1us  : cada CLK_HZ/1e6 ciclos (50 a 50 MHz)
--   tick_58us : cada 58 tick_1us (1 cm de eco del HC-SR04)
--   tick_1ms  : cada 1000 tick_1us
-- Los tres salen en el mismo ciclo que el tick_1us que los
-- completa. CLK_HZ debe ser multiplo de 1 MHz.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tick_gen is
    generic (
        CLK_HZ : natural := 50_000_000
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;   -- sincrono, activo en alto
        tick_1us  : out std_logic;
        tick_58us : out std_logic;
        tick_1ms  : out std_logic
    );
end entity tick_gen;

architecture rtl of tick_gen is
    constant CICLOS_US : natural := CLK_HZ / 1_000_000;

    signal pre    : natural range 0 to CICLOS_US - 1 := 0;
    signal cnt58  : natural range 0 to 57  := 0;
    signal cnt1k  : natural range 0 to 999 := 0;
    signal t_us   : std_logic := '0';
    signal t_58us : std_logic := '0';
    signal t_ms   : std_logic := '0';
begin

    assert CLK_HZ mod 1_000_000 = 0 and CLK_HZ >= 2_000_000
        report "tick_gen: CLK_HZ debe ser multiplo de 1 MHz y al menos 2 MHz"
        severity failure;

    process (clk)
    begin
        if rising_edge(clk) then
            t_us   <= '0';
            t_58us <= '0';
            t_ms   <= '0';
            if rst = '1' then
                pre   <= 0;
                cnt58 <= 0;
                cnt1k <= 0;
            elsif pre = CICLOS_US - 1 then
                pre  <= 0;
                t_us <= '1';
                if cnt58 = 57 then
                    cnt58  <= 0;
                    t_58us <= '1';
                else
                    cnt58 <= cnt58 + 1;
                end if;
                if cnt1k = 999 then
                    cnt1k <= 0;
                    t_ms  <= '1';
                else
                    cnt1k <= cnt1k + 1;
                end if;
            else
                pre <= pre + 1;
            end if;
        end if;
    end process;

    tick_1us  <= t_us;
    tick_58us <= t_58us;
    tick_1ms  <= t_ms;

end architecture rtl;
