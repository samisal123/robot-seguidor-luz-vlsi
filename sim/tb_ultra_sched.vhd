-- ============================================================
-- tb_ultra_sched.vhd
-- Cuatro modelos de HC-SR04 responden a su TRIG con un eco de
-- 58 us por cm (10, 50 y 123 cm; el sensor 3 nunca responde).
-- Verifica:
--   - orden de disparo 0, 1, 2, 3, 0 y separacion de TURNO_MS
--   - nunca hay dos TRIG en alto al mismo tiempo
--   - distancias, pulsos nuevo y bandera sin_eco
-- Reloj de 2 MHz para que la simulacion sea corta.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ultra_sched is
end entity tb_ultra_sched;

architecture sim of tb_ultra_sched is
    constant CLK_HZ : natural := 2_000_000;
    constant T_CLK  : time    := 500 ns;
    constant TURNO  : natural := 30;

    type t_int4 is array (0 to 3) of integer;
    constant DIST_MODELO : t_int4 := (10, 50, 123, -1);   -- -1 = sin eco

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_1us, tick_1ms : std_logic;
    signal echo     : std_logic_vector(3 downto 0) := (others => '0');
    signal trig     : std_logic_vector(3 downto 0);
    signal dist     : std_logic_vector(35 downto 0);
    signal nuevo    : std_logic_vector(3 downto 0);
    signal sin_eco  : std_logic_vector(3 downto 0);
    signal fin      : boolean := false;

    type t_cnt is array (0 to 3) of natural;
    signal n_nuevo  : t_cnt := (others => 0);

    function dist_de (v : std_logic_vector(35 downto 0); i : natural) return natural is
    begin
        return to_integer(unsigned(v(9 * i + 8 downto 9 * i)));
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    u_ticks : entity work.tick_gen
        generic map (CLK_HZ => CLK_HZ)
        port map (clk => clk, rst => rst, tick_1us => tick_1us,
                  tick_58us => open, tick_1ms => tick_1ms);

    dut : entity work.ultra_sched
        generic map (TURNO_MS => TURNO)
        port map (clk => clk, rst => rst, tick_1us => tick_1us, tick_1ms => tick_1ms,
                  echo => echo, trig => trig, dist => dist, nuevo => nuevo,
                  sin_eco => sin_eco);

    -- Modelos de sensor
    modelos : for i in 0 to 3 generate
        process
        begin
            wait until trig(i) = '1';
            wait until trig(i) = '0';
            if DIST_MODELO(i) >= 0 then
                wait for 150 us;
                echo(i) <= '1';
                wait for DIST_MODELO(i) * 58 us;
                echo(i) <= '0';
            end if;
        end process;
    end generate;

    -- Nunca dos TRIG a la vez
    process (clk)
        variable n : natural;
    begin
        if rising_edge(clk) then
            n := 0;
            for i in 0 to 3 loop
                if trig(i) = '1' then
                    n := n + 1;
                end if;
                if nuevo(i) = '1' then
                    n_nuevo(i) <= n_nuevo(i) + 1;
                end if;
            end loop;
            assert n <= 1 report "Dos TRIG en alto al mismo tiempo" severity error;
        end if;
    end process;

    estimulo : process
        variable t_ant   : time := 0 ns;
        variable esperado : natural;
    begin
        wait for 3 * T_CLK;
        rst <= '0';

        -- 5 disparos: orden y separacion
        for k in 0 to 4 loop
            esperado := k mod 4;
            wait until trig /= "0000";
            assert trig(esperado) = '1'
                report "Disparo " & integer'image(k) & ": se esperaba el sensor " &
                       integer'image(esperado) severity error;
            if k > 0 then
                assert now - t_ant = TURNO * 1 ms
                    report "Separacion entre disparos incorrecta: " &
                           time'image(now - t_ant) severity error;
            end if;
            t_ant := now;
            wait until trig = "0000";
        end loop;

        -- Despues de una vuelta completa ya hay 4 mediciones
        wait for 2 ms;
        assert dist_de(dist, 0) = 10  report "Distancia 0 incorrecta: " & integer'image(dist_de(dist, 0)) severity error;
        assert dist_de(dist, 1) = 50  report "Distancia 1 incorrecta: " & integer'image(dist_de(dist, 1)) severity error;
        assert dist_de(dist, 2) = 123 report "Distancia 2 incorrecta: " & integer'image(dist_de(dist, 2)) severity error;
        assert dist_de(dist, 3) = 511 report "Distancia 3 incorrecta: " & integer'image(dist_de(dist, 3)) severity error;
        assert sin_eco = "1000" report "sin_eco incorrecto" severity error;
        for i in 0 to 3 loop
            assert n_nuevo(i) >= 1
                report "El sensor " & integer'image(i) & " no dio pulso nuevo" severity error;
        end loop;

        report "tb_ultra_sched: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
