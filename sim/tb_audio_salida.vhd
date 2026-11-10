-- ============================================================
-- tb_audio_salida.vhd
-- Prueba de punta a punta de la etapa de audio con los ticks
-- reales a 25 MHz (tick_fs cada FS_DIV = 512 ciclos, tick_1ms
-- cada 25 000). Un medidor cuenta los ciclos en alto de cada
-- periodo del PWM (ventanas de 256 ciclos desde que se suelta el
-- reset), revisa que cada periodo sea un solo pulso al inicio, que
-- los 2 periodos de cada muestra midan lo mismo y que
-- nivel = |muestra|, y guarda
-- la muestra reconstruida (ancho - 128) de cada tick_fs.
-- Revisa:
--   A) voz senoidal (voz0 = seno, 1335 Hz) a volumen 100 % sin
--      efectos: la muestra que sale del PWM es piso(voz0 / 2) en
--      cada una de 65 muestras; clip no se enciende
--   B) volumen 0 con la voz sonando: silencio exacto. Al encender el
--      metronomo hay beat y acento en el siguiente ciclo y solo se
--      oye el clic (empieza en +48, la amplitud nunca sube, dura
--      ~25 ms, 3 kHz por ser acento) y luego silencio exacto hasta
--      los 100 ms
--   C) tremolo (efecto 01) con voz constante: la salida arranca en
--      50 y baja sin subir durante 1200 muestras (LFO desde fase 0)
--   D) eco (efecto 10) con un impulso: regresa exactamente 4096
--      muestras despues a la mitad; todo lo demas vale 0
--   E) los dos (efecto 11): baja por el tremolo y 4096 muestras
--      despues sube de golpe por el eco (al menos 15 sobre la
--      muestra anterior)
--   F) clip: dos voces a 127 llegan a 127 sin clip; tres voces
--      durante una sola muestra encienden clip por 99 a 100 ms; el
--      clic sobre una senal de 127 satura la suma final y tambien
--      enciende clip
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_audio_salida is
end entity tb_audio_salida;

