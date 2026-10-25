-- ============================================================
-- telemetria.vhd
-- Bitacora por UART (115200 8N1 por defecto). Cada PERIODO_MS, y
-- ademas cada vez que la FSM reporta un evento, manda una linea
-- de 52 caracteres:
--
--   E2 V1 F045 I120 D--- A033 L1010 C0 P66 66 S012 013<CR><LF>
--
--   E  estado (0 INICIO .. 6 META)      V  ultimo evento
--   F  distancia frente en cm           I  diagonal izquierda
--   D  diagonal derecha                 A  atras
--      ("---" = sin eco)
--   L  LDR frente, izquierda, derecha, atras ('1' = luz)
--   C  luz cerca al frente
--   P  % de duty izquierdo y derecho (duty * 100 / 256)
--   S  velocidad medida por los encoders izquierdo y derecho
--      (transiciones por ventana de 50 ms; sirve para calibrar
--      VMAX del PI)
--
-- Los valores se copian al empezar la linea, asi una linea nunca
-- mezcla datos de dos momentos.
-- En la PC: python3 -m serial.tools.miniterm /dev/ttyUSB0 115200
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.robot_pkg.all;

entity telemetria is
    generic (
        CLK_HZ     : positive := 50_000_000;
        BAUD       : positive := 115_200;
        PERIODO_MS : positive := 200
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        tick_1ms : in  std_logic;
        ev_nuevo : in  std_logic;
        estado   : in  std_logic_vector(2 downto 0);
        evento   : in  std_logic_vector(2 downto 0);
        dist     : in  std_logic_vector(35 downto 0);
        luz      : in  std_logic_vector(3 downto 0);
        cerca    : in  std_logic;
        duty_l   : in  std_logic_vector(7 downto 0);
        duty_r   : in  std_logic_vector(7 downto 0);
        vel_l    : in  std_logic_vector(9 downto 0);
        vel_r    : in  std_logic_vector(9 downto 0);
        tx       : out std_logic
    );
end entity telemetria;

architecture rtl of telemetria is
    constant LARGO : natural := 52;

    type t_fase is (REPOSO, ENVIA, ESPERA_OCUPADO, ESPERA_LIBRE);
    signal fase    : t_fase := REPOSO;
    signal idx     : natural range 0 to LARGO - 1 := 0;
    signal t_ms    : natural range 0 to PERIODO_MS - 1 := 0;
    signal pend    : std_logic := '0';

    -- copia de los datos de la linea en curso
    signal c_est, c_ev : std_logic_vector(2 downto 0) := (others => '0');
    signal c_dist      : std_logic_vector(35 downto 0) := (others => '1');
    signal c_luz       : std_logic_vector(3 downto 0) := (others => '0');
    signal c_cer       : std_logic := '0';
    signal c_dl, c_dr  : std_logic_vector(7 downto 0) := (others => '0');
    signal c_vl, c_vr  : std_logic_vector(8 downto 0) := (others => '0');

    signal dato    : std_logic_vector(7 downto 0);
    signal enviar  : std_logic := '0';
    signal ocupado : std_logic;

    -- Binario de 9 bits a 3 digitos BCD (double dabble)
    function a_bcd (b : unsigned(8 downto 0)) return unsigned is
        variable r : unsigned(20 downto 0) := (others => '0');
    begin
        r(8 downto 0) := b;
        for i in 1 to 9 loop
            if r(12 downto 9) > 4 then
                r(12 downto 9) := r(12 downto 9) + 3;
            end if;
            if r(16 downto 13) > 4 then
                r(16 downto 13) := r(16 downto 13) + 3;
            end if;
            if r(20 downto 17) > 4 then
                r(20 downto 17) := r(20 downto 17) + 3;
            end if;
            r := r(19 downto 0) & '0';
        end loop;
        return r(20 downto 9);
    end function;

    function porcentaje (d : std_logic_vector(7 downto 0)) return unsigned is
        variable p : unsigned(14 downto 0);
    begin
        p := unsigned(d) * to_unsigned(100, 7);
        return "00" & p(14 downto 8);
    end function;

    function ascii (d : unsigned(3 downto 0)) return std_logic_vector is
    begin
        return "0011" & std_logic_vector(d);
    end function;

    function ascii_bit (b : std_logic) return std_logic_vector is
    begin
        if b = '1' then
            return x"31";
        else
            return x"30";
        end if;
    end function;

    -- Caracter j (0, 1 o 2) de una distancia ya convertida a BCD
    function dist_char (bcd : unsigned(11 downto 0); sin_eco : std_logic; j : natural)
        return std_logic_vector is
    begin
        if sin_eco = '1' then
            return x"2D";                         -- '-'
        end if;
        case j is
            when 0      => return ascii(bcd(11 downto 8));
            when 1      => return ascii(bcd(7 downto 4));
            when others => return ascii(bcd(3 downto 0));
        end case;
    end function;

    -- Velocidad de 10 bits limitada a 511 para mostrarla con 3 digitos
    function a_9 (v : std_logic_vector(9 downto 0)) return std_logic_vector is
    begin
        if v(9) = '1' then
            return "111111110";   -- 510
        else
            return v(8 downto 0);
        end if;
    end function;

    type t_bcd4 is array (0 to 3) of unsigned(11 downto 0);
    signal bcd_d          : t_bcd4 := (others => (others => '0'));
    signal sin_d          : std_logic_vector(3 downto 0) := (others => '1');
    signal p_l, p_r       : unsigned(8 downto 0) := (others => '0');
    signal pct_l, pct_r   : unsigned(11 downto 0) := (others => '0');
    signal bcd_vl, bcd_vr : unsigned(11 downto 0) := (others => '0');
