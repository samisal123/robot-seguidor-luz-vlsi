-- ============================================================
-- tremolo.vhd
-- Efecto de tremolo: modula la amplitud con un LFO triangular de
-- unos 5 Hz y profundidad de 50 %.
--   LFO: acumulador de fase de 20 bits que avanza INC_LFO por
--        muestra; f = INC_LFO * Fs / 2**20 (107 -> 4.98 Hz).
--        tri sube de 0 a 255 en medio periodo y baja en el otro.
--   ganancia g = 256 - tri / 2   (de 256 = 1.0 a 129 = 0.504)
--   y = x * g / 256              (corrimiento aritmetico)
-- Con activo = '0' la muestra pasa sin cambio (el LFO sigue).
-- Muestras de 12 bits con signo; |y| <= |x|, nunca satura.
-- Tres etapas registradas (LFO, producto, escala): sal_valida
-- llega 3 ciclos despues de ent_valida. Acepta una muestra por
-- ciclo.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity tremolo is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        activo     : in  std_logic;
        ent_valida : in  std_logic;
        x          : in  std_logic_vector(11 downto 0);
        y          : out std_logic_vector(11 downto 0);
        sal_valida : out std_logic
    );
end entity tremolo;

architecture rtl of tremolo is
    constant FS_HZ   : natural := 50_000_000 / FS_DIV;                 -- 48 828
    constant INC_LFO : natural := (5 * 2**20 + FS_HZ / 2) / FS_HZ;     -- 107

    signal fase   : unsigned(19 downto 0) := (others => '0');
    signal g      : unsigned(8 downto 0) := to_unsigned(256, 9);
    signal x_r    : signed(11 downto 0) := (others => '0');
    signal x_r2   : signed(11 downto 0) := (others => '0');
    signal prod   : signed(21 downto 0) := (others => '0');
    signal act_r  : std_logic := '0';
    signal act_r2 : std_logic := '0';
    signal v1, v2 : std_logic := '0';
    signal s_y    : signed(11 downto 0) := (others => '0');
    signal s_val  : std_logic := '0';
begin

    process (clk)
        variable tri : unsigned(7 downto 0);
    begin
        if rising_edge(clk) then
            v1    <= '0';
            v2    <= '0';
            s_val <= '0';
            if rst = '1' then
                fase <= (others => '0');
                g    <= to_unsigned(256, 9);
                s_y  <= (others => '0');
            else
                -- Etapa 1: LFO triangular, ganancia y captura de la muestra
                if ent_valida = '1' then
                    fase <= fase + INC_LFO;
                    if fase(19) = '0' then
                        tri := fase(18 downto 11);
                    else
                        tri := 255 - fase(18 downto 11);
                    end if;
                    g     <= to_unsigned(256, 9) - resize(tri(7 downto 1), 9);
                    x_r   <= signed(x);
                    act_r <= activo;
                    v1    <= '1';
                end if;
                -- Etapa 2: producto x * g
                if v1 = '1' then
                    prod   <= x_r * signed('0' & g);
                    x_r2   <= x_r;
                    act_r2 <= act_r;
                    v2     <= '1';
                end if;
                -- Etapa 3: escala entre 256 o paso directo
                if v2 = '1' then
                    if act_r2 = '1' then
                        s_y <= resize(shift_right(prod, 8), 12);
                    else
                        s_y <= x_r2;
                    end if;
                    s_val <= '1';
                end if;
            end if;
        end if;
    end process;

    y          <= std_logic_vector(s_y);
    sal_valida <= s_val;

end architecture rtl;
