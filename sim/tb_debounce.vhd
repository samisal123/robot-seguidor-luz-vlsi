-- ============================================================
-- tb_debounce.vhd
-- Verifica debounce (N_MS = 20) con tick_gen real a 2 MHz, de
-- modo que los tiempos son milisegundos reales:
--   arranca en INIT,
--   rebotes de 2 ms no pasan,
--   un pulso de 15 ms no pasa,
--   un nivel estable pasa entre 19 y 20 ms despues del ultimo
--   rebote, con un solo pulso rise o fall,
--   rst regresa clean a INIT.
-- GHDL: sim/correr.sh debounce
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_debounce is
end entity tb_debounce;

architecture sim of tb_debounce is
    constant CLK_HZ : natural := 2_000_000;
    constant T_CLK  : time    := 500 ns;
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal t1ms  : std_logic;
    signal raw   : std_logic := '0';
    signal clean : std_logic;
    signal rise  : std_logic;
    signal fall  : std_logic;
    signal n_rise, n_fall : natural := 0;
    signal fin   : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    ticks : entity work.tick_gen
        generic map (CLK_HZ => CLK_HZ)
        port map (clk => clk, rst => rst, tick_1us => open, tick_58us => open, tick_1ms => t1ms);

    dut : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => t1ms, raw => raw,
                  clean => clean, rise => rise, fall => fall);

    -- Cuenta pulsos y revisa que cada uno dure un ciclo y vaya con clean
    cuenta_pulsos : process (clk)
        variable rise_prev, fall_prev : std_logic := '0';
    begin
        if rising_edge(clk) then
            if rise = '1' then
                n_rise <= n_rise + 1;
                assert rise_prev = '0' report "rise dura mas de un ciclo" severity error;
                assert clean = '1' report "rise sin clean en 1" severity error;
            end if;
            if fall = '1' then
                n_fall <= n_fall + 1;
                assert fall_prev = '0' report "fall dura mas de un ciclo" severity error;
                assert clean = '0' report "fall sin clean en 0" severity error;
            end if;
            rise_prev := rise;
            fall_prev := fall;
        end if;
    end process;

    estimulo : process
        variable t0 : time;

        -- n rebotes de 'ancho' cada uno; regresa justo en el ultimo
        -- flanco, cuando raw queda en 'final'
        procedure rebotes (n : natural; ancho : time; final : std_logic) is
        begin
            for i in 1 to n loop
                raw <= not final;
                wait for ancho;
                raw <= final;
                if i < n then
                    wait for ancho;
                end if;
            end loop;
        end procedure;
    begin
        wait for 10 us;
        rst <= '0';
        wait for 1 us;
        assert clean = '0' report "clean no arranca en INIT" severity error;

        -- 1) Rebotes de 2 ms alrededor de '0' durante 40 ms: no pasan
        rebotes(10, 2 ms, '0');
        wait for 25 ms;
        assert clean = '0' and n_rise = 0 report "rebotes de 2 ms pasaron" severity error;

        -- 2) Pulso de 15 ms: no pasa
        raw <= '1';
        wait for 15 ms;
        raw <= '0';
        wait for 25 ms;
        assert clean = '0' and n_rise = 0 report "pulso de 15 ms paso" severity error;

        -- 3) Presion con rebotes y luego estable en '1'
        rebotes(5, 2 ms, '1');
        t0 := now;                        -- ultimo flanco de raw
        wait until clean = '1' for 30 ms;
        assert clean = '1' report "nivel estable no paso" severity error;
        assert now - t0 >= 19 ms and now - t0 <= 20 ms + T_CLK
            report "clean subio fuera de la ventana de 19 a 20 ms" severity error;
        wait for 30 ms;
        assert n_rise = 1 and n_fall = 0 report "se esperaba un solo rise" severity error;

        -- 4) Soltar con rebotes: baja una sola vez
        rebotes(5, 2 ms, '0');
        t0 := now;
        wait until clean = '0' for 30 ms;
        assert clean = '0' report "soltar no paso" severity error;
        assert now - t0 >= 19 ms and now - t0 <= 20 ms + T_CLK
            report "clean bajo fuera de la ventana de 19 a 20 ms" severity error;
        wait for 30 ms;
        assert n_rise = 1 and n_fall = 1 report "se esperaba un solo fall" severity error;

        -- 5) rst regresa a INIT
        raw <= '1';
        wait for 30 ms;
        assert clean = '1' report "no subio antes del rst" severity error;
        wait until rising_edge(clk);
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        assert clean = '0' report "rst no regreso clean a INIT" severity error;

        report "tb_debounce: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
