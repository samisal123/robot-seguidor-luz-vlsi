-- ============================================================
-- tb_secuenciador.vhd
-- Prueba de grabacion y reproduccion. El "ms" dura per_tick
-- ciclos (10, o 2 en la prueba larga). El testbench cambia las
-- notas un ciclo despues de cada tick, como el teclado real.
-- Un monitor guarda cada cambio de la salida con el numero de
-- tick en que ocurrio; de ahi salen las duraciones exactas.
-- Revisa:
--   1) reproducir sin nada grabado no hace nada
--   2) una grabacion con notas, acordes y silencios guarda los
--      eventos en orden con su duracion exacta (en ms)
--   3) la reproduccion respeta el orden y la duracion de cada
--      evento, termina en silencio y regresa a espera
--   4) posicion durante la grabacion y la reproduccion
--   5) detener la reproduccion a la mitad
--   6) un conjunto de menos de 1 ms, o finalizar justo despues
--      de un cambio, no guarda eventos de duracion 0
--   7) memoria llena: a los 256 eventos se detiene sola y los 256
--      se reproducen
--   8) una nota de mas de 65.5 s se guarda como dos eventos y se
--      reproduce completa
--   9) cambios de notas en el mismo ciclo que un tick no pierden
--      ni duplican milisegundos
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tb_secuenciador is
end entity tb_secuenciador;

architecture sim of tb_secuenciador is
    constant T_CLK : time := 20 ns;

    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal tick_1ms       : std_logic := '0';
    signal cmd_grabar     : std_logic := '0';
    signal cmd_reproducir : std_logic := '0';
    signal cmd_parar      : std_logic := '0';
    signal conjunto       : std_logic_vector(20 downto 0) := (others => '0');
    signal salida         : std_logic_vector(20 downto 0);
    signal estado         : std_logic_vector(1 downto 0);
    signal eventos        : std_logic_vector(8 downto 0);
    signal posicion       : std_logic_vector(8 downto 0);
    signal llena          : std_logic;
    signal fin            : boolean := false;

    signal per_tick : natural := 10;
    signal n_ticks  : natural := 0;

    -- registro de cambios de la salida
    constant MAX_REG : natural := 400;
    type t_sets is array (0 to MAX_REG - 1) of std_logic_vector(20 downto 0);
    type t_nums is array (0 to MAX_REG - 1) of natural;
    signal reg_set   : t_sets;
    signal reg_tick  : t_nums;
    signal n_reg     : natural := 0;
    signal borra_reg : boolean := false;

    function arma (a, b, c : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(c, 7)) & std_logic_vector(to_unsigned(b, 7))
               & std_logic_vector(to_unsigned(a, 7));
    end function;

    constant SILENCIO : std_logic_vector(20 downto 0) := (others => '0');

    -- secuencia de la prueba 2
    constant N_SEC : natural := 7;
    type t_sec_sets is array (0 to N_SEC - 1) of std_logic_vector(20 downto 0);
    type t_sec_durs is array (0 to N_SEC - 1) of natural;
    constant SEC_SET : t_sec_sets := (
        SILENCIO, arma(57, 0, 0), arma(57, 60, 0), SILENCIO,
        arma(59, 0, 0), arma(59, 62, 66), SILENCIO);
    constant SEC_DUR : t_sec_durs := (5, 10, 7, 3, 4, 12, 6);
