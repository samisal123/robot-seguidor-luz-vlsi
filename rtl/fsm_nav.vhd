-- ============================================================
-- fsm_nav.vhd
-- FSM principal del robot (7 estados). Decide la accion de
-- movimiento a partir de la luz, los obstaculos y el atasco.
--
--   INICIO   motores parados; KEY0 (arranque) pasa a BUSCAR.
--   BUSCAR   fase 0: gira despacio en su lugar T_BUSCA_MS;
--            fase 1: si el frente esta libre avanza T_TRAMO_MS
--            y vuelve a girar.
--   SEGUIR   avanza corrigiendo el rumbo segun dir_luz.
--   ESQUIVA  fase 0: gira hacia el lado mas libre hasta que el
--            frente y esa diagonal se despejan (minimo
--            T_GIRO_MIN_MS; si pasa T_GIRO_MAX_MS es esquina);
--            fase 1: avanza T_RODEO_MS para rodear.
--   ESQUINA  fase 0: reversa T_REVERSA_MS si atras esta libre;
--            fase 1: gira T_GIRO_ESQ_MS (unos 135 grados).
--   ESCAPE   fase 0: reversa T_ESC_REV_MS si atras esta libre;
--            fase 1: gira hacia un lado al azar (LFSR) un tiempo
--            al azar entre T_ESC_GIRO_MS y T_ESC_GIRO_MS+700.
--   META     motores parados.
--
-- arranque (pulso) detiene al robot desde cualquier estado
-- (vuelve a INICIO) y lo arranca desde INICIO.
-- La meta tiene prioridad sobre la evasion: junto al foco el
-- sensor del frente ve la base de la lampara como obstaculo. En
-- SEGUIR con luz cerca no esquiva (se detiene y espera
-- T_META_MS); si ya estaba esquivando, la meta tambien cuenta.
-- Los tiempos son generics en ms para calibrarlos en la arena.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity fsm_nav is
    generic (
        T_BUSCA_MS    : positive := 3000;
        T_TRAMO_MS    : positive := 1200;
        T_PERDIDA_MS  : positive := 1500;
        T_META_MS     : positive := 400;
        T_GIRO_MIN_MS : positive := 150;
        T_GIRO_MAX_MS : positive := 1500;
        T_RODEO_MS    : positive := 700;
        T_REVERSA_MS  : positive := 400;
        T_GIRO_ESQ_MS : positive := 900;
        T_ESC_REV_MS  : positive := 600;
        T_ESC_GIRO_MS : positive := 500
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        tick_1ms   : in  std_logic;
        arranque   : in  std_logic;   -- pulso de un ciclo
        hay_luz    : in  std_logic;
        luz_cerca  : in  std_logic;
        dir_luz    : in  std_logic_vector(2 downto 0);
        obs        : in  std_logic_vector(3 downto 0);
        lado_libre : in  std_logic;   -- '1' derecha mas libre
        atasco     : in  std_logic;   -- pulso de stall_detect
        estado     : out std_logic_vector(2 downto 0);
        accion     : out std_logic_vector(2 downto 0);
        evento     : out std_logic_vector(2 downto 0);  -- ultimo evento
        ev_nuevo   : out std_logic;                     -- pulso por evento
        moviendo   : out std_logic
    );
end entity fsm_nav;

