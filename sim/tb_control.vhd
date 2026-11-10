-- ============================================================
-- tb_control.vhd
-- Prueba de la unidad de control.
-- Revisa:
--   1) valores iniciales (interpretacion, cuadrada, attack 0,
--      decay 1, sustain 2, release 1, volumen 3, tempo 2, sin
--      efecto, metronomo apagado, octava 4, parametro forma)
--   2) MODO (teclado 2, A) recorre interpretacion, grabacion,
--      reproduccion y configuracion y da la vuelta
--   3) teclas directas: octava entre 2 y 6, forma y efecto dan la
--      vuelta (teclado 1); volumen siguiente de 0 a 4 y de vuelta a
--      0 (teclado 2, D), tambien en grabacion y reproduccion
--   4) configuracion: C y D del teclado 1 recorren los 7
--      parametros dando la vuelta; A y B cambian el parametro
--      elegido sin salirse de sus limites; en este modo el teclado
--      1 no cambia la octava, la forma ni el efecto
--   5) METRONOMO (teclado 2, C) enciende y apaga el metronomo; no
--      suena mientras se reproduce una secuencia
--   6) ACCION (teclado 2, B): graba solo en modo grabacion y
--      reproduce solo en modo reproduccion, desde espera; con el
--      secuenciador ocupado manda parar
--   7) cambiar de modo a mitad de una grabacion o reproduccion
--      manda parar
--   8) reset regresa a interpretacion
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_control is
end entity tb_control;

