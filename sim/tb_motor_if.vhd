-- ============================================================
-- tb_motor_if.vhd
-- Verifica motor_if (PAUSA_MS = 20) con tick_gen real a 2 MHz:
--   adelante y atras ponen IN1/IN2 correctos y EN sigue a pwm
--   con un ciclo de retraso,
--   al invertir dir hay pausa (IN1 = IN2 = EN = 0) de 19 a 20 ms
--   aunque pwm siga conmutando,
--   un regreso de dir durante la pausa termina en la direccion
--   original, tambien despues de la pausa,
--   nunca IN1 = IN2 = 1 y nunca se invierte sin pausa completa
--   (monitor continuo).
-- GHDL: sim/correr.sh motor_if
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_motor_if is
end entity tb_motor_if;

architecture sim of tb_motor_if is
    constant CLK_HZ   : natural := 2_000_000;
    constant T_CLK    : time    := 500 ns;
    constant PAUSA_MS : natural := 20;
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';
    signal t1ms : std_logic;
    signal dir  : std_logic := '1';
    signal pwm  : std_logic := '0';
    signal in1, in2, en : std_logic;
    signal fin  : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    -- pwm de prueba: conmuta cada 7 ciclos
    pwm_prueba : process (clk)
        variable c : natural := 0;
    begin
        if rising_edge(clk) then
            c := (c + 1) mod 7;
            if c = 0 then
                pwm <= not pwm;
            end if;
        end if;
    end process;

    ticks : entity work.tick_gen
        generic map (CLK_HZ => CLK_HZ)
        port map (clk => clk, rst => rst, tick_1us => open, tick_58us => open, tick_1ms => t1ms);

    dut : entity work.motor_if
        generic map (PAUSA_MS => PAUSA_MS)
        port map (clk => clk, rst => rst, tick_1ms => t1ms, dir => dir, pwm => pwm,
                  in1 => in1, in2 => in2, en => en);

    -- Monitor: combinaciones validas, EN solo con direccion y
    -- pausa completa antes de cada inversion
    monitor : process (clk)
        variable ultima    : std_logic_vector(1 downto 0) := "00";  -- ultima direccion
        variable ini_pausa : time := 0 ns;
        variable pwm_prev  : std_logic := '0';
    begin
        if rising_edge(clk) and rst = '0' then
            assert not (in1 = '1' and in2 = '1') report "IN1 = IN2 = 1" severity error;
            if in1 = '0' and in2 = '0' then
                assert en = '0' report "EN activo durante la pausa" severity error;
                if ultima /= "00" and ini_pausa = 0 ns then
                    ini_pausa := now;
                end if;
            else
                assert en = pwm_prev report "EN no sigue a pwm" severity error;
                if ultima /= "00" and (in1 & in2) /= ultima then
                    assert ini_pausa > 0 ns and now - ini_pausa >= (PAUSA_MS - 1) * 1 ms
                        report "se invirtio el giro sin pausa completa" severity error;
                end if;
                ultima    := in1 & in2;
                ini_pausa := 0 ns;
            end if;
            pwm_prev := pwm;
        end if;
    end process;

    estimulo : process
        variable t0 : time;
    begin
        wait for 10 us;
        wait until rising_edge(clk);
        rst <= '0';

        -- Adelante tras reset, sin pausa
        wait for 5 us;
        assert in1 = '1' and in2 = '0' report "no arranca adelante" severity error;
        wait for 2 ms;

        -- Invertir: pausa de 19 a 20 ms y luego atras
        wait until rising_edge(clk);
        dir <= '0';
        t0 := now;
        wait for 2 * T_CLK + 1 ns;
        assert in1 = '0' and in2 = '0' and en = '0' report "no entro a la pausa" severity error;
        wait until in2 = '1' for 25 ms;
        assert in1 = '0' and in2 = '1' report "no paso a atras" severity error;
        assert now - t0 >= (PAUSA_MS - 1) * 1 ms and now - t0 <= PAUSA_MS * 1 ms + 4 * T_CLK
            report "pausa fuera de 19 a 20 ms" severity error;
        wait for 2 ms;

        -- dir regresa a mitad de la pausa: termina atras, como estaba
        dir <= '1';
        wait for 5 ms;
        dir <= '0';
        wait for 20 ms;
        assert in1 = '0' and in2 = '1' report "no regreso a atras" severity error;

        -- Atras a adelante
        dir <= '1';
        wait for 25 ms;
        assert in1 = '1' and in2 = '0' report "no paso a adelante" severity error;

        -- Varias inversiones seguidas: el monitor revisa cada pausa
        for i in 1 to 4 loop
            dir <= not dir;
            wait for 7 ms;
        end loop;
        wait for 30 ms;
        assert in1 = dir and in2 = not dir report "no se estabilizo" severity error;

        -- rst apaga todo
        wait until rising_edge(clk);
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        assert in1 = '0' and in2 = '0' and en = '0' report "rst no apago las salidas" severity error;

        report "tb_motor_if: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
