-- ============================================================
-- uart_tx.vhd
-- Transmisor UART 8N1 (1 start, 8 datos LSB primero, sin
-- paridad, 1 stop). Cada bit dura CLK_HZ / BAUD ciclos.
-- Un pulso en enviar con ocupado = '0' carga dato y empieza a
-- transmitir; ocupado vale '1' desde el ciclo siguiente hasta que
-- termina el bit de stop. tx queda en '1' en reposo.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        CLK_HZ : positive := 50_000_000;
        BAUD   : positive := 115_200
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;   -- sincrono, activo en alto
        dato    : in  std_logic_vector(7 downto 0);
        enviar  : in  std_logic;
        tx      : out std_logic;
        ocupado : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is
    constant CICLOS_BIT : positive := CLK_HZ / BAUD;
    signal reg    : std_logic_vector(9 downto 0) := (others => '1');
    signal bits   : natural range 0 to 10 := 0;   -- bits que faltan
    signal cuenta : natural range 0 to CICLOS_BIT - 1 := 0;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg    <= (others => '1');
                bits   <= 0;
                cuenta <= 0;
            elsif bits = 0 then
                if enviar = '1' then
                    reg    <= '1' & dato & '0';   -- stop, datos, start
                    bits   <= 10;
                    cuenta <= 0;
                end if;
            elsif cuenta = CICLOS_BIT - 1 then
                cuenta <= 0;
                reg    <= '1' & reg(9 downto 1);
                bits   <= bits - 1;
            else
                cuenta <= cuenta + 1;
            end if;
        end if;
    end process;

    tx      <= reg(0) when bits /= 0 else '1';
    ocupado <= '0' when bits = 0 else '1';

end architecture rtl;
