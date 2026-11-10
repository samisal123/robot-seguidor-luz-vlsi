-- ============================================================
-- salida_pwm.vhd
-- DAC de 1 bit: PWM de 8 bits a 25 MHz / 256 = 97.7 kHz.
-- El filtro RC de la tarjeta de audio quita la portadora y deja la
-- senal de audio (Fs = 48.8 kHz, 2 periodos de PWM por muestra).
--   duty = muestra + 128   (muestra con signo -128..127 -> 0..255)
--   pwm = '1' los primeros duty ciclos de cada periodo de 256
-- El duty nuevo se toma solo al final de cada periodo (cuenta =
-- 255), para que ningun periodo quede con un ancho intermedio.
-- La salida sale de un registro (sin glitches). Despues del
-- reset el duty es 128 (silencio).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity salida_pwm is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;   -- sincrono, activo en alto
        muestra : in  std_logic_vector(7 downto 0);   -- con signo
        pwm     : out std_logic
    );
end entity salida_pwm;

architecture rtl of salida_pwm is
    signal cuenta   : unsigned(7 downto 0) := (others => '0');
    signal duty_reg : unsigned(7 downto 0) := to_unsigned(128, 8);
    signal s_pwm    : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cuenta   <= (others => '0');
                duty_reg <= to_unsigned(128, 8);
                s_pwm    <= '0';
            else
                cuenta <= cuenta + 1;               -- de 255 regresa a 0
                if cuenta = 255 then
                    duty_reg <= unsigned(muestra) + 128;
                end if;
                if cuenta < duty_reg then
                    s_pwm <= '1';
                else
                    s_pwm <= '0';
                end if;
            end if;
        end if;
    end process;

    pwm <= s_pwm;

end architecture rtl;
