-- ============================================================
-- tb_metronomo.vhd
-- Prueba del metronomo. tick_1ms y tick_fs salen de divisores del
-- testbench mas rapidos que los reales (el modulo solo cuenta
-- pulsos), asi un segundo de metronomo se simula en microsegundos.
-- Revisa:
--   1) para cada tempo (60, 90, 120, 150 BPM): el primer tiempo es
--      inmediato al encender y lleva acento; los siguientes llegan
--      cada periodo_beat_ms(tempo) = 1000, 667, 500, 400 tick_1ms
--      exactos y hay acento en 1 de cada 4 (tiempos 0, 4, 8)
--   2) beat y acento son pulsos de 1 ciclo; acento nunca sin beat
--   3) cambio a un tempo mas rapido con la cuenta ya pasada: el
--      siguiente tiempo cae en el siguiente tick_1ms
--   4) con metro_on = '0' no hay tiempos
--   5) clic del acento y de un tiempo normal, muestra por muestra:
--      arranca en +48, la amplitud nunca sube y baja en linea recta
--      (36, 24 y 12 a 1/4, 1/2 y 3/4), dura 25 ms +-1.5 ms y su
--      frecuencia (cruces por cero) es 3000 Hz o 2000 Hz +-2 %;
--      despues queda en 0
--   6) reset
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_metronomo is
end entity tb_metronomo;