begin

    clk <= not clk after T_CLK / 2 when not fin;

    -- ticks de per_tick ciclos; n_ticks cuenta los ticks que ya vio el DUT
    process (clk)
        variable c : natural := 0;
    begin
        if rising_edge(clk) then
            tick_1ms <= '0';
            if tick_1ms = '1' then
                n_ticks <= n_ticks + 1;
            end if;
            if c >= per_tick - 1 then
                c := 0;
                tick_1ms <= '1';
            else
                c := c + 1;
            end if;
        end if;
    end process;

    dut : entity work.secuenciador
        port map (
            clk            => clk,
            rst            => rst,
            tick_1ms       => tick_1ms,
            cmd_grabar     => cmd_grabar,
            cmd_reproducir => cmd_reproducir,
            cmd_parar      => cmd_parar,
            conjunto       => conjunto,
            salida         => salida,
            estado         => estado,
            eventos        => eventos,
            posicion       => posicion,
            llena          => llena
        );

    monitor : process (clk)
        variable ant : std_logic_vector(20 downto 0) := (others => '0');
        variable n   : natural := 0;
    begin
        if rising_edge(clk) then
            if borra_reg then
                n := 0;
            elsif salida /= ant and n < MAX_REG then
                reg_set(n)  <= salida;
                reg_tick(n) <= n_ticks;
                n := n + 1;
            end if;
            ant := salida;
            n_reg <= n;
        end if;
    end process;

    estimulo : process
        procedure tras_tick is
        begin
            wait until rising_edge(clk) and tick_1ms = '1';
            wait for 1 ns;
        end procedure;

        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;

        procedure pulso (signal s : out std_logic) is
        begin
            s <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            s <= '0';
        end procedure;

        -- mantiene un conjunto de notas durante ms ticks
        procedure toca (c : std_logic_vector(20 downto 0); ms : natural) is
        begin
            conjunto <= c;
            for i in 1 to ms loop
                tras_tick;
            end loop;
        end procedure;

        procedure limpia_registro is
        begin
            borra_reg <= true;
            ciclos(1);
            borra_reg <= false;
        end procedure;

        variable dur  : natural;
        variable t0   : natural;
        variable tfin : natural;
    begin
        rst <= '1';
        ciclos(5);
        rst <= '0';
        ciclos(2);

        -- 1) reproducir sin grabacion
        tras_tick;
        pulso(cmd_reproducir);
        ciclos(5);
        assert estado = S_ESPERA and salida = SILENCIO
            report "tb_secuenciador: sin eventos no debe reproducir" severity error;

        -- 2) grabacion
        tras_tick;
        conjunto <= SEC_SET(0);
        pulso(cmd_grabar);
        assert estado = S_GRABANDO report "tb_secuenciador: debe estar grabando" severity error;
        for i in 0 to N_SEC - 1 loop
            toca(SEC_SET(i), SEC_DUR(i));
            -- 4) posicion durante la grabacion = eventos guardados
            assert to_integer(unsigned(posicion)) = i
                report "tb_secuenciador: posicion al grabar incorrecta" severity error;
        end loop;
        pulso(cmd_parar);
        ciclos(2);
        assert estado = S_ESPERA report "tb_secuenciador: al finalizar debe esperar" severity error;
        assert to_integer(unsigned(eventos)) = N_SEC
            report "tb_secuenciador: se esperaban 7 eventos y hay "
                   & integer'image(to_integer(unsigned(eventos))) severity error;
        assert llena = '0' report "tb_secuenciador: no debe estar llena" severity error;

        -- 3) reproduccion
        limpia_registro;
        tras_tick;
        pulso(cmd_reproducir);
        t0 := n_ticks;
        ciclos(3);
        assert estado = S_REPRODUCE report "tb_secuenciador: debe reproducir" severity error;
        -- 4) posicion durante la reproduccion (a mitad del evento 3)
        for i in 1 to 5 + 10 + 3 loop
            tras_tick;
        end loop;
        ciclos(3);
        assert to_integer(unsigned(posicion)) = 3
            report "tb_secuenciador: posicion al reproducir incorrecta" severity error;
        wait until estado = S_ESPERA for 1 ms;
        tfin := n_ticks;
        ciclos(2);
        assert estado = S_ESPERA and salida = SILENCIO
            report "tb_secuenciador: al terminar debe quedar en espera y en silencio" severity error;
        -- primer y ultimo evento (silencios): contra el inicio y el fin
        assert reg_tick(0) - t0 = SEC_DUR(0)
            report "tb_secuenciador: el silencio inicial duro " & integer'image(reg_tick(0) - t0)
            severity error;
        assert tfin - reg_tick(N_SEC - 2) = SEC_DUR(N_SEC - 1)
            report "tb_secuenciador: el silencio final duro "
                   & integer'image(tfin - reg_tick(N_SEC - 2)) severity error;
        -- cambios: silencio inicial no es cambio (la salida ya era 0),
        -- luego los eventos 1 a 6 y el silencio final (evento 6)
        assert n_reg = N_SEC - 1
            report "tb_secuenciador: cambios de salida: " & integer'image(n_reg) severity error;
        for i in 1 to N_SEC - 1 loop
            assert reg_set(i - 1) = SEC_SET(i)
                report "tb_secuenciador: evento " & integer'image(i) & " con notas incorrectas"
                severity error;
        end loop;
        for i in 1 to N_SEC - 2 loop
            dur := reg_tick(i) - reg_tick(i - 1);
            assert dur = SEC_DUR(i)
                report "tb_secuenciador: evento " & integer'image(i) & " duro " & integer'image(dur)
                       & " ms en vez de " & integer'image(SEC_DUR(i)) severity error;
        end loop;

        -- 5) detener a la mitad
        tras_tick;
        pulso(cmd_reproducir);
        for i in 1 to 12 loop
            tras_tick;
        end loop;
        assert salida = SEC_SET(1) report "tb_secuenciador: debe sonar el evento 1" severity error;
        pulso(cmd_parar);
        ciclos(1);
        assert estado = S_ESPERA and salida = SILENCIO
            report "tb_secuenciador: detener debe dejar silencio y espera" severity error;

        -- 6) un conjunto que dura menos de un ms (dos cambios entre
        -- dos ticks) y finalizar justo despues de un cambio: ninguno
        -- de los dos se guarda (duracion 0)
        tras_tick;
        conjunto <= arma(50, 0, 0);
        pulso(cmd_grabar);
        toca(arma(50, 0, 0), 5);
        conjunto <= arma(51, 0, 0);
        ciclos(2);
        toca(arma(53, 0, 0), 4);
        conjunto <= arma(52, 0, 0);
        ciclos(1);
        pulso(cmd_parar);
        ciclos(2);
        assert to_integer(unsigned(eventos)) = 2
            report "tb_secuenciador: no se deben guardar eventos de 0 ms ("
                   & integer'image(to_integer(unsigned(eventos))) & " eventos)" severity error;

        -- 7) memoria llena
        tras_tick;
        conjunto <= arma(40, 0, 0);
        pulso(cmd_grabar);
        for i in 0 to 299 loop
            if i mod 2 = 0 then
                toca(arma(40, 0, 0), 1);
            else
                toca(arma(41, 0, 0), 1);
            end if;
            if i = 256 then
                assert estado = S_ESPERA and llena = '1'
                    report "tb_secuenciador: con 256 eventos debe detenerse sola" severity error;
            end if;
        end loop;
        assert to_integer(unsigned(eventos)) = 256 and llena = '1'
            report "tb_secuenciador: deben quedar 256 eventos" severity error;
        conjunto <= SILENCIO;
        limpia_registro;
        tras_tick;
        pulso(cmd_reproducir);
        wait until estado = S_ESPERA for 1 ms;
        ciclos(2);
        assert n_reg = 257
            report "tb_secuenciador: se esperaban 257 cambios y hubo " & integer'image(n_reg)
            severity error;
        for i in 0 to 255 loop
            if i mod 2 = 0 then
                assert reg_set(i) = arma(40, 0, 0) report "tb_secuenciador: evento par" severity error;
            else
                assert reg_set(i) = arma(41, 0, 0) report "tb_secuenciador: evento impar" severity error;
            end if;
            assert reg_tick(i + 1) - reg_tick(i) = 1
                report "tb_secuenciador: los eventos de memoria llena duran 1 ms" severity error;
        end loop;
        assert reg_set(256) = SILENCIO report "tb_secuenciador: debe terminar en silencio" severity error;

        -- 9) cambios de notas en el mismo ciclo que un tick: ningun
        -- ms se pierde ni se cuenta dos veces (la reproduccion dura
        -- exactamente lo que duro la grabacion)
        tras_tick;
        conjunto <= arma(60, 0, 0);
        pulso(cmd_grabar);
        t0 := n_ticks;
        for i in 1 to 3 loop
            tras_tick;
            tras_tick;
            ciclos(per_tick - 1);          -- el cambio cae en el siguiente tick
            conjunto <= arma(60 + i, 0, 0);
        end loop;
        tras_tick;
        tras_tick;
        pulso(cmd_parar);
        dur := n_ticks - t0;               -- ms que duro la grabacion
        ciclos(2);
        assert to_integer(unsigned(eventos)) = 4
            report "tb_secuenciador: se esperaban 4 eventos alineados con el tick" severity error;
        conjunto <= SILENCIO;
        limpia_registro;
        tras_tick;
        pulso(cmd_reproducir);
        t0 := n_ticks;
        wait until estado = S_ESPERA for 1 ms;
        tfin := n_ticks;
        assert tfin - t0 = dur
            report "tb_secuenciador: con cambios en el tick la reproduccion duro "
                   & integer'image(tfin - t0) & " ms en vez de " & integer'image(dur) severity error;

        -- 8) nota de 65 635 ms (tick de 2 ciclos)
        per_tick <= 2;
        tras_tick;
        tras_tick;
        conjunto <= arma(45, 0, 0);
        pulso(cmd_grabar);
        toca(arma(45, 0, 0), 65535 + 100);
        pulso(cmd_parar);
        ciclos(2);
        assert to_integer(unsigned(eventos)) = 2
            report "tb_secuenciador: la nota larga debe quedar en 2 eventos" severity error;
        conjunto <= SILENCIO;
        limpia_registro;
        tras_tick;
        pulso(cmd_reproducir);
        t0 := n_ticks;
        wait until estado = S_ESPERA for 10 ms;
        ciclos(2);
        assert n_reg = 2 and reg_set(0) = arma(45, 0, 0) and reg_set(1) = SILENCIO
            report "tb_secuenciador: la nota larga debe sonar sin cortes" severity error;
        assert reg_tick(0) - t0 <= 1
            report "tb_secuenciador: la nota larga empezo tarde" severity error;
        assert reg_tick(1) - t0 = 65535 + 100
            report "tb_secuenciador: la nota larga duro " & integer'image(reg_tick(1) - t0)
            severity error;

        report "tb_secuenciador: OK";
        fin <= true;
        wait;
    end process;

end architecture sim;
