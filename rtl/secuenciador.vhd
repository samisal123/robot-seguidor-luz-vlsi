-- ============================================================
-- secuenciador.vhd
-- Graba y reproduce secuencias musicales en memoria_eventos.
--
-- Un evento es un conjunto de notas que se mantuvo igual (hasta
-- 3 notas, o silencio si no hay ninguna) y su duracion en ms.
-- Grabando, cada vez que cambia el conjunto pedido se guarda el
-- evento que termina; asi quedan las notas, los acordes, los
-- silencios y sus duraciones, en orden.
--
-- Base de tiempo: t_ms cuenta los ticks de 1 ms todo el tiempo.
-- inicio guarda el ms en que empezo el evento en curso y la
-- duracion es t_ms - inicio (modulo 2**17). Al reproducir, el
-- evento siguiente empieza en inicio + duracion; asi la
-- latencia de la maquina de estados no pierde ticks ni acumula
-- error a lo largo de la secuencia.
--
-- Maquina de estados:
--   ESPERA    no hace nada; la salida es silencio.
--             cmd_grabar                   -> GRABANDO (borra lo anterior)
--             cmd_reproducir y hay eventos -> LEER (evento 0)
--   GRABANDO  si el conjunto cambia, guarda el evento que termina
--             y empieza otro. Un evento que llega a 65 535 ms se
--             guarda y sigue como un evento nuevo.
--             cmd_parar -> guarda el ultimo evento -> ESPERA
--             al guardar el evento 256 (memoria llena) -> ESPERA
--   LEER      la RAM entrega el evento p             -> CARGAR
--   CARGAR    pone las notas del evento en la salida -> TOCAR
--   TOCAR     al cumplirse la duracion pasa al siguiente evento
--             (LEER) o, si era el ultimo, termina en silencio
--             -> ESPERA. cmd_parar -> ESPERA.
--
-- Un evento con duracion 0 no se guarda.
-- posicion: grabando o en espera, eventos guardados;
-- reproduciendo, numero del evento que suena (desde 1).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity secuenciador is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;   -- sincrono, activo en alto
        tick_1ms       : in  std_logic;
        cmd_grabar     : in  std_logic;   -- pulso: iniciar grabacion
        cmd_reproducir : in  std_logic;   -- pulso: iniciar reproduccion
        cmd_parar      : in  std_logic;   -- finalizar grabacion o detener reproduccion
        conjunto       : in  std_logic_vector(20 downto 0);   -- notas en vivo
        salida         : out std_logic_vector(20 downto 0);   -- notas reproducidas
        estado         : out std_logic_vector(1 downto 0);    -- S_ESPERA, S_GRABANDO, S_REPRODUCE
        eventos        : out std_logic_vector(8 downto 0);    -- 0 a 256
        posicion       : out std_logic_vector(8 downto 0);
        llena          : out std_logic
    );
end entity secuenciador;

architecture rtl of secuenciador is
    type t_est is (ESPERA, GRABANDO, LEER, CARGAR, TOCAR);
    constant DUR_MAX : natural := 65535;
    constant N_MAX   : natural := 256;

    signal est      : t_est := ESPERA;
    signal n_ev     : natural range 0 to N_MAX := 0;        -- eventos guardados
    signal p        : natural range 0 to N_MAX - 1 := 0;    -- evento que suena
    signal actual   : std_logic_vector(20 downto 0) := (others => '0');
    signal t_ms     : unsigned(16 downto 0) := (others => '0');
    signal inicio   : unsigned(16 downto 0) := (others => '0');
    signal dur_ev   : unsigned(15 downto 0) := (others => '0');
    signal s_salida : std_logic_vector(20 downto 0) := (others => '0');

    signal ahora : unsigned(16 downto 0);   -- ms, contando el tick de este ciclo
    signal trans : unsigned(16 downto 0);   -- ms transcurridos del evento

    signal we   : std_logic := '0';
    signal dir  : std_logic_vector(7 downto 0) := (others => '0');
    signal din  : std_logic_vector(36 downto 0) := (others => '0');
    signal dout : std_logic_vector(36 downto 0);