architecture sim of tb_metronomo is
    constant T_CLK : time := 20 ns;
    constant F_MUESTREO : real := 50.0e6 / 1024.0;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_fs  : std_logic := '0';
    signal tick_1ms : std_logic := '0';
    signal metro_on : std_logic := '0';
    signal tempo    : std_logic_vector(1 downto 0) := "00";
    signal beat     : std_logic;
    signal acento   : std_logic;
    signal clic     : std_logic_vector(7 downto 0);
    signal fin      : boolean := false;

    -- divisores de los ticks del testbench (ciclos entre pulsos)
    signal div_ms   : natural := 4;
    signal div_fs   : natural := 4;
    signal gen_fs   : boolean := false;

    -- monitor de tiempos
    signal n_beats   : natural := 0;
    signal intervalo : integer := -1;   -- tick_1ms desde el tiempo anterior
    signal fue_acento: std_logic := '0';

    -- grabadora del clic: una entrada por tick_fs
    type t_rec is array (0 to 8191) of integer;
    signal rec      : t_rec := (others => 0);
    signal n_rec    : natural := 0;      -- muestras grabadas
    signal inicio   : natural := 0;      -- primera muestra del ultimo clic
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.metronomo
        port map (
            clk      => clk,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms,
            metro_on => metro_on,
            tempo    => tempo,
            beat     => beat,
            acento   => acento,
            clic     => clic
        );

    ticks : process (clk)
        variable cm, cf : natural := 0;
    begin
        if rising_edge(clk) then
            tick_1ms <= '0';
            tick_fs  <= '0';
            if cm >= div_ms - 1 then
                cm := 0;
                tick_1ms <= '1';
            else
                cm := cm + 1;
            end if;
            if gen_fs then
                if cf >= div_fs - 1 then
                    cf := 0;
                    tick_fs <= '1';
                else
                    cf := cf + 1;
                end if;
            end if;
        end if;
    end process;

    -- Cuenta los tick_1ms entre tiempos; revisa que beat y acento
    -- sean pulsos de un ciclo
    monitor : process (clk)
        variable cnt      : integer := 0;
        variable beat_ant : std_logic := '0';
    begin
        if rising_edge(clk) then
            assert not (acento = '1' and beat = '0')
                report "acento sin beat" severity error;
            assert not (beat = '1' and beat_ant = '1')
                report "beat dura mas de un ciclo" severity error;
            beat_ant := beat;
            if beat = '1' then
                intervalo  <= cnt;
                fue_acento <= acento;
                n_beats    <= n_beats + 1;
                cnt        := 0;
            end if;
            if tick_1ms = '1' then
                cnt := cnt + 1;
            end if;
        end if;
    end process;

    -- Graba cada muestra de clic (la que el DUT calcula en el flanco
    -- con tick_fs se lee en el flanco siguiente). En el flanco en que
    -- se ve beat, la siguiente muestra por grabar es la primera del
    -- clic nuevo: una muestra calculada en el mismo flanco del tiempo
    -- todavia usa la envolvente anterior.
    grabadora : process (clk)
        variable pend : boolean := false;
        variable n    : natural := 0;
    begin
        if rising_edge(clk) then
            if pend then
                if n <= 8191 then
                    rec(n) <= to_integer(signed(clic));
                end if;
                n    := n + 1;
                pend := false;
            end if;
            if tick_fs = '1' then
                pend := true;
            end if;
            if beat = '1' then
                inicio <= n;
            end if;
            n_rec <= n;
        end if;
    end process;

    estimulo : process
        variable base : natural;
        variable p    : natural;
        variable sel  : std_logic_vector(1 downto 0);

        -- Espera el siguiente tiempo; falla si no llega en "limite"
        procedure esperar_beat (limite : time) is
            variable n0 : natural;
        begin
            n0 := n_beats;
            wait until n_beats = n0 + 1 for limite;
            assert n_beats = n0 + 1
                report "no llego el tiempo esperado" severity error;
        end procedure;

        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        -- Graba 1500 muestras de clic a partir del siguiente tick_fs
        -- y las revisa
        procedure revisar_clic (f_esp : real) is
            type t_clic is array (0 to 1499) of integer;
            variable c : t_clic;
            variable i0, ult, cambios, a, a_ant : integer;
            variable dur_ms, f : real;
        begin
            i0 := inicio;
            wait until n_rec >= i0 + 1500 for 1500 * 5 * T_CLK;
            assert n_rec >= i0 + 1500 report "no se grabaron las muestras del clic" severity error;
            for k in 0 to 1499 loop
                c(k) := rec(i0 + k);
            end loop;
            assert c(0) = 48
                report "el clic debe arrancar en +48 y empezo en " & integer'image(c(0))
                severity error;
            ult := -1;
            a_ant := 127;
            cambios := 0;
            for k in 0 to 1499 loop
                a := abs (c(k));
                assert a <= a_ant
                    report "la amplitud del clic subio en la muestra " & integer'image(k)
                    severity error;
                a_ant := a;
                if c(k) /= 0 then
                    ult := k;
                end if;
                if k > 0 then
                    if (c(k) > 0 and c(k - 1) < 0) or (c(k) < 0 and c(k - 1) > 0) then
                        cambios := cambios + 1;
                    end if;
                end if;
            end loop;
            dur_ms := real(ult + 1) * 1000.0 / F_MUESTREO;
            f  := real(cambios) * F_MUESTREO / (2.0 * real(ult));
            report "clic: " & integer'image(ult + 1) & " muestras = " & real'image(dur_ms) &
                   " ms, " & integer'image(cambios) & " cruces por cero = " &
                   real'image(f) & " Hz";
            assert dur_ms >= 23.5 and dur_ms <= 26.5
                report "duracion del clic fuera de 25 ms +-1.5 ms" severity error;
            assert f >= 0.98 * f_esp and f <= 1.02 * f_esp
                report "frecuencia del clic fuera de " & real'image(f_esp) & " Hz +-2 %"
                severity error;
            if ult > 100 then
                assert abs (abs (c(ult / 4)) - 36) <= 2 and
                       abs (abs (c(ult / 2)) - 24) <= 2 and
                       abs (abs (c(3 * ult / 4)) - 12) <= 2
                    report "la caida del clic no es lineal: " &
                           integer'image(c(ult / 4)) & " " & integer'image(c(ult / 2)) &
                           " " & integer'image(c(3 * ult / 4)) severity error;
            end if;
        end procedure;
    begin
        ciclos(4);
        rst <= '0';
        ciclos(10);
        assert n_beats = 0 report "hubo tiempos con metro_on = '0'" severity error;

        -- 1) y 2) periodos y acentos, tick_1ms cada 4 ciclos
        for t in 0 to 3 loop
            sel := std_logic_vector(to_unsigned(t, 2));
            p   := periodo_beat_ms(sel);
            metro_on <= '0';
            ciclos(10);
            tempo    <= sel;
            metro_on <= '1';
            base := n_beats;
            esperar_beat(5 * T_CLK);              -- inmediato
            assert fue_acento = '1'
                report "el primer tiempo debe llevar acento" severity error;
            for b in 1 to 8 loop
                esperar_beat((p + 2) * 4 * T_CLK);
                assert intervalo = p
                    report "tempo " & integer'image(t) & ", tiempo " & integer'image(b) &
                           ": intervalo de " & integer'image(intervalo) & " ms, se esperaba " &
                           integer'image(p) severity error;
                if b mod 4 = 0 then
                    assert fue_acento = '1'
                        report "falta el acento en el tiempo " & integer'image(b) severity error;
                else
                    assert fue_acento = '0'
                        report "acento de mas en el tiempo " & integer'image(b) severity error;
                end if;
            end loop;
            report "tempo " & integer'image(t) & " (" & integer'image(bpm(sel)) &
                   " BPM): 8 intervalos de " & integer'image(p) & " ms, acentos en 0, 4 y 8";
        end loop;

        -- 3) cambio a un tempo mas rapido con la cuenta ya pasada
        metro_on <= '0';
        ciclos(10);
        tempo    <= "00";
        metro_on <= '1';
        esperar_beat(5 * T_CLK);
        ciclos(600 * 4);
        tempo <= "11";
        esperar_beat(3 * 4 * T_CLK);
        assert intervalo >= 600 and intervalo <= 602
            report "cambio de tempo: intervalo de " & integer'image(intervalo) severity error;
        esperar_beat(402 * 4 * T_CLK);
        assert intervalo = 400
            report "despues del cambio el intervalo debe ser 400" severity error;

        -- 4) apagado: sin tiempos
        metro_on <= '0';
        base := n_beats;
        ciclos(3000 * 4);
        assert n_beats = base report "hubo tiempos con metro_on = '0'" severity error;

        -- 5) clic: 1 ms = 16 ciclos, una muestra cada 4 ciclos
        --    (400 ms = 1600 muestras entre tiempos)
        div_ms   <= 16;
        gen_fs   <= true;
        tempo    <= "11";
        ciclos(20);
        metro_on <= '1';
        esperar_beat(5 * T_CLK);
        assert fue_acento = '1' report "falta el acento al encender" severity error;
        revisar_clic(3000.0);                       -- acento: 3 kHz
        esperar_beat(800 * 16 * T_CLK);
        assert fue_acento = '0' report "el segundo tiempo no lleva acento" severity error;
        revisar_clic(2000.0);                       -- tiempo normal: 2 kHz

        -- 6) reset
        rst <= '1';
        ciclos(2);
        rst <= '0';
        metro_on <= '0';
        ciclos(2);
        wait for 1 ns;
        assert to_integer(signed(clic)) = 0 report "el reset no apago el clic" severity error;
        base := n_beats;
        ciclos(2000);
        assert n_beats = base report "hubo tiempos despues del reset" severity error;

        report "tb_metronomo: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