architecture sim of tb_control is
    constant T_CLK : time := 20 ns;

    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal func           : std_logic_vector(7 downto 0) := (others => '0');
    signal estado_sec     : std_logic_vector(1 downto 0) := S_ESPERA;
    signal modo           : std_logic_vector(1 downto 0);
    signal forma          : std_logic_vector(1 downto 0);
    signal atk            : std_logic_vector(1 downto 0);
    signal dec            : std_logic_vector(1 downto 0);
    signal sus            : std_logic_vector(1 downto 0);
    signal rel            : std_logic_vector(1 downto 0);
    signal volumen        : std_logic_vector(2 downto 0);
    signal tempo          : std_logic_vector(1 downto 0);
    signal efecto         : std_logic_vector(1 downto 0);
    signal metro_on       : std_logic;
    signal metro_suena    : std_logic;
    signal octava         : std_logic_vector(2 downto 0);
    signal parametro      : std_logic_vector(2 downto 0);
    signal cmd_grabar     : std_logic;
    signal cmd_reproducir : std_logic;
    signal cmd_parar      : std_logic;
    signal fin            : boolean := false;

    -- teclas de funcion
    constant K1_A : natural := 0;   -- octava - / valor -
    constant K1_B : natural := 1;   -- octava + / valor +
    constant K1_C : natural := 2;   -- forma / parametro anterior
    constant K1_D : natural := 3;   -- efecto / parametro siguiente
    constant K_MODO   : natural := 4;
    constant K_ACCION : natural := 5;
    constant K_METRO  : natural := 6;
    constant K_VOL    : natural := 7;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    dut : entity work.control
        port map (
            clk            => clk,
            rst            => rst,
            func           => func,
            estado_sec     => estado_sec,
            modo           => modo,
            forma          => forma,
            atk            => atk,
            dec            => dec,
            sus            => sus,
            rel            => rel,
            volumen        => volumen,
            tempo          => tempo,
            efecto         => efecto,
            metro_on       => metro_on,
            metro_suena    => metro_suena,
            octava         => octava,
            parametro      => parametro,
            cmd_grabar     => cmd_grabar,
            cmd_reproducir => cmd_reproducir,
            cmd_parar      => cmd_parar
        );

    estimulo : process
        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;

        procedure tecla (k : natural; veces : natural := 1) is
        begin
            for i in 1 to veces loop
                func(k) <= '1';
                ciclos(1);
                func(k) <= '0';
                ciclos(2);
            end loop;
        end procedure;

        procedure revisa (v : std_logic_vector; esperado : natural; msg : string) is
        begin
            assert to_integer(unsigned(v)) = esperado
                report "tb_control: " & msg & " = " & integer'image(to_integer(unsigned(v)))
                       & ", se esperaba " & integer'image(esperado) severity error;
        end procedure;

        -- MODO las veces necesarias para llegar al modo m
        procedure ir_a (m : std_logic_vector(1 downto 0)) is
        begin
            for i in 1 to 4 loop
                exit when modo = m;
                tecla(K_MODO);
            end loop;
            assert modo = m report "tb_control: no se llego al modo pedido" severity error;
        end procedure;

        -- pulso de ACCION y cuenta las ordenes que salen
        procedure accion_y_mira (g, r, p : out natural) is
            variable cg, cr, cp : natural := 0;
        begin
            func(K_ACCION) <= '1';
            ciclos(1);
            func(K_ACCION) <= '0';
            for i in 1 to 4 loop
                if cmd_grabar = '1' then cg := cg + 1; end if;
                if cmd_reproducir = '1' then cr := cr + 1; end if;
                if cmd_parar = '1' then cp := cp + 1; end if;
                ciclos(1);
            end loop;
            g := cg;
            r := cr;
            p := cp;
        end procedure;

        variable g, r, p : natural;
        type t_lim is array (0 to N_PARAM - 1) of natural;
        constant MAXIMO : t_lim := (3, 3, 3, 3, 3, 4, 3);

        impure function valor (par : natural) return natural is
        begin
            case par is
                when P_FORMA   => return to_integer(unsigned(forma));
                when P_ATTACK  => return to_integer(unsigned(atk));
                when P_DECAY   => return to_integer(unsigned(dec));
                when P_SUSTAIN => return to_integer(unsigned(sus));
                when P_RELEASE => return to_integer(unsigned(rel));
                when P_VOLUMEN => return to_integer(unsigned(volumen));
                when others    => return to_integer(unsigned(tempo));
            end case;
        end function;
    begin
        rst <= '1';
        ciclos(3);
        rst <= '0';
        ciclos(2);

        -- 1) valores iniciales
        assert modo = M_INT report "tb_control: el modo inicial debe ser interpretacion" severity error;
        revisa(forma, 0, "forma inicial");
        revisa(atk, 0, "attack inicial");
        revisa(dec, 1, "decay inicial");
        revisa(sus, 2, "sustain inicial");
        revisa(rel, 1, "release inicial");
        revisa(volumen, 3, "volumen inicial");
        revisa(tempo, 2, "tempo inicial");
        revisa(efecto, 0, "efecto inicial");
        revisa(octava, 4, "octava inicial");
        revisa(parametro, P_FORMA, "parametro inicial");
        assert metro_on = '0' report "tb_control: el metronomo inicia apagado" severity error;

        -- 2) MODO recorre los 4 modos
        tecla(K_MODO);
        assert modo = M_GRA report "tb_control: MODO 1 vez -> grabacion" severity error;
        tecla(K_MODO);
        assert modo = M_REP report "tb_control: MODO 2 veces -> reproduccion" severity error;
        tecla(K_MODO);
        assert modo = M_CONF report "tb_control: MODO 3 veces -> configuracion" severity error;
        tecla(K_MODO);
        assert modo = M_INT report "tb_control: MODO 4 veces -> interpretacion" severity error;
        -- mantener la tecla no avanza mas de una vez (func es un pulso)
        func(K_MODO) <= '1';
        ciclos(1);
        func(K_MODO) <= '0';
        ciclos(5);
        assert modo = M_GRA report "tb_control: un pulso de MODO avanza un solo modo" severity error;
        ir_a(M_INT);

        -- 3) teclas directas (modo interpretacion)
        tecla(K1_B, 5);
        revisa(octava, 6, "octava maxima");
        tecla(K1_A, 7);
        revisa(octava, 2, "octava minima");
        tecla(K1_B, 2);
        revisa(octava, 4, "octava tras subir 2");
        tecla(K1_C, 1);
        revisa(forma, 1, "forma siguiente");
        tecla(K1_C, 3);
        revisa(forma, 0, "la forma da la vuelta");
        tecla(K1_D, 3);
        revisa(efecto, 3, "efecto siguiente");
        tecla(K1_D, 1);
        revisa(efecto, 0, "el efecto da la vuelta");
        tecla(K_VOL, 1);
        revisa(volumen, 4, "volumen siguiente (3 -> 4)");
        tecla(K_VOL, 1);
        revisa(volumen, 0, "el volumen da la vuelta a 0 (silencio)");
        tecla(K_VOL, 3);
        revisa(volumen, 3, "volumen tras 3 pasos");
        -- las teclas directas tambien sirven en grabacion y reproduccion
        ir_a(M_GRA);
        tecla(K1_A, 1);
        revisa(octava, 3, "octava en grabacion");
        tecla(K_VOL, 1);
        revisa(volumen, 4, "volumen en grabacion");
        ir_a(M_REP);
        tecla(K1_B, 1);
        revisa(octava, 4, "octava en reproduccion");
        tecla(K_VOL, 4);
        revisa(volumen, 3, "volumen en reproduccion");

        -- 4) configuracion
        ir_a(M_CONF);
        tecla(K1_A, 1);
        tecla(K1_B, 1);
        revisa(octava, 4, "en configuracion el teclado 1 no cambia la octava");
        revisa(parametro, P_FORMA, "parametro tras A/B");
        for i in 1 to N_PARAM + 1 loop
            tecla(K1_D, 1);
        end loop;
        revisa(parametro, 1, "parametro siguiente da la vuelta");
        tecla(K1_C, 1);
        revisa(parametro, 0, "parametro anterior");
        tecla(K1_C, 1);
        revisa(parametro, N_PARAM - 1, "parametro anterior da la vuelta");
        tecla(K1_D, 1);
        revisa(parametro, 0, "de vuelta a la forma");
        revisa(efecto, 0, "en configuracion D no cambia el efecto");
        -- cada parametro: bajar al minimo, subir al maximo (y no pasarse)
        for par in 0 to N_PARAM - 1 loop
            revisa(parametro, par, "parametro en recorrido");
            tecla(K1_A, 6);
            assert valor(par) = 0
                report "tb_control: el parametro " & integer'image(par) & " no llego a 0" severity error;
            tecla(K1_B, 6);
            assert valor(par) = MAXIMO(par)
                report "tb_control: el parametro " & integer'image(par) & " no llego a su maximo"
                severity error;
            tecla(K1_A, 1);
            assert valor(par) = MAXIMO(par) - 1
                report "tb_control: el parametro " & integer'image(par) & " no bajo 1" severity error;
            tecla(K1_D, 1);
        end loop;
        revisa(parametro, P_FORMA, "el recorrido regresa a la forma");
        revisa(forma, 2, "forma tras recorrido");
        revisa(volumen, 3, "volumen tras recorrido");
        revisa(tempo, 2, "tempo tras recorrido");

        -- 5) metronomo
        ir_a(M_INT);
        tecla(K_METRO);
        assert metro_on = '1' report "tb_control: METRONOMO debe encender el metronomo" severity error;
        assert metro_suena = '1' report "tb_control: el metronomo debe sonar en espera" severity error;
        estado_sec <= S_GRABANDO;
        ciclos(1);
        assert metro_suena = '1' report "tb_control: el metronomo debe sonar al grabar" severity error;
        estado_sec <= S_REPRODUCE;
        ciclos(1);
        assert metro_suena = '0' report "tb_control: el metronomo calla al reproducir" severity error;
        estado_sec <= S_ESPERA;
        ciclos(1);
        tecla(K_METRO);
        assert metro_on = '0' report "tb_control: METRONOMO debe apagar el metronomo" severity error;

        -- 6) ACCION segun el modo, con el secuenciador en espera
        estado_sec <= S_ESPERA;
        ir_a(M_INT);
        accion_y_mira(g, r, p);
        assert g = 0 and r = 0 and p = 0 report "tb_control: ACCION no hace nada en interpretacion" severity error;
        ir_a(M_CONF);
        accion_y_mira(g, r, p);
        assert g = 0 and r = 0 and p = 0 report "tb_control: ACCION no hace nada en configuracion" severity error;
        ir_a(M_GRA);
        accion_y_mira(g, r, p);
        assert g = 1 and r = 0 and p = 0 report "tb_control: ACCION debe grabar en grabacion" severity error;
        ir_a(M_REP);
        accion_y_mira(g, r, p);
        assert g = 0 and r = 1 and p = 0 report "tb_control: ACCION debe reproducir en reproduccion" severity error;
        -- secuenciador ocupado: ACCION manda parar
        estado_sec <= S_REPRODUCE;
        ciclos(3);
        accion_y_mira(g, r, p);
        assert g = 0 and r = 0 and p = 1 report "tb_control: ACCION debe detener la reproduccion" severity error;
        estado_sec <= S_ESPERA;
        ir_a(M_GRA);
        estado_sec <= S_GRABANDO;
        ciclos(3);
        accion_y_mira(g, r, p);
        assert g = 0 and r = 0 and p = 1 report "tb_control: ACCION debe finalizar la grabacion" severity error;

        -- 7) cambiar de modo a mitad: de grabacion a reproduccion
        tecla(K_MODO);
        assert modo = M_REP report "tb_control: MODO durante la grabacion" severity error;
        ciclos(1);
        assert cmd_parar = '1' report "tb_control: salir de grabacion debe parar" severity error;
        -- de reproduccion a configuracion
        estado_sec <= S_REPRODUCE;
        ciclos(2);
        tecla(K_MODO);
        ciclos(1);
        assert cmd_parar = '1' report "tb_control: salir de reproduccion debe parar" severity error;
        estado_sec <= S_ESPERA;
        ciclos(2);
        assert cmd_parar = '0' report "tb_control: en espera no debe parar" severity error;

        -- 8) reset
        assert modo = M_CONF report "tb_control: se esperaba configuracion antes del reset" severity error;
        rst <= '1';
        ciclos(2);
        rst <= '0';
        ciclos(1);
        assert modo = M_INT report "tb_control: el reset regresa a interpretacion" severity error;
        revisa(volumen, 3, "volumen tras reset");

        report "tb_control: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
