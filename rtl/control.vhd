-- ============================================================
-- control.vhd
-- Unidad principal de control. Guarda los parametros del
-- sintetizador, interpreta las teclas de funcion segun el modo
-- y manda las ordenes al secuenciador.
--
-- Modo (boton MODO): 00 interpretacion, 01 grabacion,
--                 10 reproduccion, 11 configuracion.
--
-- Teclas de funcion (columna A-D de cada teclado):
--   Interpretacion, grabacion y reproduccion:
--     teclado 1: A octava -, B octava +, C forma siguiente,
--                D efecto siguiente
--     teclado 2: A volumen -, B volumen +, C tempo -, D tempo +
--   Configuracion (cualquiera de los dos teclados):
--     A valor -, B valor +, C parametro anterior,
--     D parametro siguiente
--   Parametros: forma, attack, decay, sustain, release, volumen,
--   tempo y efecto (synth_pkg). Los valores se quedan en sus
--   limites (no dan la vuelta); forma y efecto si dan la vuelta
--   con sus teclas directas.
--
-- ACCION: en grabacion inicia o finaliza la grabacion; en
-- reproduccion inicia o detiene la reproduccion.
-- METRONOMO: enciende o apaga el metronomo (en cualquier modo).
-- metro_suena = metro_on, salvo mientras se reproduce una
-- secuencia (el metronomo se usa al interpretar y al grabar).
-- Si se cambia de modo a mitad de una grabacion o reproduccion,
-- esta se termina (cmd_parar).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity control is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;   -- sincrono, activo en alto
        modo           : in  std_logic_vector(1 downto 0);
        func           : in  std_logic_vector(7 downto 0);   -- pulsos A-D teclado 1 (3..0) y 2 (7..4)
        accion         : in  std_logic;                      -- pulso del boton ACCION
        metro_btn      : in  std_logic;                      -- pulso del boton METRONOMO
        estado_sec     : in  std_logic_vector(1 downto 0);
        forma          : out std_logic_vector(1 downto 0);
        atk            : out std_logic_vector(1 downto 0);
        dec            : out std_logic_vector(1 downto 0);
        sus            : out std_logic_vector(1 downto 0);
        rel            : out std_logic_vector(1 downto 0);
        volumen        : out std_logic_vector(2 downto 0);   -- 0 silencio .. 4
        tempo          : out std_logic_vector(1 downto 0);
        efecto         : out std_logic_vector(1 downto 0);
        metro_on       : out std_logic;
        metro_suena    : out std_logic;
        octava         : out std_logic_vector(2 downto 0);
        parametro      : out std_logic_vector(2 downto 0);
        cmd_grabar     : out std_logic;
        cmd_reproducir : out std_logic;
        cmd_parar      : out std_logic
    );
end entity control;

architecture rtl of control is
    constant VOL_MAX : natural := 4;

    signal r_forma : natural range 0 to 3 := 0;   -- cuadrada
    signal r_atk   : natural range 0 to 3 := 0;   -- 2 ms
    signal r_dec   : natural range 0 to 3 := 1;   -- 200 ms
    signal r_sus   : natural range 0 to 3 := 2;   -- 75 %
    signal r_rel   : natural range 0 to 3 := 1;   -- 150 ms
    signal r_vol   : natural range 0 to VOL_MAX := 3;
    signal r_tempo : natural range 0 to 3 := 2;   -- 120 BPM
    signal r_efe   : natural range 0 to 3 := 0;   -- sin efecto
    signal r_metro : std_logic := '0';
    signal r_oct   : natural range OCT_MIN to OCT_MAX := 4;
    signal r_par   : natural range 0 to 7 := P_FORMA;

    signal c_grabar, c_reproducir, c_parar : std_logic := '0';

    function sube (v, maximo : natural) return natural is
    begin
        if v < maximo then
            return v + 1;
        else
            return v;
        end if;
    end function;

    function baja (v, minimo : natural) return natural is
    begin
        if v > minimo then
            return v - 1;
        else
            return v;
        end if;
    end function;
