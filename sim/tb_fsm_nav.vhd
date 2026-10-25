-- ============================================================
-- tb_fsm_nav.vhd
-- Escenarios de la FSM principal con los tiempos por defecto y
-- tick_1ms cada 2 ciclos (1 ms del robot = 20 ns de simulacion):
--   arranque, busqueda (giro y tramo), seguimiento con cada
--   direccion de luz, esquiva con rodeo, esquina, atasco y
--   escape, luz perdida, meta junto a la lampara, giro maximo de
--   esquiva -> esquina, y paro con KEY0 desde cualquier estado.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.robot_pkg.all;

entity tb_fsm_nav is
end entity tb_fsm_nav;

architecture sim of tb_fsm_nav is
    constant T_CLK : time := 10 ns;
    constant T_MS  : time := 2 * T_CLK;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal tick_1ms   : std_logic := '0';
    signal arranque   : std_logic := '0';
    signal hay_luz    : std_logic := '0';
    signal luz_cerca  : std_logic := '0';
    signal dir_luz    : std_logic_vector(2 downto 0) := D_NINGUNA;
    signal obs        : std_logic_vector(3 downto 0) := "0000";
    signal lado_libre : std_logic := '0';
    signal atasco     : std_logic := '0';
    signal estado, accion, evento : std_logic_vector(2 downto 0);
    signal ev_nuevo, moviendo     : std_logic;
    signal n_ev       : natural := 0;
    signal fin        : boolean := false;

    function img (v : std_logic_vector) return string is
        variable s : string(1 to v'length);
        variable k : natural := 1;
    begin
        for i in v'range loop
            if v(i) = '1' then s(k) := '1'; else s(k) := '0'; end if;
            k := k + 1;
        end loop;
        return s;
    end function;
begin

    clk <= not clk after T_CLK / 2 when not fin;

    process (clk)
    begin
        if rising_edge(clk) then
            tick_1ms <= not tick_1ms;
            if ev_nuevo = '1' then
                n_ev <= n_ev + 1;
            end if;
        end if;
    end process;

    dut : entity work.fsm_nav
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, arranque => arranque,
                  hay_luz => hay_luz, luz_cerca => luz_cerca, dir_luz => dir_luz,
                  obs => obs, lado_libre => lado_libre, atasco => atasco,
                  estado => estado, accion => accion, evento => evento,
                  ev_nuevo => ev_nuevo, moviendo => moviendo);

    estimulo : process
        procedure espera_ms (n : natural) is
        begin
            wait for n * T_MS;
        end procedure;

        procedure pulso (signal s : out std_logic) is
        begin
            wait until rising_edge(clk);
            s <= '1';
            wait until rising_edge(clk);
            s <= '0';
            wait for 3 * T_CLK;
        end procedure;

        -- Las salidas de la FSM van registradas: 2 ciclos despues de
        -- un cambio de entrada; se esperan 3 antes de revisar
        procedure revisa (e, a : std_logic_vector(2 downto 0); msg : string) is
        begin
            wait for 3 * T_CLK;
            assert estado = e
                report msg & ": estado " & img(estado) & ", se esperaba " & img(e) severity error;
            assert accion = a
                report msg & ": accion " & img(accion) & ", se esperaba " & img(a) severity error;
        end procedure;

        procedure revisa_ev (ev : std_logic_vector(2 downto 0); msg : string) is
        begin
            assert evento = ev
                report msg & ": evento " & img(evento) & ", se esperaba " & img(ev) severity error;
        end procedure;

        variable n0 : natural;
    begin
        wait for 3 * T_CLK;
        rst <= '0';
        wait for 3 * T_CLK;
        revisa(E_INICIO, A_PARO, "Tras reset");
        assert moviendo = '0' report "moviendo en INICIO" severity error;

        -- Arranque y busqueda
        pulso(arranque);
        revisa(E_BUSCAR, A_BUSCA, "Arranque");
        assert moviendo = '1' report "moviendo deberia ser 1 en BUSCAR" severity error;
        espera_ms(2990);
        revisa(E_BUSCAR, A_BUSCA, "Busqueda antes de T_BUSCA");
        espera_ms(20);
        revisa(E_BUSCAR, A_AVANZA, "Tramo de avance");
        espera_ms(1205);
        revisa(E_BUSCAR, A_BUSCA, "Fin del tramo");

        -- Encuentra la luz y la sigue
        n0 := n_ev;
        dir_luz <= D_FRENTE;
        hay_luz <= '1';
        espera_ms(1);
        revisa(E_SEGUIR, A_AVANZA, "Luz al frente");
        revisa_ev(EV_LUZ, "Luz encontrada");
        assert n_ev = n0 + 1 report "Falto el pulso de evento" severity error;
        dir_luz <= D_FRENTE_IZQ; espera_ms(1); revisa(E_SEGUIR, A_CURVA_IZQ, "Frente izq");
        dir_luz <= D_FRENTE_DER; espera_ms(1); revisa(E_SEGUIR, A_CURVA_DER, "Frente der");
        dir_luz <= D_IZQ;        espera_ms(1); revisa(E_SEGUIR, A_GIRO_IZQ,  "Izquierda");
        dir_luz <= D_DER;        espera_ms(1); revisa(E_SEGUIR, A_GIRO_DER,  "Derecha");
        dir_luz <= D_ATRAS;      espera_ms(1); revisa(E_SEGUIR, A_GIRO_IZQ,  "Atras");
        dir_luz <= D_FRENTE;     espera_ms(1); revisa(E_SEGUIR, A_AVANZA,    "Frente");

        -- Obstaculo al frente, derecha mas libre: esquiva y rodea
        lado_libre <= '1';
        obs <= "0001";
        espera_ms(1);
        revisa(E_ESQUIVA, A_GIRO_DER, "Obstaculo al frente");
        revisa_ev(EV_OBSTACULO, "Obstaculo");
        espera_ms(50);
        obs <= "0000";
        espera_ms(50);
        revisa(E_ESQUIVA, A_GIRO_DER, "Giro minimo de esquiva");
        espera_ms(60);
        revisa(E_ESQUIVA, A_AVANZA, "Rodeo");
        espera_ms(710);
        revisa(E_SEGUIR, A_AVANZA, "Fin del rodeo con luz");

        -- Esquina: frente y diagonales ocupadas
        lado_libre <= '0';
        obs <= "0111";
        espera_ms(1);
        revisa(E_ESQUINA, A_REVERSA, "Esquina");
        revisa_ev(EV_ESQUINA, "Esquina");
        obs <= "0000";
        espera_ms(405);
        revisa(E_ESQUINA, A_GIRO_IZQ, "Giro de esquina");
        espera_ms(905);
        revisa(E_SEGUIR, A_AVANZA, "Fin de esquina con luz");

        -- Esquina con la parte de atras ocupada: no da reversa
        obs <= "1111";
        espera_ms(2);
        revisa(E_ESQUINA, A_GIRO_IZQ, "Esquina sin reversa");
        obs <= "0000";
        espera_ms(905);
        revisa(E_SEGUIR, A_AVANZA, "Fin de esquina sin reversa");

        -- Atasco
        pulso(atasco);
        revisa(E_ESCAPE, A_REVERSA, "Atasco");
        revisa_ev(EV_ATASCO, "Atasco");
        espera_ms(605);
        assert estado = E_ESCAPE and (accion = A_GIRO_IZQ or accion = A_GIRO_DER)
            report "Escape: deberia estar girando" severity error;
        espera_ms(1205);
        revisa(E_SEGUIR, A_AVANZA, "Fin del escape (con luz)");

        -- Luz perdida
        hay_luz <= '0';
        dir_luz <= D_NINGUNA;
        espera_ms(1400);
        revisa(E_SEGUIR, A_AVANZA, "Luz perdida antes de T_PERDIDA");
        espera_ms(110);
        revisa(E_BUSCAR, A_BUSCA, "Luz perdida");
        revisa_ev(EV_PERDIDA, "Luz perdida");

        -- Meta: junto a la lampara el frente marca obstaculo
        hay_luz <= '1';
        dir_luz <= D_FRENTE;
        espera_ms(1);
        revisa(E_SEGUIR, A_AVANZA, "Luz de nuevo");
        luz_cerca <= '1';
        obs <= "0001";
        espera_ms(2);
        revisa(E_SEGUIR, A_PARO, "Junto a la lampara no esquiva");
        espera_ms(405);
        revisa(E_META, A_PARO, "Meta");
        revisa_ev(EV_META, "Meta");
        assert moviendo = '0' report "moviendo en META" severity error;
        espera_ms(3000);
        revisa(E_META, A_PARO, "Se queda en META");

        -- KEY0 en META vuelve a INICIO; otra vez arranca
        pulso(arranque);
        revisa(E_INICIO, A_PARO, "KEY0 en META");
        luz_cerca <= '0';
        obs <= "0000";
        pulso(arranque);
        revisa(E_SEGUIR, A_AVANZA, "Arranque con luz");

        -- Esquiva que no termina: a los T_GIRO_MAX_MS pasa a esquina
        lado_libre <= '0';
        obs <= "0001";
        espera_ms(1);
        revisa(E_ESQUIVA, A_GIRO_IZQ, "Esquiva a la izquierda");
        espera_ms(1450);
        revisa(E_ESQUIVA, A_GIRO_IZQ, "Esquiva sin despejar");
        espera_ms(60);
        assert estado = E_ESQUINA report "Giro maximo de esquiva no paso a esquina" severity error;
        revisa_ev(EV_ESQUINA, "Giro maximo");

        -- KEY0 detiene desde cualquier estado
        pulso(arranque);
        revisa(E_INICIO, A_PARO, "Paro con KEY0");

        report "tb_fsm_nav: OK" severity note;
        fin <= true;
        wait;
    end process;

end architecture sim;