architecture rtl of fsm_nav is
    type t_estado is (INICIO, BUSCAR, SEGUIR, ESQUIVA, ESQUINA, ESCAPE, META);
    constant T_MAX : natural := 16383;

    signal est     : t_estado := INICIO;
    signal fase    : std_logic := '0';
    signal t       : natural range 0 to T_MAX := 0;  -- ms en la fase actual
    signal t_cerca : natural range 0 to T_MAX := 0;  -- ms seguidos con luz cerca
    signal t_sin   : natural range 0 to T_MAX := 0;  -- ms seguidos sin luz
    signal t_lim   : natural range 0 to T_MAX := T_ESC_GIRO_MS;
    signal lado    : std_logic := '0';               -- '0' izquierda, '1' derecha
    signal lfsr    : std_logic_vector(7 downto 0) := "10101101";
    signal s_ev    : std_logic_vector(2 downto 0) := EV_NINGUNO;
    signal s_evn   : std_logic := '0';
    signal s_acc   : std_logic_vector(2 downto 0) := A_PARO;
    signal s_est   : std_logic_vector(2 downto 0) := E_INICIO;

    function frente_bloqueado (o : std_logic_vector(3 downto 0)) return boolean is
    begin
        return o(S_FRENTE) = '1' or o(S_DIAG_IZQ) = '1' or o(S_DIAG_DER) = '1';
    end function;

    -- Lado hacia el que conviene girar: lejos de la diagonal ocupada
    function elegir_lado (o : std_logic_vector(3 downto 0); libre : std_logic)
        return std_logic is
    begin
        if o(S_DIAG_IZQ) = '1' and o(S_DIAG_DER) = '0' then
            return '1';
        elsif o(S_DIAG_DER) = '1' and o(S_DIAG_IZQ) = '0' then
            return '0';
        else
            return libre;
        end if;
    end function;

    function giro (l : std_logic) return std_logic_vector is
    begin
        if l = '1' then
            return A_GIRO_DER;
        else
            return A_GIRO_IZQ;
        end if;
    end function;
