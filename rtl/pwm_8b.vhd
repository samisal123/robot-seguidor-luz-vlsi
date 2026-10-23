-- ============================================================
-- pwm_8b.vhd
-- PWM de 8 bits. Un contador de 0 a 255 avanza cada PRESC
-- ciclos de reloj y pwm vale '1' mientras contador < duty:
--   periodo = 256 * PRESC ciclos (51.2 us = 19.53 kHz a 50 MHz)
--   ancho   = duty * PRESC ciclos (duty 0 = apagado,
--             duty 255 = 255/256 del periodo)
-- duty se captura al inicio de cada periodo, asi un cambio a
-- media cuenta no corta ni alarga el pulso en curso.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_8b is
    generic (
        PRESC : positive := 10
    );
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;   -- sincrono, activo en alto
        duty : in  std_logic_vector(7 downto 0);
        pwm  : out std_logic
    );
end entity pwm_8b;

architecture rtl of pwm_8b is
    signal pre      : natural range 0 to PRESC - 1 := 0;
    signal cuenta   : unsigned(7 downto 0) := (others => '0');
    signal duty_reg : unsigned(7 downto 0) := (others => '0');
    signal salida   : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pre      <= 0;
                cuenta   <= (others => '0');
                duty_reg <= (others => '0');
                salida   <= '0';
            else
                if pre = PRESC - 1 then
                    pre    <= 0;
                    cuenta <= cuenta + 1;             -- 255 + 1 = 0
                    if cuenta = 255 then
                        duty_reg <= unsigned(duty);   -- inicia periodo
                    end if;
                else
                    pre <= pre + 1;
                end if;
                if cuenta < duty_reg then
                    salida <= '1';
                else
                    salida <= '0';
                end if;
            end if;
        end if;
    end process;

    pwm <= salida;

end architecture rtl;
