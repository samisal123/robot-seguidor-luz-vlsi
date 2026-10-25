-- ============================================================
-- tb_stall_detect.vhd
-- N_MS = 50 y DELTA_CM = 3, con tick_1ms cada 2 ciclos.
--   1. Moviendose con distancias fijas: atasco a los 50 ms.
--   2. Moviendose y acercandose a una pared: nunca hay atasco.
--   3. Lecturas a +-DELTA_CM de la referencia no cuentan como
--      avance (el atasco llega a tiempo); DELTA_CM + 1 si cuenta.
--   4. Lecturas que alternan entre sin eco y 100 cm no cuentan
--      como avance.
--   5. Con moviendo = '0' nunca hay atasco.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_stall_detect is
end entity tb_stall_detect;

architecture sim of tb_stall_detect is
    constant T_CLK : time := 10 ns;
    constant T_MS  : time := 2 * T_CLK;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1ms : std_logic := '0';
    signal moviendo : std_logic := '0';
    signal dist     : std_logic_vector(35 downto 0) := (others => '0');
    signal nuevo    : std_logic_vector(3 downto 0) := "0000";
    signal atasco   : std_logic;
    signal n_atasco : natural := 0;
    signal fin      : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            tick_1ms <= not tick_1ms;
            if atasco = '1' then
                n_atasco <= n_atasco + 1;
            end if;
        end if;
    end process;

    dut : entity work.stall_detect
        generic map (N_MS => 50, DELTA_CM => 3)
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, moviendo => moviendo,
                  dist => dist, nuevo => nuevo, atasco => atasco);

    estimulo : process
        -- Nueva medicion del sensor i
        procedure mide (i : natural; cm : natural) is
        begin
            wait until rising_edge(clk);
            dist(9 * i + 8 downto 9 * i) <= std_logic_vector(to_unsigned(cm, 9));
            nuevo(i) <= '1';
            wait until rising_edge(clk);
            nuevo(i) <= '0';
        end procedure;

        procedure todas (cm : natural) is
        begin
            for i in 0 to 3 loop
                dist(9 * i + 8 downto 9 * i) <= std_logic_vector(to_unsigned(cm, 9));
            end loop;
        end procedure;

        variable n0 : natural;
        variable t0 : time;
    begin
        todas(100);
        wait for 3 * T_CLK;
        rst <= '0';
        wait for 5 * T_CLK;

        -- 1. distancias fijas
        n0 := n_atasco;
        moviendo <= '1';
        t0 := now;
        for k in 1 to 10 loop
            mide(k mod 4, 100);
            wait for 2 * T_MS;
        end loop;
        wait until atasco = '1' for 100 * T_MS;
        assert atasco = '1' report "No detecto atasco con distancias fijas" severity error;
        assert now - t0 >= 49 * T_MS and now - t0 <= 52 * T_MS
            report "Atasco a destiempo: " & time'image(now - t0) severity error;
        moviendo <= '0';
        wait for 10 * T_MS;

        -- 2. acercandose: 5 cm cada 10 ms
        n0 := n_atasco;
        todas(200);
        wait for 2 * T_CLK;
        moviendo <= '1';
        for k in 1 to 30 loop
            wait for 10 * T_MS;
            mide(0, 200 - 5 * k);
        end loop;
        assert n_atasco = n0 report "Atasco falso mientras avanza" severity error;
        moviendo <= '0';
        wait for 10 * T_MS;

        -- 3. lecturas a +-DELTA_CM de la referencia nunca cuentan como
        --    avance: el atasco llega justo a los N_MS
        todas(100);
        wait for 2 * T_CLK;
        moviendo <= '1';
        t0 := now;
        for k in 1 to 8 loop       -- 8 lecturas en 48 ms, antes del atasco
            wait for 5 * T_MS;
            case k mod 4 is
                when 1      => mide(0, 103);
                when 3      => mide(0, 97);
                when others => mide(0, 100);
            end case;
        end loop;
        wait until atasco = '1' for 20 * T_MS;
        assert atasco = '1' and now - t0 >= 49 * T_MS and now - t0 <= 52 * T_MS
            report "Un cambio de DELTA_CM no debe contar como avance (atasco a " &
                   time'image(now - t0) & ")" severity error;
        moviendo <= '0';
        wait for 10 * T_MS;

        -- 3b. cambios de DELTA_CM + 1 si cuentan: nunca hay atasco
        todas(100);
        wait for 2 * T_CLK;
        n0 := n_atasco;
        moviendo <= '1';
        for k in 1 to 8 loop
            wait for 10 * T_MS;
            if k mod 2 = 1 then mide(0, 104); else mide(0, 100); end if;
        end loop;
        assert n_atasco = n0 report "Un cambio de DELTA_CM + 1 si es avance" severity error;
        moviendo <= '0';
        wait for 10 * T_MS;

        -- 4. eco intermitente
        todas(100);
        wait for 2 * T_CLK;
        n0 := n_atasco;
        moviendo <= '1';
        for k in 1 to 8 loop
            wait for 10 * T_MS;
            if k mod 2 = 1 then mide(0, 511); else mide(0, 100); end if;
        end loop;
        assert n_atasco = n0 + 1 report "Un eco intermitente no debe contar como avance" severity error;
        moviendo <= '0';

        -- 5. parado
        n0 := n_atasco;
        wait for 200 * T_MS;
        assert n_atasco = n0 report "Atasco con el robot parado" severity error;

        report "tb_stall_detect: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
