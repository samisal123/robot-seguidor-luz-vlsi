-- ============================================================
-- pi_ctrl.vhd
-- Control PI de velocidad de una rueda (caracteristica extra).
-- objetivo es el duty que pide drive_cmd (0 a 255) y se usa como
-- consigna de velocidad. VMAX es lo que mide encoder_vel con
-- duty 255 (se calibra en la arena), asi la medida se lleva a
-- las mismas unidades que el duty:
--   med_duty = medida * 256 / VMAX
-- Con cada medicion (actualizar):
--   e     = objetivo - med_duty
--   integ = integ + KI * e             (limitado a +-I_MAX)
--   corr  = (KP * e + integ) / 2**SHIFT
-- y la salida es duty = objetivo + corr, limitada a 0..255: el
-- objetivo funciona como prealimentacion y el PI solo corrige.
-- Con KP = 4, KI = 2 y SHIFT = 4 el lazo es estable aunque la
-- rueda real de entre 0.5 y 2 veces VMAX.
-- Con habilitado = '0' u objetivo = 0: duty = objetivo y el
-- integrador se vacia.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pi_ctrl is
    generic (
        VMAX  : positive := 64;
        KP    : natural  := 4;
        KI    : natural  := 2;
        SHIFT : natural  := 4;
        I_MAX : positive := 4096
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        habilitado : in  std_logic;
        actualizar : in  std_logic;   -- pulso: llego una medicion
        objetivo   : in  std_logic_vector(7 downto 0);
        medida     : in  std_logic_vector(9 downto 0);
        duty       : out std_logic_vector(7 downto 0)
    );
end entity pi_ctrl;

architecture rtl of pi_ctrl is
    constant ESCALA : positive := 2 ** SHIFT;
    constant K_INV  : positive := 65536 / VMAX;   -- medida -> duty, en 1/256

    signal med_d  : natural range 0 to 511 := 0;    -- etapa 1
    signal e_r    : integer range -511 to 255 := 0; -- etapa 2
    signal integ  : integer range -I_MAX to I_MAX := 0;
    signal corr   : integer range -255 to 255 := 0; -- etapa 3
    signal act1, act2 : std_logic := '0';
    signal s_duty : natural range 0 to 255 := 0;
begin

    -- El calculo va en 3 etapas registradas (medida a unidades de
    -- duty; error e integrador; correccion) para que ningun camino
    -- encadene el multiplicador con sumas y saturaciones en un solo
    -- ciclo de 20 ns. La correccion queda lista 3 ciclos despues de
    -- actualizar, mucho antes de la siguiente medicion (50 ms).
    process (clk)
        variable obj : natural range 0 to 255;
        variable m   : natural;
        variable e   : integer range -511 to 255;
        variable i_n : integer range -I_MAX - 1024 to I_MAX + 1024;
        variable c_n : integer range -65536 to 65536;
        variable u   : integer range -255 to 510;
    begin
        if rising_edge(clk) then
            obj  := to_integer(unsigned(objetivo));
            act1 <= actualizar;
            act2 <= act1;

            -- Etapa 1: medida en unidades de duty
            m := (to_integer(unsigned(medida)) * K_INV) / 256;
            if m > 511 then
                med_d <= 511;
            else
                med_d <= m;
            end if;

            if rst = '1' or habilitado = '0' or obj = 0 then
                e_r   <= 0;
                integ <= 0;
                corr  <= 0;
            else
                -- Etapa 2: error e integrador con antiwindup
                if act1 = '1' then
                    e   := obj - med_d;
                    e_r <= e;
                    i_n := integ + KI * e;
                    if i_n > I_MAX then
                        integ <= I_MAX;
                    elsif i_n < -I_MAX then
                        integ <= -I_MAX;
                    else
                        integ <= i_n;
                    end if;
                end if;
                -- Etapa 3: correccion
                if act2 = '1' then
                    c_n := (KP * e_r + integ) / ESCALA;
                    if c_n > 255 then
                        corr <= 255;
                    elsif c_n < -255 then
                        corr <= -255;
                    else
                        corr <= c_n;
                    end if;
                end if;
            end if;

            if habilitado = '0' or obj = 0 then
                s_duty <= obj;
            else
                u := obj + corr;
                if u > 255 then
                    s_duty <= 255;
                elsif u < 0 then
                    s_duty <= 0;
                else
                    s_duty <= u;
                end if;
            end if;
        end if;
    end process;

    duty <= std_logic_vector(to_unsigned(s_duty, 8));

end architecture rtl;
