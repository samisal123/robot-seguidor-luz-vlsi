-- ============================================================
-- tb_telemetria.vhd
-- CLK_HZ = 1 MHz, BAUD = 100000 (10 ciclos por bit), tick_1ms
-- cada 1000 ciclos y PERIODO_MS = 10. Un receptor UART en el
-- testbench junta los caracteres y compara la linea completa:
--   "E2 V1 F045 I120 D--- A033 L1010 C0 P66 66 S012 013" & CR & LF
-- Despues revisa que un evento dispare una linea extra antes del
-- siguiente periodo y que la linea refleje los datos nuevos.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_telemetria is
end entity tb_telemetria;

architecture sim of tb_telemetria is
    constant T_CLK : time := 1 us;
    constant T_BIT : time := 10 us;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal ev_nuevo : std_logic := '0';
    signal estado   : std_logic_vector(2 downto 0) := "010";
    signal evento   : std_logic_vector(2 downto 0) := "001";
    signal dist     : std_logic_vector(35 downto 0);
    signal luz      : std_logic_vector(3 downto 0) := "0101";   -- frente y derecha
    signal cerca    : std_logic := '0';
    signal duty_l   : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(170, 8));
    signal duty_r   : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(170, 8));
    signal vel_l    : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(12, 10));
    signal vel_r    : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(13, 10));
    signal tx       : std_logic;
    signal fin      : boolean := false;

    signal linea    : string(1 to 64) := (others => ' ');
    signal largo    : natural := 0;
    signal n_lineas : natural := 0;

    constant CR : character := character'val(13);
    constant LF : character := character'val(10);
    constant ESPERADA1 : string := "E2 V1 F045 I120 D--- A033 L1010 C0 P66 66 S012 013" & CR & LF;
    constant ESPERADA2 : string := "E3 V3 F012 I120 D--- A033 L1010 C1 P00 99 S510 000" & CR & LF;

    function dist4 (a, b, c, d : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(d, 9)) & std_logic_vector(to_unsigned(c, 9)) &
               std_logic_vector(to_unsigned(b, 9)) & std_logic_vector(to_unsigned(a, 9));
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
        variable n : natural := 0;
    begin
        if rising_edge(clk) then
            if n = 999 then
                n := 0;
                tick_1ms <= '1';
            else
                n := n + 1;
                tick_1ms <= '0';
            end if;
        end if;
    end process;

    dist <= dist4(45, 120, 511, 33) when estado = "010" else dist4(12, 120, 511, 33);

    dut : entity work.telemetria
        generic map (CLK_HZ => 1_000_000, BAUD => 100_000, PERIODO_MS => 10)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, ev_nuevo => ev_nuevo,
                  estado => estado, evento => evento, dist => dist, luz => luz,
                  cerca => cerca, duty_l => duty_l, duty_r => duty_r,
                  vel_l => vel_l, vel_r => vel_r, tx => tx);

    -- Receptor UART: arma la linea hasta el LF
    receptor : process
        variable r : std_logic_vector(7 downto 0);
        variable c : character;
        variable n : natural := 0;
    begin
        wait until falling_edge(tx);
        wait for T_BIT / 2;
        for i in 0 to 7 loop
            wait for T_BIT;
            r(i) := tx;
        end loop;
        wait for T_BIT;
        assert tx = '1' report "Falta el stop bit" severity error;
        c := character'val(to_integer(unsigned(r)));
        n := n + 1;
        linea(n) <= c;
        if c = LF then
            largo    <= n;
            n_lineas <= n_lineas + 1;
            n := 0;
        end if;
    end process;

    estimulo : process
        variable t0 : time;
    begin
        wait for 3 * T_CLK;
        rst <= '0';

        -- Primera linea periodica
        wait until n_lineas = 1;
        wait for T_CLK;
        assert largo = ESPERADA1'length
            report "Largo de linea " & integer'image(largo) severity error;
        assert linea(1 to ESPERADA1'length) = ESPERADA1
            report "Linea 1: [" & linea(1 to largo - 2) & "]" severity error;

        -- Evento: linea extra antes del siguiente periodo, con datos nuevos
        wait for 2 ms;
        estado <= "011";
        evento <= "011";
        cerca  <= '1';
        duty_l <= (others => '0');
        duty_r <= (others => '1');
        vel_l  <= (others => '1');      -- 1023 se muestra como 510
        vel_r  <= (others => '0');
        t0 := now;
        wait until rising_edge(clk);
        ev_nuevo <= '1';
        wait until rising_edge(clk);
        ev_nuevo <= '0';
        wait until n_lineas = 2;
        assert now - t0 < 6 ms report "La linea del evento tardo demasiado" severity error;
        wait for T_CLK;
        assert linea(1 to ESPERADA2'length) = ESPERADA2
            report "Linea 2: [" & linea(1 to largo - 2) & "]" severity error;

        report "tb_telemetria: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