architecture sim of tb_audio_salida is
    constant T_CLK : time := 40 ns;    -- 25 MHz
    constant F_MUESTREO : real := real(CLK_HZ_SIS) / real(FS_DIV);
    constant RETARDO    : natural := 4096;   -- eco de audio_salida
    constant MAX_MED    : natural := 16383;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal tick_fs  : std_logic := '0';
    signal tick_1ms : std_logic := '0';
    signal voz0, voz1, voz2 : std_logic_vector(7 downto 0) := (others => '0');
    signal volumen  : std_logic_vector(2 downto 0) := "100";
    signal efecto   : std_logic_vector(1 downto 0) := E_NINGUNO;
    signal metro_on : std_logic := '0';
    signal tempo    : std_logic_vector(1 downto 0) := "11";
    signal pwm      : std_logic;
    signal beat     : std_logic;
    signal acento   : std_logic;
    signal clip     : std_logic;
    signal nivel    : std_logic_vector(7 downto 0);
    signal fin      : boolean := false;

    type t_med is array (0 to MAX_MED) of integer;
    signal med     : t_med := (others => 0);   -- muestra medida en el PWM
    signal n_med   : integer := -1;            -- ultima muestra medida
    signal n_tick  : integer := -1;            -- ultima muestra tomada por el DUT
    signal n_beats : natural := 0;

    function piso_div (a, b : integer) return integer is
    begin
        if a >= 0 then
            return a / b;
        else
            return -((-a + b - 1) / b);
        end if;
    end function;

    function sv8 (v : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(v, 8));
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.audio_salida
        port map (
            clk      => clk,
            rst      => rst,
            tick_fs  => tick_fs,
            tick_1ms => tick_1ms,
            voz0     => voz0,
            voz1     => voz1,
            voz2     => voz2,
            volumen  => volumen,
            efecto   => efecto,
            metro_on => metro_on,
            tempo    => tempo,
            pwm      => pwm,
            beat     => beat,
            acento   => acento,
            clip     => clip,
            nivel    => nivel
        );

    -- Ticks (fase fija respecto al reset) y medidor del PWM.
    -- e = flancos desde que el DUT salio de reset (0 = el primero).
    -- tick_fs se toma en los flancos 512 m + 100 (muestra m); la
    -- muestra final queda lista 9 ciclos despues y el PWM la usa en
    -- los periodos 2m+1 y 2m+2.
    medidor : process (clk)
        variable e       : integer := 0;
        variable cnt     : integer := 0;
        variable bajo    : boolean := false;
        variable idx, k, pos, m : integer;
        variable primera : integer := 0;
        variable ncap    : integer := -1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                e    := 0;
                cnt  := 0;
                bajo := false;
                ncap := -1;
                n_med    <= -1;
                n_tick   <= -1;
                tick_fs  <= '0';
                tick_1ms <= '0';
            else
                if tick_fs = '1' then
                    ncap   := ncap + 1;
                    n_tick <= ncap;
                end if;
                -- el pwm que se ve ahora es el registro despues del flanco e - 1
                if e >= 1 then
                    idx := e - 1;
                    k   := idx / 256;
                    pos := idx mod 256;
                    if pos = 0 then
                        cnt  := 0;
                        bajo := false;
                    end if;
                    if pwm = '1' then
                        assert not bajo
                            report "PWM: mas de un pulso en el periodo " & integer'image(k)
                            severity error;
                        cnt := cnt + 1;
                    else
                        bajo := true;
                    end if;
                    if pos = 255 then
                        if k = 0 then
                            assert cnt = 128
                                report "PWM: el primer periodo debe tener duty 128" severity error;
                        else
                            m := (k - 1) / 2;
                            if (k - 1) mod 2 = 0 then
                                primera := cnt;
                                if m <= MAX_MED then
                                    med(m) <= cnt - 128;
                                end if;
                                n_med <= m;
                                assert to_integer(unsigned(nivel)) = abs (cnt - 128)
                                    report "nivel = " & integer'image(to_integer(unsigned(nivel))) &
                                           " /= |muestra| en la muestra " & integer'image(m)
                                    severity error;
                            else
                                assert cnt = primera
                                    report "PWM: los 2 periodos de la muestra " & integer'image(m) &
                                           " no miden lo mismo" severity error;
                            end if;
                        end if;
                    end if;
                end if;
                if (e + 1) mod FS_DIV = 100 then
                    tick_fs <= '1';
                else
                    tick_fs <= '0';
                end if;
                if (e + 1) mod 25000 = 12500 then
                    tick_1ms <= '1';
                else
                    tick_1ms <= '0';
                end if;
                e := e + 1;
            end if;
        end if;
    end process;

    tiempos : process (clk)
    begin
        if rising_edge(clk) then
            assert not (acento = '1' and beat = '0') report "acento sin beat" severity error;
            if beat = '1' then
                n_beats <= n_beats + 1;
            end if;
        end if;
    end process;

    estimulo : process
        variable m, ult, cambios, a, a_ant, b0 : integer;
        variable f, dur_ms : real;
        variable t_sat, dt : time;

        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure reiniciar is
        begin
            rst <= '1';
            ciclos(5);
            rst <= '0';
        end procedure;

        -- Espera a que el DUT tome la siguiente muestra, deja pasar la
        -- cadena (20 ciclos) y devuelve el indice de esa muestra; lo que
        -- se cambie despues aplica desde la muestra siguiente
        procedure siguiente (n : out integer) is
        begin
            wait until rising_edge(clk) and tick_fs = '1';
            ciclos(20);
            n := n_tick;
        end procedure;

        procedure esperar_medida (n : integer) is
        begin
            if n_med < n then
                wait until n_med >= n;
            end if;
        end procedure;
    begin
        ------------------------------------------------------------
        -- A) seno a volumen 100 %, sin efectos; B) volumen 0 y metronomo
        ------------------------------------------------------------
        volumen  <= "100";
        efecto   <= E_NINGUNO;
        metro_on <= '0';
        tempo    <= "11";
        voz0     <= sv8(seno(0));
        voz1     <= sv8(0);
        voz2     <= sv8(0);
        reiniciar;
        loop
            siguiente(m);
            voz0 <= sv8(seno(((m + 1) * 7) mod 256));
            assert clip = '0'
                report "A/B: clip encendido con una sola voz a escala completa" severity error;
            if m = 64 then
                volumen <= "000";               -- volumen 0 desde la muestra 65
            end if;
            if m = 80 then
                b0 := n_beats;
                metro_on <= '1';                -- el clic empieza en la muestra 81
                wait until rising_edge(clk);
                wait for 1 ns;
                assert beat = '1' and acento = '1'
                    report "B: al encender el metronomo debe haber beat con acento" severity error;
                wait until rising_edge(clk);
                wait for 1 ns;
                assert beat = '0' report "B: beat dura mas de un ciclo" severity error;
            end if;
            exit when m = 81 + 4882;            -- 100 ms despues del tiempo
        end loop;
        metro_on <= '0';
        esperar_medida(81 + 4882);
        for i in 0 to 64 loop
            assert med(i) = piso_div(seno((i * 7) mod 256), 2)
                report "A: muestra " & integer'image(i) & " del PWM = " & integer'image(med(i)) &
                       ", se esperaba " & integer'image(piso_div(seno((i * 7) mod 256), 2))
                severity error;
        end loop;
        report "A: 65 muestras del seno reproducidas exactas en el PWM";
        for i in 65 to 80 loop
            assert med(i) = 0
                report "B: con volumen 0 debe haber silencio (muestra " & integer'image(i) & ")"
                severity error;
        end loop;
        assert med(81) = 48
            report "B: el clic debe empezar en +48 y empezo en " & integer'image(med(81))
            severity error;
        ult := -1;
        a_ant := 127;
        cambios := 0;
        for k in 0 to 4882 loop
            a := abs (med(81 + k));
            assert a <= a_ant
                report "B: la amplitud del clic subio en la muestra " & integer'image(81 + k)
                severity error;
            a_ant := a;
            if med(81 + k) /= 0 then
                ult := k;
            end if;
            if k > 0 then
                if (med(81 + k) > 0 and med(80 + k) < 0) or (med(81 + k) < 0 and med(80 + k) > 0) then
                    cambios := cambios + 1;
                end if;
            end if;
        end loop;
        dur_ms := real(ult + 1) * 1000.0 / F_MUESTREO;
        f  := real(cambios) * F_MUESTREO / (2.0 * real(ult));
        report "B: clic de " & real'image(dur_ms) & " ms a " & real'image(f) &
               " Hz; silencio exacto hasta 100 ms";
        assert dur_ms >= 23.5 and dur_ms <= 26.5 report "B: duracion del clic fuera de 25 ms +-1.5 ms" severity error;
        assert f >= 2940.0 and f <= 3060.0 report "B: el clic del acento debe ser de 3 kHz" severity error;
        assert n_beats = b0 + 1 report "B: debio haber un solo tiempo en 100 ms" severity error;

        ------------------------------------------------------------
        -- C) tremolo
        ------------------------------------------------------------
        volumen  <= "100";
        efecto   <= E_TREMOLO;
        voz0     <= sv8(100);
        reiniciar;
        loop
            siguiente(m);
            exit when m = 1199;
        end loop;
        esperar_medida(1199);
        assert med(0) = 50 report "C: el tremolo arranca con ganancia 1 (50)" severity error;
        for i in 1 to 1199 loop
            assert med(i) <= med(i - 1)
                report "C: la salida subio en la muestra " & integer'image(i) severity error;
        end loop;
        assert med(1199) <= 45
            report "C: el tremolo no bajo la amplitud (" & integer'image(med(1199)) & ")" severity error;
        report "C: tremolo de 50 a " & integer'image(med(1199)) & " en 1200 muestras";

        ------------------------------------------------------------
        -- D) eco con un impulso en la muestra 5
        ------------------------------------------------------------
        efecto <= E_ECO;
        voz0   <= sv8(0);
        reiniciar;
        loop
            siguiente(m);
            if m + 1 = 5 then
                voz0 <= sv8(100);
            else
                voz0 <= sv8(0);
            end if;
            exit when m = 5 + RETARDO + 20;
        end loop;
        esperar_medida(5 + RETARDO + 20);
        for i in 0 to 5 + RETARDO + 20 loop
            if i = 5 then
                assert med(i) = 50 report "D: el impulso debe salir en 50" severity error;
            elsif i = 5 + RETARDO then
                assert med(i) = 25
                    report "D: el eco debe regresar en 25 a las 4096 muestras y salio " &
                           integer'image(med(i)) severity error;
            else
                assert med(i) = 0
                    report "D: muestra " & integer'image(i) & " = " & integer'image(med(i)) &
                           ", se esperaba 0" severity error;
            end if;
        end loop;
        report "D: eco exacto 4096 muestras despues (84 ms) a la mitad";

        ------------------------------------------------------------
        -- E) tremolo y eco
        ------------------------------------------------------------
        efecto <= E_AMBOS;
        voz0   <= sv8(100);
        reiniciar;
        loop
            siguiente(m);
            exit when m = RETARDO + 108;
        end loop;
        esperar_medida(RETARDO + 108);
        assert med(0) = 50 report "E: debe arrancar en 50" severity error;
        for i in 1 to 1199 loop
            assert med(i) <= med(i - 1)
                report "E: la salida subio en la muestra " & integer'image(i) severity error;
        end loop;
        assert med(1199) <= 45 report "E: falta el tremolo" severity error;
        -- el eco suma la mitad de lo que salio RETARDO muestras antes
        -- (unos 25): la salida sube de golpe respecto a la muestra previa
        for i in RETARDO to RETARDO + 108 loop
            assert med(i) >= med(RETARDO - 1) + 15
                report "E: falta el eco en la muestra " & integer'image(i) & " (" &
                       integer'image(med(i)) & " contra " & integer'image(med(RETARDO - 1)) & ")"
                severity error;
        end loop;
        report "E: tremolo (50 a " & integer'image(med(1199)) & ") y eco (" &
               integer'image(med(RETARDO)) & " en la muestra 4096)";

        ------------------------------------------------------------
        -- F) clip
        ------------------------------------------------------------
        efecto  <= E_NINGUNO;
        volumen <= "100";
        voz0    <= sv8(127);
        voz1    <= sv8(127);
        voz2    <= sv8(0);
        reiniciar;
        loop
            siguiente(m);
            assert clip = '0' report "F: dos voces a 127 no deben encender clip" severity error;
            exit when m = 19;
        end loop;
        voz2 <= sv8(127);                       -- solo la muestra 20 satura la mezcla
        siguiente(m);
        voz2  <= sv8(0);
        t_sat := now;
        assert clip = '1' report "F: tres voces a 127 deben encender clip" severity error;
        wait until clip = '0' for 120 ms;
        dt := now - t_sat;
        report "F: clip encendido " & integer'image(dt / 1 us) & " us despues de la saturacion";
        assert dt >= 98.9 ms and dt <= 100.1 ms
            report "F: clip debe durar unos 100 ms" severity error;
        esperar_medida(20);
        for i in 0 to 20 loop
            assert med(i) = 127 report "F: dos o tres voces a 127 deben dar 127" severity error;
        end loop;
        siguiente(m);
        metro_on <= '1';                        -- clic de +48 sobre 127
        siguiente(m);
        assert clip = '1' report "F: el clic sobre 127 debe saturar la suma final" severity error;
        esperar_medida(m);
        assert med(m) = 127 report "F: la suma final debe saturar en 127" severity error;
        metro_on <= '0';

        report "tb_audio_salida: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