begin

    process (clk)
        variable menos, mas, ant, sig : boolean;
    begin
        if rising_edge(clk) then
            c_grabar     <= '0';
            c_reproducir <= '0';
            c_parar      <= '0';
            if rst = '1' then
                r_forma <= 0;
                r_atk   <= 0;
                r_dec   <= 1;
                r_sus   <= 2;
                r_rel   <= 1;
                r_vol   <= 3;
                r_tempo <= 2;
                r_efe   <= 0;
                r_metro <= '0';
                r_oct   <= 4;
                r_par   <= P_FORMA;
            else
                -- teclas de funcion
                if modo = M_CONF then
                    menos := func(0) = '1' or func(4) = '1';
                    mas   := func(1) = '1' or func(5) = '1';
                    ant   := func(2) = '1' or func(6) = '1';
                    sig   := func(3) = '1' or func(7) = '1';
                    if ant then
                        r_par <= (r_par + 7) mod 8;
                    elsif sig then
                        r_par <= (r_par + 1) mod 8;
                    elsif menos or mas then
                        case r_par is
                            when P_FORMA =>
                                if mas then r_forma <= sube(r_forma, 3); else r_forma <= baja(r_forma, 0); end if;
                            when P_ATTACK =>
                                if mas then r_atk <= sube(r_atk, 3); else r_atk <= baja(r_atk, 0); end if;
                            when P_DECAY =>
                                if mas then r_dec <= sube(r_dec, 3); else r_dec <= baja(r_dec, 0); end if;
                            when P_SUSTAIN =>
                                if mas then r_sus <= sube(r_sus, 3); else r_sus <= baja(r_sus, 0); end if;
                            when P_RELEASE =>
                                if mas then r_rel <= sube(r_rel, 3); else r_rel <= baja(r_rel, 0); end if;
                            when P_VOLUMEN =>
                                if mas then r_vol <= sube(r_vol, VOL_MAX); else r_vol <= baja(r_vol, 0); end if;
                            when P_TEMPO =>
                                if mas then r_tempo <= sube(r_tempo, 3); else r_tempo <= baja(r_tempo, 0); end if;
                            when others =>
                                if mas then r_efe <= sube(r_efe, 3); else r_efe <= baja(r_efe, 0); end if;
                        end case;
                    end if;
                else
                    if func(0) = '1' then r_oct <= baja(r_oct, OCT_MIN); end if;
                    if func(1) = '1' then r_oct <= sube(r_oct, OCT_MAX); end if;
                    if func(2) = '1' then r_forma <= (r_forma + 1) mod 4; end if;
                    if func(3) = '1' then r_efe <= (r_efe + 1) mod 4; end if;
                    if func(4) = '1' then r_vol <= baja(r_vol, 0); end if;
                    if func(5) = '1' then r_vol <= sube(r_vol, VOL_MAX); end if;
                    if func(6) = '1' then r_tempo <= baja(r_tempo, 0); end if;
                    if func(7) = '1' then r_tempo <= sube(r_tempo, 3); end if;
                end if;

                -- metronomo
                if metro_btn = '1' then
                    r_metro <= not r_metro;
                end if;

                -- ordenes al secuenciador
                if estado_sec = S_ESPERA then
                    if accion = '1' and modo = M_GRA then
                        c_grabar <= '1';
                    elsif accion = '1' and modo = M_REP then
                        c_reproducir <= '1';
                    end if;
                elsif accion = '1'
                      or (estado_sec = S_GRABANDO and modo /= M_GRA)
                      or (estado_sec = S_REPRODUCE and modo /= M_REP) then
                    c_parar <= '1';
                end if;
            end if;
        end if;
    end process;

    forma     <= std_logic_vector(to_unsigned(r_forma, 2));
    atk       <= std_logic_vector(to_unsigned(r_atk, 2));
    dec       <= std_logic_vector(to_unsigned(r_dec, 2));
    sus       <= std_logic_vector(to_unsigned(r_sus, 2));
    rel       <= std_logic_vector(to_unsigned(r_rel, 2));
    volumen   <= std_logic_vector(to_unsigned(r_vol, 3));
    tempo     <= std_logic_vector(to_unsigned(r_tempo, 2));
    efecto    <= std_logic_vector(to_unsigned(r_efe, 2));
    metro_on  <= r_metro;
    metro_suena <= r_metro when estado_sec /= S_REPRODUCE else '0';
    octava    <= std_logic_vector(to_unsigned(r_oct, 3));
    parametro <= std_logic_vector(to_unsigned(r_par, 3));

    cmd_grabar     <= c_grabar;
    cmd_reproducir <= c_reproducir;
    cmd_parar      <= c_parar;

end architecture rtl;
