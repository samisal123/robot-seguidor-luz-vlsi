-- ============================================================
-- motor_if.vhd
-- Interfaz de una rueda con el driver (TB6612FNG o L298N):
--   adelante: IN1 = 1, IN2 = 0, EN = pwm
--   atras   : IN1 = 0, IN2 = 1, EN = pwm
--   pausa   : IN1 = 0, IN2 = 0, EN = 0 (motor libre)
-- Cuando dir cambia, el motor pasa por la pausa durante PAUSA_MS
-- ticks de 1 ms (entre PAUSA_MS-1 y PAUSA_MS ms) antes de tomar
-- la direccion nueva. Asi no se invierte el giro de golpe, que
-- produce picos de corriente en el driver.
-- Las salidas van registradas: EN sigue a pwm con un ciclo de
-- retraso.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity motor_if is
    generic (
        PAUSA_MS : positive := 50
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        dir      : in  std_logic;   -- '1' adelante, '0' atras
        pwm      : in  std_logic;
        in1      : out std_logic;
        in2      : out std_logic;
        en       : out std_logic
    );
end entity motor_if;

architecture rtl of motor_if is
    signal dir_act : std_logic := '1';
    signal pausa   : std_logic := '0';
    signal cuenta  : natural range 0 to PAUSA_MS - 1 := 0;
    signal s_in1   : std_logic := '0';
    signal s_in2   : std_logic := '0';
    signal s_en    : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dir_act <= dir;             -- al arrancar no hay pausa
                pausa   <= '0';
                cuenta  <= 0;
            elsif pausa = '1' then
                if tick_1ms = '1' then
                    if cuenta = PAUSA_MS - 1 then
                        pausa   <= '0';
                        cuenta  <= 0;
                        dir_act <= dir;
                    else
                        cuenta <= cuenta + 1;
                    end if;
                end if;
            elsif dir /= dir_act then
                pausa  <= '1';
                cuenta <= 0;
            end if;

            if rst = '1' or pausa = '1' then
                s_in1 <= '0';
                s_in2 <= '0';
                s_en  <= '0';
            else
                s_in1 <= dir_act;
                s_in2 <= not dir_act;
                s_en  <= pwm;
            end if;
        end if;
    end process;

    in1 <= s_in1;
    in2 <= s_in2;
    en  <= s_en;

end architecture rtl;
