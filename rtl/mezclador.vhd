-- ============================================================
-- mezclador.vhd
-- Suma las 3 voces (muestras de 8 bits con signo, -127..127) y
-- deja el resultado en el formato interno de la etapa de audio:
-- 12 bits con signo = muestra de 8 bits con 4 bits de fraccion,
-- escala completa +-2032 (= +-127.0).
--   mezcla = saturar( (voz0 + voz1 + voz2) * 8 )
-- Equivale a sumar las voces y dividir entre 2: una voz sola a
-- escala completa queda en la mitad de la escala (63.5 de 127);
-- dos voces nunca saturan y tres solo cuando sus picos coinciden
-- (|suma| > 254). Si satura, satura = '1' junto con sal_valida.
-- Con ent_valida = '1' captura las voces; la mezcla sale un ciclo
-- despues con un pulso en sal_valida.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mezclador is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        ent_valida : in  std_logic;
        voz0       : in  std_logic_vector(7 downto 0);
        voz1       : in  std_logic_vector(7 downto 0);
        voz2       : in  std_logic_vector(7 downto 0);
        mezcla     : out std_logic_vector(11 downto 0);
        sal_valida : out std_logic;
        satura     : out std_logic
    );
end entity mezclador;

architecture rtl of mezclador is
    constant TOPE : integer := 2032;   -- 127 * 16
    signal s_mezcla : signed(11 downto 0) := (others => '0');
    signal s_valida : std_logic := '0';
    signal s_satura : std_logic := '0';
begin

    process (clk)
        variable suma : integer range -384 to 384;
        variable p    : integer range -3072 to 3072;
    begin
        if rising_edge(clk) then
            s_valida <= '0';
            if rst = '1' then
                s_mezcla <= (others => '0');
                s_satura <= '0';
            elsif ent_valida = '1' then
                suma := to_integer(signed(voz0)) + to_integer(signed(voz1)) +
                        to_integer(signed(voz2));
                p := suma * 8;
                if p > TOPE then
                    s_mezcla <= to_signed(TOPE, 12);
                    s_satura <= '1';
                elsif p < -TOPE then
                    s_mezcla <= to_signed(-TOPE, 12);
                    s_satura <= '1';
                else
                    s_mezcla <= to_signed(p, 12);
                    s_satura <= '0';
                end if;
                s_valida <= '1';
            end if;
        end if;
    end process;

    mezcla     <= std_logic_vector(s_mezcla);
    sal_valida <= s_valida;
    satura     <= s_satura;

end architecture rtl;