begin

    -- Conversiones a decimal en etapas registradas. Los datos de la
    -- linea no cambian mientras se envia y los digitos se usan miles
    -- de ciclos despues de la copia, asi que la latencia no importa y
    -- el camino mas largo no pasa por el multiplexor ni la UART.
    process (clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 3 loop
                bcd_d(i) <= a_bcd(unsigned(c_dist(9 * i + 8 downto 9 * i)));
                if c_dist(9 * i + 8 downto 9 * i) = "111111111" then
                    sin_d(i) <= '1';
                else
                    sin_d(i) <= '0';
                end if;
            end loop;
            p_l    <= porcentaje(c_dl);
            p_r    <= porcentaje(c_dr);
            pct_l  <= a_bcd(p_l);
            pct_r  <= a_bcd(p_r);
            bcd_vl <= a_bcd(unsigned(c_vl));
            bcd_vr <= a_bcd(unsigned(c_vr));
        end if;
    end process;

    -- Caracter que toca enviar
    process (idx, c_est, c_ev, bcd_d, sin_d, c_luz, c_cer, pct_l, pct_r, bcd_vl, bcd_vr)
    begin
        case idx is
            when 0  => dato <= x"45";                                 -- E
            when 1  => dato <= ascii('0' & unsigned(c_est));
            when 3  => dato <= x"56";                                 -- V
            when 4  => dato <= ascii('0' & unsigned(c_ev));
            when 6  => dato <= x"46";                                 -- F
            when 7 to 9   => dato <= dist_char(bcd_d(0), sin_d(0), idx - 7);
            when 11 => dato <= x"49";                                 -- I
            when 12 to 14 => dato <= dist_char(bcd_d(1), sin_d(1), idx - 12);
            when 16 => dato <= x"44";                                 -- D
            when 17 to 19 => dato <= dist_char(bcd_d(2), sin_d(2), idx - 17);
            when 21 => dato <= x"41";                                 -- A
            when 22 to 24 => dato <= dist_char(bcd_d(3), sin_d(3), idx - 22);
            when 26 => dato <= x"4C";                                 -- L
            when 27 => dato <= ascii_bit(c_luz(L_FRENTE));
            when 28 => dato <= ascii_bit(c_luz(L_IZQ));
            when 29 => dato <= ascii_bit(c_luz(L_DER));
            when 30 => dato <= ascii_bit(c_luz(L_ATRAS));
            when 32 => dato <= x"43";                                 -- C
            when 33 => dato <= ascii_bit(c_cer);
            when 35 => dato <= x"50";                                 -- P
            when 36 => dato <= ascii(pct_l(7 downto 4));
            when 37 => dato <= ascii(pct_l(3 downto 0));
            when 39 => dato <= ascii(pct_r(7 downto 4));
            when 40 => dato <= ascii(pct_r(3 downto 0));
            when 42 => dato <= x"53";                                 -- S
            when 43 => dato <= ascii(bcd_vl(11 downto 8));
            when 44 => dato <= ascii(bcd_vl(7 downto 4));
            when 45 => dato <= ascii(bcd_vl(3 downto 0));
            when 47 => dato <= ascii(bcd_vr(11 downto 8));
            when 48 => dato <= ascii(bcd_vr(7 downto 4));
            when 49 => dato <= ascii(bcd_vr(3 downto 0));
            when 50 => dato <= x"0D";                                 -- CR
            when 51 => dato <= x"0A";                                 -- LF
            when others => dato <= x"20";                             -- espacio
        end case;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            enviar <= '0';

            -- disparos: periodo o evento
            if tick_1ms = '1' then
                if t_ms = PERIODO_MS - 1 then
                    t_ms <= 0;
                    pend <= '1';
                else
                    t_ms <= t_ms + 1;
                end if;
            end if;
            if ev_nuevo = '1' then
                pend <= '1';
            end if;

            if rst = '1' then
                fase <= REPOSO;
                idx  <= 0;
                t_ms <= 0;
                pend <= '0';
            else
                case fase is
                    when REPOSO =>
                        if pend = '1' then
                            pend   <= '0';
                            idx    <= 0;
                            c_est  <= estado;
                            c_ev   <= evento;
                            c_dist <= dist;
                            c_luz  <= luz;
                            c_cer  <= cerca;
                            c_dl   <= duty_l;
                            c_dr   <= duty_r;
                            c_vl   <= a_9(vel_l);
                            c_vr   <= a_9(vel_r);
                            fase   <= ENVIA;
                        end if;
                    when ENVIA =>
                        if ocupado = '0' then
                            enviar <= '1';
                            fase   <= ESPERA_OCUPADO;
                        end if;
                    when ESPERA_OCUPADO =>
                        if ocupado = '1' then
                            fase <= ESPERA_LIBRE;
                        end if;
                    when ESPERA_LIBRE =>
                        if ocupado = '0' then
                            if idx = LARGO - 1 then
                                fase <= REPOSO;
                            else
                                idx  <= idx + 1;
                                fase <= ENVIA;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    u_tx : entity work.uart_tx
        generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
        port map (
            clk     => clk,
            rst     => rst,
            dato    => dato,
            enviar  => enviar,
            tx      => tx,
            ocupado => ocupado
        );

end architecture rtl;
