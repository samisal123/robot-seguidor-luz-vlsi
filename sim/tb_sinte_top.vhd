-- ============================================================
-- tb_sinte_top.vhd
-- Prueba del sintetizador completo a 50 MHz reales, con dos
-- modelos de teclado en los pines del GPIO. El audio se
-- reconstruye de AUDIO_PWM contando los ciclos en alto de cada
-- ventana de 1024 ciclos (una muestra): 4 periodos de PWM dan
-- 4 * (muestra + 128); se le resta 512.
-- La frecuencia se mide con el tiempo entre cruces por cero.
-- Revisa:
--   1) arranque: modo "In", octava 4, sin nota, LEDs apagados
--   2) tecla A del teclado 1: 440 Hz, "A4" en HEX1-HEX0, LEDR0
--   3) acorde de 3 teclas en los dos teclados: 3 voces (LEDR0-2)
--   4) al soltar, las voces se apagan y el audio queda en silencio
--   5) octava + (tecla B del teclado 1): A5 = 880 Hz y la A del
--      teclado 2 = A6 (en los displays), sonando las dos
--   6) configuracion: cambiar la forma a triangular y el release
--      a 20 ms desde los teclados; A4 sigue en 440 Hz
--   7) grabacion de una melodia corta (KEY0 inicia y finaliza)
--      y su reproduccion: la primera nota suena a su frecuencia y
--      la reproduccion dura lo mismo que la grabacion (+-2 ms)
--   8) metronomo con KEY1: LEDR3, destello en LEDR4 y clic en el
--      audio sin notas
--   9) VGA: periodos de HS (32 us) y VS (16.8 ms)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sinte_top is
end entity tb_sinte_top;