begin

    u_mem : entity work.memoria_eventos
        generic map (
            ANCHO => 37,
            N_DIR => 8
        )
        port map (
            clk  => clk,
            we   => we,
            dir  => dir,
            din  => din,
            dout => dout
        );

    ahora <= t_ms + 1 when tick_1ms = '1' else t_ms;
    trans <= ahora - inicio;

    process (clk)
        variable cerrar : boolean;                 -- guardar el evento en curso
        variable d      : unsigned(15 downto 0);
    begin
        if rising_edge(clk) then
            we <= '0';
            t_ms <= ahora;

            if rst = '1' then
                est      <= ESPERA;
                n_ev     <= 0;
                p        <= 0;
                actual   <= (others => '0');
                inicio   <= (others => '0');
                dur_ev   <= (others => '0');
                s_salida <= (others => '0');
            else
                case est is
                    when ESPERA =>
                        s_salida <= (others => '0');
                        if cmd_grabar = '1' then
                            n_ev   <= 0;
                            actual <= conjunto;
                            inicio <= ahora;
                            est    <= GRABANDO;
                        elsif cmd_reproducir = '1' and n_ev > 0 then
                            p      <= 0;
                            dir    <= (others => '0');
                            inicio <= ahora;
                            est    <= LEER;
                        end if;

                    when GRABANDO =>
                        cerrar := false;
                        d      := trans(15 downto 0);
                        if cmd_parar = '1' then
                            cerrar := trans > 0;
                            est    <= ESPERA;
                        elsif conjunto /= actual then
                            cerrar := trans > 0;
                            actual <= conjunto;
                            inicio <= ahora;
                        elsif trans >= DUR_MAX then
                            cerrar := true;              -- evento muy largo: se parte
                            d      := to_unsigned(DUR_MAX, 16);
                            inicio <= inicio + DUR_MAX;
                        end if;
                        if cerrar then
                            we   <= '1';
                            dir  <= std_logic_vector(to_unsigned(n_ev mod N_MAX, 8));
                            din  <= actual & std_logic_vector(d);
                            n_ev <= n_ev + 1;
                            if n_ev = N_MAX - 1 then
                                est <= ESPERA;           -- memoria llena
                            end if;
                        end if;

                    when LEER =>
                        if cmd_parar = '1' then
                            s_salida <= (others => '0');
                            est      <= ESPERA;
                        else
                            est <= CARGAR;
                        end if;

                    when CARGAR =>
                        if cmd_parar = '1' then
                            s_salida <= (others => '0');
                            est      <= ESPERA;
                        else
                            s_salida <= dout(36 downto 16);
                            dur_ev   <= unsigned(dout(15 downto 0));
                            est      <= TOCAR;
                        end if;

                    when TOCAR =>
                        if cmd_parar = '1' then
                            s_salida <= (others => '0');
                            est      <= ESPERA;
                        elsif trans >= dur_ev then
                            if p = n_ev - 1 then
                                s_salida <= (others => '0');
                                est      <= ESPERA;      -- fin de la secuencia
                            else
                                p      <= p + 1;
                                dir    <= std_logic_vector(to_unsigned(p + 1, 8));
                                inicio <= inicio + dur_ev;
                                est    <= LEER;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    salida <= s_salida;

    with est select
        estado <= S_ESPERA    when ESPERA,
                  S_GRABANDO  when GRABANDO,
                  S_REPRODUCE when others;

    eventos  <= std_logic_vector(to_unsigned(n_ev, 9));
    posicion <= std_logic_vector(to_unsigned(p + 1, 9))
                    when est = LEER or est = CARGAR or est = TOCAR
                    else std_logic_vector(to_unsigned(n_ev, 9));
    llena    <= '1' when n_ev = N_MAX else '0';

end architecture rtl;
