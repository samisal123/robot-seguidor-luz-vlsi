-- ============================================================
-- tb_uart_tx.vhd
-- CLK_HZ = 1 MHz y BAUD = 100000 (10 ciclos por bit).
-- Manda 0x4B y 0xA5 y los recibe muestreando a mitad de bit:
-- start en 0, datos LSB primero, stop en 1, duracion exacta.
-- Un pulso de enviar con el transmisor ocupado se ignora.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture sim of tb_uart_tx is
    constant T_CLK : time := 1 us;
    constant T_BIT : time := 10 us;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal dato    : std_logic_vector(7 downto 0) := (others => '0');
    signal enviar  : std_logic := '0';
    signal tx      : std_logic;
    signal ocupado : std_logic;
    signal fin     : boolean := false;

    type t_bytes is array (0 to 7) of std_logic_vector(7 downto 0);
    signal rx_buf  : t_bytes := (others => (others => '0'));
    signal rx_cnt  : natural := 0;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.uart_tx
        generic map (CLK_HZ => 1_000_000, BAUD => 100_000)
        port map (clk => clk, rst => rst, dato => dato, enviar => enviar,
                  tx => tx, ocupado => ocupado);

    -- Receptor: muestrea cada bit a la mitad
    receptor : process
        variable r : std_logic_vector(7 downto 0);
    begin
        wait until falling_edge(tx);
        wait for T_BIT / 2;
        assert tx = '0' report "Start bit corto" severity error;
        for i in 0 to 7 loop
            wait for T_BIT;
            r(i) := tx;
        end loop;
        wait for T_BIT;
        assert tx = '1' report "Falta el stop bit" severity error;
        rx_buf(rx_cnt) <= r;
        rx_cnt <= rx_cnt + 1;
    end process;

    estimulo : process
        variable t0 : time;

        procedure manda (d : std_logic_vector(7 downto 0)) is
        begin
            wait until rising_edge(clk);
            dato   <= d;
            enviar <= '1';
            wait until rising_edge(clk);
            enviar <= '0';
        end procedure;
    begin
        wait for 3 * T_CLK;
        rst <= '0';
        wait for T_CLK;
        assert tx = '1' and ocupado = '0' report "Reposo incorrecto" severity error;

        manda(x"4B");
        t0 := now;
        -- intento de envio con el transmisor ocupado: se ignora
        wait for 3 * T_BIT;
        manda(x"FF");
        wait until ocupado = '0';
        assert now - t0 >= 10 * T_BIT - 2 * T_CLK and now - t0 <= 10 * T_BIT + 2 * T_CLK
            report "Duracion de la trama incorrecta: " & time'image(now - t0) severity error;
        wait for T_BIT;
        assert rx_cnt = 1 and rx_buf(0) = x"4B" report "Primer byte incorrecto" severity error;

        manda(x"A5");
        wait until ocupado = '0';
        wait for 3 * T_BIT;
        assert rx_cnt = 2 and rx_buf(1) = x"A5"
            report "Segundo byte incorrecto (o se envio el que debia ignorarse)" severity error;
        assert tx = '1' report "tx deberia quedar en 1" severity error;

        report "tb_uart_tx: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
