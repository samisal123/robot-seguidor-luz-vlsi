-- ============================================================
-- tb_pwm_8b.vhd
-- Verifica pwm_8b a 50 MHz con PRESC = 10:
--   duty 0, 1, 64, 128 y 255: tiempo en alto por periodo
--   exacto (duty * 200 ns),
--   periodo de 51.2 us entre flancos de subida,
--   un cambio de duty a mitad de pulso no altera el pulso en
--   curso y se aplica en el siguiente periodo.
-- GHDL: sim/correr.sh pwm_8b
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pwm_8b is
end entity tb_pwm_8b;

architecture sim of tb_pwm_8b is
    constant T_CLK   : time := 20 ns;
    constant PERIODO : time := 51.2 us;    -- 256 * 10 * 20 ns
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';
    signal duty : std_logic_vector(7 downto 0) := (others => '0');
    signal pwm  : std_logic;
    signal fin  : boolean := false;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.pwm_8b
        generic map (PRESC => 10)
        port map (clk => clk, rst => rst, duty => duty, pwm => pwm);

    estimulo : process
        type t_duties is array (natural range <>) of natural;
        constant DUTIES : t_duties := (0, 1, 64, 128, 255);
        variable altos : natural;
        variable t_sub, t_baj : time;
    begin
        wait for 100 ns;
        wait until rising_edge(clk);
        rst <= '0';

        for i in DUTIES'range loop
            duty <= std_logic_vector(to_unsigned(DUTIES(i), 8));
            wait for 2 * PERIODO;           -- deja que se aplique

            -- Cuenta ciclos en alto en una ventana de exactamente un periodo
            altos := 0;
            for c in 1 to 2560 loop
                wait until rising_edge(clk);
                if pwm = '1' then
                    altos := altos + 1;
                end if;
            end loop;
            assert altos = DUTIES(i) * 10
                report "duty " & integer'image(DUTIES(i)) & ": " &
                       integer'image(altos) & " ciclos en alto, se esperaban " &
                       integer'image(DUTIES(i) * 10)
                severity error;

            -- Periodo y ancho medidos con flancos
            if DUTIES(i) > 0 then
                wait until pwm = '1';
                t_sub := now;
                wait until pwm = '0';
                t_baj := now;
                assert t_baj - t_sub = DUTIES(i) * 10 * T_CLK
                    report "duty " & integer'image(DUTIES(i)) & ": ancho incorrecto"
                    severity error;
                wait until pwm = '1';
                assert now - t_sub = PERIODO
                    report "duty " & integer'image(DUTIES(i)) & ": periodo incorrecto"
                    severity error;
            end if;
        end loop;

        -- Cambio de duty a mitad del pulso: el pulso en curso no cambia
        duty <= std_logic_vector(to_unsigned(128, 8));
        wait for 2 * PERIODO;
        wait until pwm = '1';
        t_sub := now;
        wait for 5 us;
        duty <= std_logic_vector(to_unsigned(20, 8));
        wait until pwm = '0';
        assert now - t_sub = 128 * 10 * T_CLK
            report "el cambio de duty corto el pulso en curso" severity error;
        wait until pwm = '1';
        assert now - t_sub = PERIODO report "el cambio de duty movio el periodo" severity error;
        t_sub := now;
        wait until pwm = '0';
        assert now - t_sub = 20 * 10 * T_CLK
            report "el duty nuevo no se aplico en el siguiente periodo" severity error;

        -- Con rst la salida se apaga
        wait until pwm = '1';
        wait until rising_edge(clk);
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        assert pwm = '0' report "rst no apago pwm" severity error;

        report "tb_pwm_8b: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