architecture sim of tb_sinte_top is
    constant T_CLK : time := 20 ns;
    constant FS    : real := 48828.125;

    signal clk       : std_logic := '0';
    signal KEY       : std_logic_vector(1 downto 0) := "11";
    signal SW        : std_logic_vector(9 downto 0) := (others => '0');
    signal LEDR      : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(7 downto 0);
    signal TEC1_FIL  : std_logic_vector(3 downto 0);
    signal TEC1_COL  : std_logic_vector(3 downto 0);
    signal TEC2_FIL  : std_logic_vector(3 downto 0);
    signal TEC2_COL  : std_logic_vector(3 downto 0);
    signal AUDIO_PWM : std_logic;
    signal VGA_R, VGA_G, VGA_B : std_logic_vector(3 downto 0);
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

    function car (h : std_logic_vector(7 downto 0)) return character is
        variable s : std_logic_vector(6 downto 0);
    begin
        s := not h(6 downto 0);
        case s is
            when "0111111" => return '0';
            when "0000110" => return '1';
            when "1011011" => return '2';
            when "1001111" => return '3';
            when "1100110" => return '4';
            when "1101101" => return '5';
            when "1111101" => return '6';
            when "0000111" => return '7';
            when "1111111" => return '8';
            when "1101111" => return '9';
            when "1110111" => return 'A';
            when "1111100" => return 'b';
            when "0111001" => return 'C';
            when "1011110" => return 'd';
            when "1111001" => return 'E';
            when "1110001" => return 'F';
            when "0111101" => return 'G';
            when "0110000" => return 'I';
            when "1010100" => return 'n';
            when "1011100" => return 'o';
            when "1110011" => return 'P';
            when "1010000" => return 'r';
            when "1111000" => return 't';
            when "0111110" => return 'U';
            when "0011100" => return 'u';
            when "1000000" => return '-';
            when "0000000" => return ' ';
            when others    => return '?';
        end case;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.sinte_top
        port map (
            MAX10_CLK1_50 => clk,
            KEY           => KEY,
            SW            => SW,
            LEDR          => LEDR,
            HEX0          => HEX0,
            HEX1          => HEX1,
            HEX2          => HEX2,
            HEX3          => HEX3,
            HEX4          => HEX4,
            HEX5          => HEX5,
            TEC1_FIL      => TEC1_FIL,
            TEC1_COL      => TEC1_COL,
            TEC2_FIL      => TEC2_FIL,
            TEC2_COL      => TEC2_COL,
            AUDIO_PWM     => AUDIO_PWM,
            VGA_R         => VGA_R,
            VGA_G         => VGA_G,
            VGA_B         => VGA_B,
            VGA_HS        => VGA_HS,
            VGA_VS        => VGA_VS
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

        -- texto de HEX5 a HEX0
        impure function pantalla return string is
        begin
            return car(HEX5) & car(HEX4) & car(HEX3) & car(HEX2) & car(HEX1) & car(HEX0);
        end function;

        procedure revisa_hex (txt : string(1 to 6); msg : string) is
        begin
            assert pantalla = txt
                report "tb_sinte_top: " & msg & ": HEX = '" & pantalla & "', se esperaba '" & txt & "'"
                severity error;
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

        -- pulsa una tecla 30 ms y la suelta 30 ms (el antirrebote pide 20)
        procedure pulsa (signal p : out std_logic_vector(15 downto 0); k : natural) is
        begin
            p <= (others => '0');
            p(k) <= '1';
            espera_ms(30);
            p <= (others => '0');
            espera_ms(30);
        end procedure;

        procedure boton (n : natural) is
        begin
            KEY(n) <= '0';
            espera_ms(30);
            KEY(n) <= '1';
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
    begin
        -- 1) arranque
        espera_ms(5);
        revisa_hex("Ino4--", "arranque");
        assert LEDR = "0000000000" report "tb_sinte_top: LEDs encendidos al arrancar" severity error;
        silencio(50, "arranque");

        -- 2) A4 en el teclado 1
        report "tb_sinte_top: paso 2 A4";
        pres1(T_AST) <= '1';
        espera_ms(30);
        assert LEDR(0) = '1' report "tb_sinte_top: LEDR0 debe encender con una nota" severity error;
        revisa_hex("Ino4A4", "A4");
        mide(12, f);
        revisa_f(f, 440.0, "A4");

        -- 3) acorde: A4 + D4 (teclado 1) + E5 (teclado 2)
        report "tb_sinte_top: paso 3 acorde";
        pres1(T_3) <= '1';
        pres2(T_5) <= '1';
        espera_ms(30);
        assert LEDR(2 downto 0) = "111" report "tb_sinte_top: el acorde debe usar 3 voces" severity error;

        -- 4) soltar todo: release de 150 ms
        report "tb_sinte_top: paso 4 soltar";
        pres1 <= (others => '0');
        pres2 <= (others => '0');
        espera_ms(190);
        assert LEDR(2 downto 0) = "000" report "tb_sinte_top: las voces deben apagarse" severity error;
        silencio(100, "tras soltar");

        -- 5) octava +: A5 en el teclado 1 y A6 en el teclado 2
        report "tb_sinte_top: paso 5 octavas";
        pulsa(pres1, T_B);
        assert pantalla(1 to 4) = "Ino5" report "tb_sinte_top: la octava debe subir a 5" severity error;
        pres1(T_AST) <= '1';
        espera_ms(30);
        revisa_hex("Ino5A5", "A5");
        mide(12, f);
        revisa_f(f, 880.0, "A5");
        pres2(T_AST) <= '1';
        espera_ms(30);
        revisa_hex("Ino5A6", "A6 en el teclado 2");
        assert LEDR(1 downto 0) = "11" report "tb_sinte_top: A5 y A6 deben sonar juntas" severity error;
        pres1 <= (others => '0');
        pres2 <= (others => '0');
        espera_ms(190);
        pulsa(pres1, T_A);
        assert pantalla(3 to 4) = "o4" report "tb_sinte_top: la octava debe regresar a 4" severity error;

        -- 6) configuracion: forma triangular y release de 20 ms
        report "tb_sinte_top: paso 6 configuracion";
        SW(9 downto 8) <= "11";
        espera_ms(30);
        revisa_hex("CFFo 0", "configuracion");
        pulsa(pres1, T_B);                 -- forma 1 = triangular
        revisa_hex("CFFo 1", "forma triangular");
        for i in 1 to 4 loop
            pulsa(pres1, T_D);             -- hasta release
        end loop;
        revisa_hex("CFrE 1", "release");
        pulsa(pres2, T_A);                 -- release 0 = 20 ms (teclado 2)
        revisa_hex("CFrE 0", "release 20 ms");
        SW(9 downto 8) <= "00";
        espera_ms(30);
        pres1(T_AST) <= '1';
        espera_ms(30);
        mide(12, f);
        revisa_f(f, 440.0, "A4 triangular");
        pres1 <= (others => '0');
        espera_ms(50);
        assert LEDR(2 downto 0) = "000" report "tb_sinte_top: con release de 20 ms ya debe callar" severity error;

        -- 7) grabacion: C4 60 ms, silencio 40 ms, E4 50 ms
        report "tb_sinte_top: paso 7 grabacion";
        SW(9 downto 8) <= "01";
        espera_ms(30);
        revisa_hex("Gr   0", "modo grabacion");
        KEY(0) <= '0';
        wait until LEDR(5) = '1' for 40 ms;
        assert LEDR(5) = '1' report "tb_sinte_top: KEY0 debe iniciar la grabacion" severity error;
        t_g0 := now;
        espera_ms(10);
        KEY(0) <= '1';
        espera_ms(25);
        pres1(T_1) <= '1';
        espera_ms(60);
        pres1 <= (others => '0');
        espera_ms(40);
        pres1(T_5) <= '1';
        espera_ms(50);
        pres1 <= (others => '0');
        espera_ms(30);
        KEY(0) <= '0';
        wait until LEDR(5) = '0' for 40 ms;
        assert LEDR(5) = '0' report "tb_sinte_top: KEY0 debe finalizar la grabacion" severity error;
        t_g1 := now;
        espera_ms(10);
        KEY(0) <= '1';
        espera_ms(25);
        -- silencio inicial, C4, silencio, E4, silencio final
        revisa_hex("Gr   5", "eventos grabados");

        -- reproduccion
        report "tb_sinte_top: paso 7 reproduccion";
        SW(9 downto 8) <= "10";
        espera_ms(30);
        revisa_hex("rP   5", "modo reproduccion");
        KEY(0) <= '0';
        wait until LEDR(6) = '1' for 40 ms;
        assert LEDR(6) = '1' report "tb_sinte_top: KEY0 debe iniciar la reproduccion" severity error;
        t_r0 := now;
        wait until LEDR(0) = '1' for 100 ms;
        mide(8, f);
        revisa_f(f, 261.63, "C4 reproducido");
        KEY(0) <= '1';
        wait until LEDR(6) = '0' for 400 ms;
        assert LEDR(6) = '0' report "tb_sinte_top: la reproduccion debe terminar sola" severity error;
        t_r1 := now;
        assert abs ((t_r1 - t_r0) - (t_g1 - t_g0)) <= 2 ms
            report "tb_sinte_top: la reproduccion no dura lo que la grabacion" severity error;
        espera_ms(5);
        revisa_hex("rP   5", "fin de la reproduccion");

        -- 8) metronomo
        report "tb_sinte_top: paso 8 metronomo";
        SW(9 downto 8) <= "00";
        espera_ms(30);
        KEY(1) <= '0';
        wait until LEDR(4) = '1' for 40 ms;
        assert LEDR(3) = '1' and LEDR(4) = '1'
            report "tb_sinte_top: el metronomo debe encender y marcar el primer tiempo" severity error;
        vio_clic := false;
        for i in 1 to 200 loop
            wait on n_muestra;
            if audio /= 0 then
                vio_clic := true;
            end if;
        end loop;
        assert vio_clic report "tb_sinte_top: el metronomo no sono" severity error;
        KEY(1) <= '1';
        espera_ms(30);
        boton(1);
        assert LEDR(3) = '0' report "tb_sinte_top: KEY1 debe apagar el metronomo" severity error;

        report "tb_sinte_top: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