begin

    -- ---------------- Transiciones ----------------
    process (clk)
        procedure ir (e : t_estado; ev : std_logic_vector(2 downto 0)) is
        begin
            est  <= e;
            fase <= '0';
            t    <= 0;
            if ev /= EV_NINGUNO then
                s_ev  <= ev;
                s_evn <= '1';
            end if;
        end procedure;

        procedure siguiente_fase is
        begin
            fase <= '1';
            t    <= 0;
        end procedure;

        procedure entrar_esquiva is
        begin
            if obs(S_FRENTE) = '1' and obs(S_DIAG_IZQ) = '1' and obs(S_DIAG_DER) = '1' then
                ir(ESQUINA, EV_ESQUINA);
                lado <= lado_libre;
            else
                ir(ESQUIVA, EV_OBSTACULO);
                lado <= elegir_lado(obs, lado_libre);
            end if;
        end procedure;

        procedure entrar_escape is
        begin
            ir(ESCAPE, EV_ATASCO);
            lado  <= lfsr(0);
            t_lim <= T_ESC_GIRO_MS + 100 * to_integer(unsigned(lfsr(6 downto 4)));
        end procedure;
    begin
        if rising_edge(clk) then
            s_evn <= '0';
            lfsr  <= lfsr(6 downto 0) & (lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3));

            -- Contadores de ms (las transiciones de abajo pueden reiniciarlos)
            if tick_1ms = '1' and t < T_MAX then
                t <= t + 1;
            end if;
            if luz_cerca = '0' then
                t_cerca <= 0;
            elsif tick_1ms = '1' and t_cerca < T_MAX then
                t_cerca <= t_cerca + 1;
            end if;
            if hay_luz = '1' then
                t_sin <= 0;
            elsif tick_1ms = '1' and t_sin < T_MAX then
                t_sin <= t_sin + 1;
            end if;

            if rst = '1' then
                est  <= INICIO;
                fase <= '0';
                t    <= 0;
                lado <= '0';
                s_ev <= EV_NINGUNO;
            elsif arranque = '1' then
                if est = INICIO then
                    ir(BUSCAR, EV_NINGUNO);
                else
                    ir(INICIO, EV_NINGUNO);
                end if;
            else
                case est is
                    when INICIO =>
                        null;

                    when BUSCAR =>
                        if atasco = '1' then
                            entrar_escape;
                        elsif hay_luz = '1' then
                            ir(SEGUIR, EV_LUZ);
                        elsif fase = '0' then
                            if t >= T_BUSCA_MS and obs(S_FRENTE) = '0' then
                                siguiente_fase;
                            end if;
                        elsif frente_bloqueado(obs) then
                            entrar_esquiva;
                        elsif t >= T_TRAMO_MS then
                            fase <= '0';
                            t    <= 0;
                        end if;

                    when SEGUIR =>
                        if atasco = '1' then
                            entrar_escape;
                        elsif luz_cerca = '1' and t_cerca >= T_META_MS then
                            ir(META, EV_META);
                        elsif frente_bloqueado(obs) and luz_cerca = '0' then
                            entrar_esquiva;
                        elsif hay_luz = '0' and t_sin >= T_PERDIDA_MS then
                            ir(BUSCAR, EV_PERDIDA);
                        end if;

                    when ESQUIVA =>
                        if atasco = '1' then
                            entrar_escape;
                        elsif luz_cerca = '1' and t_cerca >= T_META_MS then
                            ir(META, EV_META);   -- esquivando la base de la lampara
                        elsif fase = '0' then
                            if t >= T_GIRO_MAX_MS then
                                ir(ESQUINA, EV_ESQUINA);
                            elsif t >= T_GIRO_MIN_MS and obs(S_FRENTE) = '0' and
                                  ((lado = '0' and obs(S_DIAG_IZQ) = '0') or
                                   (lado = '1' and obs(S_DIAG_DER) = '0')) then
                                siguiente_fase;
                            end if;
                        elsif frente_bloqueado(obs) then
                            fase <= '0';
                            t    <= 0;
                            lado <= elegir_lado(obs, lado_libre);
                        elsif t >= T_RODEO_MS then
                            if hay_luz = '1' then
                                ir(SEGUIR, EV_NINGUNO);
                            else
                                ir(BUSCAR, EV_NINGUNO);
                            end if;
                        end if;

                    when ESQUINA =>
                        if atasco = '1' then
                            entrar_escape;
                        elsif fase = '0' then
                            if obs(S_ATRAS) = '1' or t >= T_REVERSA_MS then
                                siguiente_fase;
                            end if;
                        elsif t >= T_GIRO_ESQ_MS then
                            if hay_luz = '1' then
                                ir(SEGUIR, EV_NINGUNO);
                            else
                                ir(BUSCAR, EV_NINGUNO);
                            end if;
                        end if;

                    when ESCAPE =>
                        if fase = '0' then
                            if obs(S_ATRAS) = '1' or t >= T_ESC_REV_MS then
                                siguiente_fase;
                            end if;
                        elsif t >= t_lim then
                            ir(BUSCAR, EV_NINGUNO);
                        end if;

                    when META =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- ---------------- Salidas (registradas) ----------------
    process (clk)
    begin
        if rising_edge(clk) then
            case est is
                when INICIO =>
                    s_est <= E_INICIO;
                    s_acc <= A_PARO;
                when BUSCAR =>
                    s_est <= E_BUSCAR;
                    if fase = '0' then
                        s_acc <= A_BUSCA;
                    else
                        s_acc <= A_AVANZA;
                    end if;
                when SEGUIR =>
                    s_est <= E_SEGUIR;
                    if luz_cerca = '1' and obs(S_FRENTE) = '1' then
                        s_acc <= A_PARO;          -- junto al foco: espera la meta
                    else
                        case dir_luz is
                            when D_FRENTE_IZQ => s_acc <= A_CURVA_IZQ;
                            when D_FRENTE_DER => s_acc <= A_CURVA_DER;
                            when D_IZQ        => s_acc <= A_GIRO_IZQ;
                            when D_DER        => s_acc <= A_GIRO_DER;
                            when D_ATRAS      => s_acc <= A_GIRO_IZQ;
                            when others       => s_acc <= A_AVANZA;
                        end case;
                    end if;
                when ESQUIVA =>
                    s_est <= E_ESQUIVA;
                    if fase = '0' then
                        s_acc <= giro(lado);
                    else
                        s_acc <= A_AVANZA;
                    end if;
                when ESQUINA =>
                    s_est <= E_ESQUINA;
                    if fase = '0' then
                        s_acc <= A_REVERSA;
                    else
                        s_acc <= giro(lado);
                    end if;
                when ESCAPE =>
                    s_est <= E_ESCAPE;
                    if fase = '0' then
                        s_acc <= A_REVERSA;
                    else
                        s_acc <= giro(lado);
                    end if;
                when META =>
                    s_est <= E_META;
                    s_acc <= A_PARO;
            end case;
        end if;
    end process;

    estado   <= s_est;
    accion   <= s_acc;
    evento   <= s_ev;
    ev_nuevo <= s_evn;
    moviendo <= '0' when s_acc = A_PARO else '1';

end architecture rtl;
