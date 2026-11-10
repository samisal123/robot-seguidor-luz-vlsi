-- ============================================================
-- tb_sinte_top.vhd
-- Prueba del sintetizador completo con el reloj de 50 MHz de la
-- tarjeta (el modelo del PLL lo baja a 25 MHz) y dos modelos de
-- teclado en los pines. El audio se reconstruye de AUDIO_PWM
-- contando los ciclos de 50 MHz en alto de cada ventana de 1024
-- (una muestra): 2 periodos de PWM de 512 dan 4 * (muestra + 128);
-- se le resta 512. La frecuencia se mide con el tiempo entre
-- cruces por cero. Los modos se cambian con el boton MODO.
-- Revisa:
--   1) arranque: LEDs apagados y silencio
--   2) tecla A del teclado 1: 440 Hz
--   3) acorde de 3 teclas en los dos teclados: el pico del audio
--      crece (suenan 3 voces)
--   4) al soltar, el audio queda en silencio despues del release
--   5) octava + (tecla B del teclado 1): A5 = 880 Hz en el teclado
--      1 y A6 = 1760 Hz en el teclado 2; octava - la regresa
--   6) configuracion (3 veces MODO): forma triangular y release de
--      20 ms desde los teclados; de regreso en interpretacion A4
--      sigue en 440 Hz, la onda ya no es cuadrada y calla a los
--      50 ms de soltar
--   7) grabacion (ACCION inicia y finaliza, LED D4) de una melodia
--      corta y su reproduccion (LED D5): la primera nota suena a su
--      frecuencia y la reproduccion dura lo mismo que la grabacion
--      (+-2 ms)
--   8) metronomo con su boton: destello en D2 y clic en el audio
--      sin notas; al apagarlo D2 ya no destella
--   9) VGA: periodos de HS (32 us) y VS (16.8 ms)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sinte_top is
end entity tb_sinte_top;

architecture sim of tb_sinte_top is
    constant T_CLK : time := 20 ns;    -- 50 MHz de la tarjeta
    constant FS    : real := 48828.125;

    signal clk       : std_logic := '0';
    signal BTN_RESET : std_logic := '1';
    signal BTN       : std_logic_vector(2 downto 0) := "111";   -- MODO, ACCION, METRONOMO
    signal LED       : std_logic_vector(2 downto 0);            -- D2, D4, D5 ('0' = encendido)
    signal TEC1_FIL  : std_logic_vector(3 downto 0);
    signal TEC1_COL  : std_logic_vector(3 downto 0);
    signal TEC2_FIL  : std_logic_vector(3 downto 0);
    signal TEC2_COL  : std_logic_vector(3 downto 0);
    signal AUDIO_PWM : std_logic;
    signal VGA_R, VGA_G, VGA_B : std_logic;
    signal VGA_HS, VGA_VS : std_logic;

    signal pres1 : std_logic_vector(15 downto 0) := (others => '0');
    signal pres2 : std_logic_vector(15 downto 0) := (others => '0');

    signal audio     : integer := 0;     -- muestra reconstruida (4x)
    signal n_muestra : natural := 0;
    signal fin       : boolean := false;

    -- teclas (4*fila + columna)
    constant T_1    : natural := 0;    -- C
    constant T_3    : natural := 2;    -- D
    constant T_5    : natural := 5;    -- E
    constant T_A    : natural := 3;
    constant T_B    : natural := 7;
    constant T_C    : natural := 11;
    constant T_D    : natural := 15;
    constant T_AST  : natural := 12;   -- * = A

begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.sinte_top
        port map (
            CLOCK_50  => clk,
            BTN_RESET => BTN_RESET,
            BTN       => BTN,
            TEC1_COL  => TEC1_COL,
            TEC2_COL  => TEC2_COL,
            LED       => LED,
            TEC1_FIL  => TEC1_FIL,
            TEC2_FIL  => TEC2_FIL,
            AUDIO_PWM => AUDIO_PWM,
            VGA_R     => VGA_R,
            VGA_G     => VGA_G,
            VGA_B     => VGA_B,
            VGA_HS    => VGA_HS,
            VGA_VS    => VGA_VS
        );

    teclado1 : entity work.modelo_teclado
        port map (filas => TEC1_FIL, cols => TEC1_COL, presion => pres1);

    teclado2 : entity work.modelo_teclado
        port map (filas => TEC2_FIL, cols => TEC2_COL, presion => pres2);

    -- audio reconstruido del PWM
    reconstruye : process (clk)
        variable alto, k : natural := 0;
    begin
        if rising_edge(clk) then
            if AUDIO_PWM = '1' then
                alto := alto + 1;
            end if;
            k := k + 1;
            if k = 1024 then
                audio     <= alto - 512;
                n_muestra <= n_muestra + 1;
                k    := 0;
                alto := 0;
            end if;
        end if;
    end process;

    -- 9) sincronia VGA
    vga : process
        variable t0 : time;
    begin
        wait until falling_edge(VGA_HS);
        for i in 1 to 5 loop
            t0 := now;
            wait until falling_edge(VGA_HS);
            assert now - t0 = 32 us
                report "tb_sinte_top: periodo de HS incorrecto" severity error;
        end loop;
        wait until falling_edge(VGA_VS);
        t0 := now;
        wait until falling_edge(VGA_VS);
        assert now - t0 = 16800 us
            report "tb_sinte_top: periodo de VS incorrecto" severity error;
        wait;
    end process;

    estimulo : process
        procedure espera_ms (n : natural) is
        begin
            wait for n * 1 ms;
        end procedure;

        -- frecuencia de p periodos (cruces por cero hacia arriba)
        procedure mide (p : natural; f : out real) is
            variable a, v   : integer;
            variable c      : natural := 0;
            variable n0, n1 : natural := 0;
            variable tope   : natural := 0;
        begin
            a := audio;
            loop
                wait on n_muestra;
                v := audio;
                tope := tope + 1;
                if a < 0 and v >= 0 then
                    if c = 0 then
                        n0 := n_muestra;
                    end if;
                    c := c + 1;
                    if c = p + 1 then
                        n1 := n_muestra;
                        exit;
                    end if;
                end if;
                a := v;
                exit when tope > 20000;
            end loop;
            if n1 > n0 then
                f := FS * real(p) / real(n1 - n0);
            else
                f := 0.0;
            end if;
        end procedure;

        procedure revisa_f (f, esperada : real; msg : string) is
        begin
            assert abs (f - esperada) / esperada < 0.005
                report "tb_sinte_top: " & msg & ": " & integer'image(integer(f)) & " Hz, se esperaban "
                       & integer'image(integer(esperada)) severity error;
        end procedure;

        -- pico de |audio| en n muestras y fraccion (en %) de muestras
        -- con |audio| menor que la mitad del pico (casi 0 en una
        -- cuadrada, cerca de 50 en una triangular)
        procedure forma_audio (n : natural; pico : out natural; medios : out natural) is
            type t_m is array (1 to 4000) of integer;
            variable m : t_m;
            variable p, c : natural := 0;
        begin
            for i in 1 to n loop
                wait on n_muestra;
                m(i) := audio;
                if abs (audio) > p then
                    p := abs (audio);
                end if;
            end loop;
            for i in 1 to n loop
                if 2 * abs (m(i)) < p then
                    c := c + 1;
                end if;
            end loop;
            pico   := p;
            medios := (100 * c) / n;
        end procedure;

        -- pulsa una tecla 30 ms y la suelta 30 ms (el antirrebote pide 20)
        procedure pulsa (signal p : out std_logic_vector(15 downto 0); k : natural) is
        begin
            p <= (others => '0');
            p(k) <= '1';
            espera_ms(30);
            p <= (others => '0');
            espera_ms(30);
        end procedure;

        -- botones del panel: 0 MODO, 1 ACCION, 2 METRONOMO
        procedure boton (n : natural) is
        begin
            BTN(n) <= '0';
            espera_ms(30);
            BTN(n) <= '1';
            espera_ms(30);
        end procedure;

        procedure silencio (n : natural; msg : string) is
        begin
            for i in 1 to n loop
                wait on n_muestra;
                assert audio = 0
                    report "tb_sinte_top: " & msg & ": deberia haber silencio" severity error;
            end loop;
        end procedure;

        variable f        : real;
        variable t_g0, t_g1, t_r0, t_r1 : time;
        variable vio_clic : boolean;
        variable pico1, pico3, medios, pico_t, medios_t : natural;
    begin
        -- 1) arranque
        espera_ms(5);
        assert LED = "111" report "tb_sinte_top: LEDs encendidos al arrancar" severity error;
        silencio(50, "arranque");

        -- 2) A4 en el teclado 1
        report "tb_sinte_top: paso 2 A4";
        pres1(T_AST) <= '1';
        espera_ms(30);
        mide(12, f);
        revisa_f(f, 440.0, "A4");
        forma_audio(400, pico1, medios);
        assert medios < 10
            report "tb_sinte_top: la forma inicial debe ser cuadrada (" & integer'image(medios) & " %)"
            severity error;

        -- 3) acorde: A4 + D4 (teclado 1) + E5 (teclado 2)
        report "tb_sinte_top: paso 3 acorde";
        pres1(T_3) <= '1';
        pres2(T_5) <= '1';
        espera_ms(30);
        forma_audio(2000, pico3, medios);
        assert 2 * pico3 > 3 * pico1
            report "tb_sinte_top: el acorde debe sonar con 3 voces (pico " & integer'image(pico3)
                   & " contra " & integer'image(pico1) & ")" severity error;

        -- 4) soltar todo: release de 150 ms
        report "tb_sinte_top: paso 4 soltar";
        pres1 <= (others => '0');
        pres2 <= (others => '0');
        espera_ms(190);
        silencio(100, "tras soltar");

        -- 5) octava +: A5 en el teclado 1 y A6 en el teclado 2
        report "tb_sinte_top: paso 5 octavas";
        pulsa(pres1, T_B);
        pres1(T_AST) <= '1';
        espera_ms(30);
        mide(12, f);
        revisa_f(f, 880.0, "A5");
        pres1 <= (others => '0');
        espera_ms(190);
        pres2(T_AST) <= '1';
        espera_ms(30);
        mide(24, f);
        revisa_f(f, 1760.0, "A6 en el teclado 2");
        pres2 <= (others => '0');
        espera_ms(190);
        pulsa(pres1, T_A);
        pres1(T_AST) <= '1';
        espera_ms(30);
        mide(12, f);
        revisa_f(f, 440.0, "A4 al regresar la octava");
        pres1 <= (others => '0');
        espera_ms(190);

        -- 6) configuracion: forma triangular y release de 20 ms
        report "tb_sinte_top: paso 6 configuracion";
        boton(0);                          -- grabacion
        boton(0);                          -- reproduccion
        boton(0);                          -- configuracion
        pulsa(pres1, T_B);                 -- forma: valor + = triangular
        for i in 1 to 4 loop
            pulsa(pres1, T_D);             -- parametro siguiente hasta release
        end loop;
        pulsa(pres2, T_A);                 -- release: valor - = 20 ms (teclado 2)
        boton(0);                          -- interpretacion
        pres1(T_AST) <= '1';
        espera_ms(30);
        mide(12, f);
        revisa_f(f, 440.0, "A4 triangular");
        forma_audio(400, pico_t, medios_t);
        assert medios_t > 30
            report "tb_sinte_top: la forma debe ser triangular (" & integer'image(medios_t) & " %)"
            severity error;
        pres1 <= (others => '0');
        espera_ms(50);
        silencio(50, "con release de 20 ms");

        -- 7) grabacion: C4 60 ms, silencio 40 ms, E4 50 ms
        report "tb_sinte_top: paso 7 grabacion";
        boton(0);                          -- grabacion
        BTN(1) <= '0';
        wait until LED(1) = '0' for 40 ms;
        assert LED(1) = '0' report "tb_sinte_top: ACCION debe iniciar la grabacion (D4)" severity error;
        t_g0 := now;
        espera_ms(10);
        BTN(1) <= '1';
        espera_ms(25);
        pres1(T_1) <= '1';
        espera_ms(60);
        pres1 <= (others => '0');
        espera_ms(40);
        pres1(T_5) <= '1';
        espera_ms(50);
        pres1 <= (others => '0');
        espera_ms(30);
        BTN(1) <= '0';
        wait until LED(1) = '1' for 40 ms;
        assert LED(1) = '1' report "tb_sinte_top: ACCION debe finalizar la grabacion" severity error;
        t_g1 := now;
        espera_ms(10);
        BTN(1) <= '1';
        espera_ms(25);

        -- reproduccion
        report "tb_sinte_top: paso 7 reproduccion";
        boton(0);                          -- reproduccion
        BTN(1) <= '0';
        wait until LED(2) = '0' for 40 ms;
        assert LED(2) = '0' report "tb_sinte_top: ACCION debe iniciar la reproduccion (D5)" severity error;
        t_r0 := now;
        wait until audio /= 0 for 100 ms;
        mide(8, f);
        revisa_f(f, 261.63, "C4 reproducido");
        BTN(1) <= '1';
        wait until LED(2) = '1' for 400 ms;
        assert LED(2) = '1' report "tb_sinte_top: la reproduccion debe terminar sola" severity error;
        t_r1 := now;
        assert abs ((t_r1 - t_r0) - (t_g1 - t_g0)) <= 2 ms
            report "tb_sinte_top: la reproduccion no dura lo que la grabacion" severity error;

        -- 8) metronomo
        report "tb_sinte_top: paso 8 metronomo";
        boton(0);                          -- configuracion
        boton(0);                          -- interpretacion
        BTN(2) <= '0';
        wait until LED(0) = '0' for 40 ms;
        assert LED(0) = '0'
            report "tb_sinte_top: el metronomo debe encender y marcar el primer tiempo (D2)" severity error;
        vio_clic := false;
        for i in 1 to 200 loop
            wait on n_muestra;
            if audio /= 0 then
                vio_clic := true;
            end if;
        end loop;
        assert vio_clic report "tb_sinte_top: el metronomo no sono" severity error;
        BTN(2) <= '1';
        espera_ms(30);
        boton(2);
        wait until LED(0) = '0' for 600 ms;
        assert LED(0) = '1' report "tb_sinte_top: con el metronomo apagado D2 no debe destellar"
            severity error;

        report "tb_sinte_top: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
