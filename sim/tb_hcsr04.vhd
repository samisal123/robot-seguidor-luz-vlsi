-- ============================================================
-- tb_hcsr04.vhd
-- Verifica hcsr04 a 50 MHz con tick_gen real y un modelo del
-- sensor que, tras cada TRIG, espera 450 us (rafaga de
-- ultrasonido) y sube ECHO el tiempo pedido.
--   TRIG dura de 10 a 11 us,
--   eco de 580 us da 10 cm, y otros anchos dan round(t/58),
--   sin eco: timeout, dist_cm = 511, unos 25 ms despues del TRIG,
--   eco que no termina (30 ms): timeout,
--   ECHO ya en alto antes del TRIG (sensor pegado) que baja
--   despues: timeout, no una distancia falsa,
--   start durante una medicion se ignora,
--   valid dura un ciclo y dist_cm se mantiene hasta la siguiente.
-- GHDL: sim/correr.sh hcsr04
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_hcsr04 is
end entity tb_hcsr04;

architecture sim of tb_hcsr04 is
    constant T_CLK : time := 20 ns;
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal t1us    : std_logic;
    signal start   : std_logic := '0';
    signal echo    : std_logic;
    signal trig    : std_logic;
    signal dist_cm : std_logic_vector(8 downto 0);
    signal valid   : std_logic;
    signal tout    : std_logic;
    signal busy    : std_logic;
    signal fin     : boolean := false;

    -- Modelo del sensor
    signal eco_t     : time := 0 ns;     -- 0 = no responde
    signal pegado    : boolean := false; -- ECHO fijo en alto
    signal n_trig    : natural := 0;
    signal fin_trig  : time := 0 ns;
    signal echo_mod  : std_logic := '0';
begin

    clk <= not clk after T_CLK / 2 when not fin;

    ticks : entity work.tick_gen
        port map (clk => clk, rst => rst, tick_1us => t1us, tick_58us => open, tick_1ms => open);

    dut : entity work.hcsr04
        port map (clk => clk, rst => rst, tick_1us => t1us, start => start, echo => echo,
                  trig => trig, dist_cm => dist_cm, valid => valid, timeout => tout, busy => busy);

    sensor : process
        variable t0 : time;
    begin
        wait until trig = '1';
        t0 := now;
        n_trig <= n_trig + 1;
        wait until trig = '0';
        fin_trig <= now;
        assert now - t0 >= 10 us and now - t0 <= 11 us
            report "TRIG de " & time'image(now - t0) severity error;
        if not pegado and eco_t > 0 ns then
            wait for 450 us;
            echo_mod <= '1';
            wait for eco_t;
            echo_mod <= '0';
        end if;
    end process;

    echo <= '1' when pegado else echo_mod;

    -- valid dura un ciclo
    revisa_valid : process (clk)
        variable ant : std_logic := '0';
    begin
        if rising_edge(clk) then
            assert not (valid = '1' and ant = '1') report "valid dura mas de un ciclo" severity error;
            ant := valid;
        end if;
    end process;

    estimulo : process
        procedure disparar is
        begin
            wait until rising_edge(clk);
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
        end procedure;

        procedure medir (t : time; esperado : natural) is
        begin
            eco_t <= t;
            disparar;
            wait until valid = '1' for 30 ms;
            assert valid = '1' report "no hubo valid" severity error;
            assert tout = '0' report "timeout con eco de " & time'image(t) severity error;
            assert to_integer(unsigned(dist_cm)) = esperado
                report "eco de " & time'image(t) & ": " &
                       integer'image(to_integer(unsigned(dist_cm))) & " cm, se esperaban " &
                       integer'image(esperado)
                severity error;
            -- busy baja en el mismo flanco que valid
            assert busy = '0' report "busy sigue activo tras valid" severity error;
            wait for 100 us;
        end procedure;

        variable n0 : natural;
    begin
        wait for 1 us;
        rst <= '0';
        wait for 5 us;
        assert busy = '0' and trig = '0' report "no arranca en reposo" severity error;

        -- Distancias
        medir(580 us, 10);
        medir(1160 us, 20);
        medir(58 us, 1);
        medir(600 us, 10);       -- 10.34
        medir(620 us, 11);       -- 10.69
        medir(5800 us, 100);
        medir(23200 us, 400);

        -- dist_cm se mantiene hasta la siguiente medicion
        wait for 1 ms;
        assert to_integer(unsigned(dist_cm)) = 400 report "dist_cm no se mantuvo" severity error;

        -- Sin eco: timeout a los 25 ms del TRIG
        eco_t <= 0 ns;
        disparar;
        wait until valid = '1' for 30 ms;
        assert valid = '1' and tout = '1' report "sin eco no dio timeout" severity error;
        assert dist_cm = "111111111" report "sin eco no dio 511" severity error;
        assert now - fin_trig >= 24.99 ms and now - fin_trig <= 25.01 ms
            report "timeout a " & time'image(now - fin_trig) & " del TRIG" severity error;
        wait for 100 us;

        -- Una medicion buena borra timeout
        medir(580 us, 10);

        -- Eco que no termina
        eco_t <= 30 ms;
        disparar;
        wait until valid = '1' for 30 ms;
        assert valid = '1' and tout = '1' report "eco largo no dio timeout" severity error;
        wait until echo_mod = '0';
        wait for 100 us;

        -- ECHO ya en alto antes del TRIG que baja a los 5 ms: sin
        -- flanco de subida no hay medicion valida, debe dar timeout
        pegado <= true;
        wait for 10 us;
        eco_t <= 580 us;
        disparar;
        wait for 5 ms;
        pegado <= false;
        wait until valid = '1' for 30 ms;
        assert valid = '1' and tout = '1' report "ECHO pegado no dio timeout" severity error;
        wait for 100 us;

        -- start durante la medicion se ignora
        n0 := n_trig;
        eco_t <= 2000 us;
        disparar;
        wait for 1 ms;
        disparar;
        wait until valid = '1' for 30 ms;
        assert to_integer(unsigned(dist_cm)) = 34 report "medicion alterada por start extra" severity error;
        wait for 30 ms;
        assert n_trig = n0 + 1 report "start durante busy genero otro TRIG" severity error;

        report "tb_hcsr04: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
