-- ============================================================
-- forma_onda.vhd
-- Convierte la fase del DDS (24 bits) en una muestra con signo
-- de 8 bits (-127 a 127), segun la forma elegida:
--   cuadrada   : +127 en la primera mitad del periodo, -127 en la
--                segunda (bit mas alto de la fase).
--   triangular : sube de -127 a 127 en la primera mitad y baja en
--                la segunda (bits 22 a 15 de la fase).
--   sierra     : rampa de -127 a 127 (bits 23 a 16).
--   seno       : tabla de 256 puntos de synth_pkg (bits 23 a 16).
-- La forma se cambia en operacion; la salida va registrada.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity forma_onda is
    port (
        clk     : in  std_logic;
        forma   : in  std_logic_vector(1 downto 0);
        fase    : in  std_logic_vector(23 downto 0);
        muestra : out std_logic_vector(7 downto 0)
    );
end entity forma_onda;

architecture rtl of forma_onda is
    signal s_c : signed(7 downto 0);
    signal s   : signed(7 downto 0) := (others => '0');

    function limita (v : integer) return signed is
    begin
        if v < -127 then
            return to_signed(-127, 8);
        elsif v > 127 then
            return to_signed(127, 8);
        else
            return to_signed(v, 8);
        end if;
    end function;
begin

    -- muestra de la forma elegida (combinacional)
    process (forma, fase)
        variable t : integer range 0 to 255;
    begin
        case forma is
            when W_CUADRADA =>
                if fase(23) = '0' then
                    s_c <= to_signed(127, 8);
                else
                    s_c <= to_signed(-127, 8);
                end if;
            when W_TRIANGULAR =>
                t := to_integer(unsigned(fase(22 downto 15)));
                if fase(23) = '0' then
                    s_c <= limita(t - 128);
                else
                    s_c <= limita(127 - t);
                end if;
            when W_SIERRA =>
                s_c <= limita(to_integer(unsigned(fase(23 downto 16))) - 128);
            when others =>
                s_c <= to_signed(seno(to_integer(unsigned(fase(23 downto 16)))), 8);
        end case;
    end process;

    -- salida registrada
    process (clk)
    begin
        if rising_edge(clk) then
            s <= s_c;
        end if;
    end process;

    muestra <= std_logic_vector(s);

end architecture rtl;
