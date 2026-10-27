-- ============================================================
-- tb_tremolo.vhd
-- Prueba del tremolo.
-- Revisa:
--   1) apagado (activo = '0'): y = x para los 4096 valores, con una
--      muestra por ciclo (la tuberia acepta muestras seguidas) y
--      latencia de 3 ciclos
--   2) encendido con x = 2000 constante durante 25 000 muestras:
--      - y entre el minimo y 2000; maximo exacto 2000 (ganancia 1)
--      - profundidad 1 - min/max de 50 % (+-3 %)
--      - periodo del LFO medido entre cruces de bajada por 1500:
--        9800 muestras +-1 % (unos 5 Hz)
--      - forma triangular: a 1/8 de periodo del cruce la senal va
--        en 1500 +-248 (con un seno seria +-351)
--      - el LFO solo avanza con ent_valida: una pausa de 50 000
--        ciclos no hace saltar la salida
--   3) encendido con x al azar (positivos y negativos):
--      piso(x * 129/256) <= y <= x  (y al reves si x < 0)
--   4) reset: el LFO vuelve a fase 0 (ganancia 1, y = x)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_tremolo is
end entity tb_tremolo;

architecture sim of tb_tremolo is
    constant T_CLK : time := 20 ns;
    constant F_MUESTREO : real := 50.0e6 / 1024.0;
    constant N_LFO : natural := 25000;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal activo     : std_logic := '0';
    signal ent_valida : std_logic := '0';
    signal x          : std_logic_vector(11 downto 0) := (others => '0');
    signal y          : std_logic_vector(11 downto 0);
    signal sal_valida : std_logic;
    signal fin        : boolean := false;

    function piso_div (a, b : integer) return integer is
    begin
        if a >= 0 then
            return a / b;
        else
            return -((-a + b - 1) / b);
        end if;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.tremolo
        port map (
            clk        => clk,
            rst        => rst,
            activo     => activo,
            ent_valida => ent_valida,
            x          => x,
            y          => y,
            sal_valida => sal_valida
        );

    estimulo : process
        type t_reg is array (0 to N_LFO - 1) of integer;
        variable yr     : t_reg;
        variable yv     : integer;
        variable ymin, ymax : integer;
        variable cruces : natural;
        type t_cruces is array (0 to 9) of integer;
        variable c      : t_cruces;
        variable per    : integer;
        variable prof   : real;
        variable lfsr   : unsigned(15 downto 0) := x"ACE1";
        variable xv     : integer;

        -- Una muestra cada 4 ciclos; revisa la latencia de 3 ciclos
        procedure muestra (xin : integer; act : std_logic; yout : out integer) is
        begin
            x          <= std_logic_vector(to_signed(xin, 12));
            activo     <= act;
            ent_valida <= '1';
            wait until rising_edge(clk);
            ent_valida <= '0';
            wait for 1 ns;
            assert sal_valida = '0' report "sal_valida antes de tiempo (1)" severity error;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '0' report "sal_valida antes de tiempo (2)" severity error;
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '1' report "sal_valida no llego a los 3 ciclos" severity error;
            yout := to_integer(signed(y));
            wait until rising_edge(clk);
            wait for 1 ns;
            assert sal_valida = '0' report "sal_valida dura mas de un ciclo" severity error;
        end procedure;

        procedure siguiente_azar is
        begin
            lfsr := lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
        end procedure;
    begin
        for i in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- 1) apagado, una muestra por ciclo; la salida de la muestra n
        --    se ve despues del flanco que captura la muestra n + 2
        activo <= '0';
        for n in 0 to 4095 + 2 loop
            if n <= 4095 then
                x          <= std_logic_vector(to_signed(n - 2048, 12));
                ent_valida <= '1';
            else
                ent_valida <= '0';
            end if;
            wait until rising_edge(clk);
            wait for 1 ns;
            if n >= 2 then
                assert sal_valida = '1'
                    report "apagado: falta sal_valida en la muestra " & integer'image(n - 2)
                    severity error;
                assert to_integer(signed(y)) = n - 2 - 2048
                    report "apagado: y /= x en x = " & integer'image(n - 2 - 2048) severity error;
            else
                assert sal_valida = '0' report "apagado: sal_valida antes de tiempo" severity error;
            end if;
        end loop;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert sal_valida = '0' report "apagado: sal_valida de mas" severity error;
        muestra(-1234, '0', yv);
        assert yv = -1234 report "apagado: y /= x con muestras espaciadas" severity error;

        -- 4) reset: fase 0, ganancia 1
        rst <= '1';
        wait until rising_edge(clk);
        rst <= '0';
        wait for 1 ns;
        for i in 0 to 9 loop
            if i mod 2 = 0 then
                xv := 2000 - 37 * i;
            else
                xv := -2000 + 51 * i;
            end if;
            muestra(xv, '1', yv);
            assert yv = xv
                report "despues del reset la ganancia debe ser 1: x = " & integer'image(xv) &
                       ", y = " & integer'image(yv) severity error;
        end loop;

        -- 2) encendido con x constante; pausa larga a la mitad
        rst <= '1';
        wait until rising_edge(clk);
        rst <= '0';
        wait for 1 ns;
        for n in 0 to N_LFO - 1 loop
            if n = 3000 then
                for i in 1 to 50000 loop
                    wait until rising_edge(clk);
                end loop;
                wait for 1 ns;
            end if;
            muestra(2000, '1', yr(n));
            if n = 3000 then
                assert abs (yr(3000) - yr(2999)) <= 2
                    report "la salida salto despues de una pausa: el LFO avanzo sin muestras"
                    severity error;
            end if;
        end loop;
        ymin := 2047;
        ymax := -2048;
        for n in 0 to N_LFO - 1 loop
            if yr(n) < ymin then ymin := yr(n); end if;
            if yr(n) > ymax then ymax := yr(n); end if;
        end loop;
        assert ymax = 2000
            report "maximo del tremolo = " & integer'image(ymax) & ", se esperaba 2000"
            severity error;
        prof := 1.0 - real(ymin) / real(ymax);
        report "tremolo: min = " & integer'image(ymin) & ", max = " & integer'image(ymax) &
               ", profundidad = " & real'image(prof);
        assert prof > 0.47 and prof < 0.53
            report "profundidad fuera de 50 % +-3 %" severity error;
        cruces := 0;
        for n in 1 to N_LFO - 1 loop
            if yr(n - 1) >= 1500 and yr(n) < 1500 and cruces <= 9 then
                c(cruces) := n;
                cruces := cruces + 1;
            end if;
        end loop;
        assert cruces >= 2
            report "no hubo dos cruces de bajada en 25 000 muestras" severity error;
        for i in 1 to cruces - 1 loop
            per := c(i) - c(i - 1);
            report "periodo del LFO = " & integer'image(per) & " muestras = " &
                   real'image(F_MUESTREO / real(per)) & " Hz";
            assert per >= 9702 and per <= 9898
                report "periodo del LFO fuera de 9800 +-1 %" severity error;
        end loop;
        for i in 0 to cruces - 1 loop
            if c(i) - 1225 >= 0 and c(i) + 1225 <= N_LFO - 1 then
                assert abs (yr(c(i) - 1225) - 1748) <= 30 and abs (yr(c(i) + 1225) - 1252) <= 30
                    report "la modulacion no es triangular: " &
                           integer'image(yr(c(i) - 1225)) & " / " & integer'image(yr(c(i) + 1225))
                    severity error;
            end if;
        end loop;

        -- 3) encendido con x al azar
        for n in 0 to 4999 loop
            siguiente_azar;
            xv := to_integer(signed(lfsr(11 downto 0)));
            muestra(xv, '1', yv);
            if xv >= 0 then
                assert yv <= xv and yv >= piso_div(xv * 129, 256)
                    report "x = " & integer'image(xv) & ": y = " & integer'image(yv) &
                           " fuera de [x*129/256, x]" severity error;
            else
                assert yv >= xv and yv <= piso_div(xv * 129, 256)
                    report "x = " & integer'image(xv) & ": y = " & integer'image(yv) &
                           " fuera de [x, x*129/256]" severity error;
            end if;
        end loop;

        report "tb_tremolo: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
