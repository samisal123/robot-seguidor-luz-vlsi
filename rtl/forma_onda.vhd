-- ============================================================
-- forma_onda.vhd
-- Convierte la fase del DDS (24 bits) en una muestra con signo
-- de 8 bits (-127 a 127), segun la forma elegida:
--   cuadrada   : +127 en la primera mitad del periodo, -127 en la
--                segunda (bit mas alto de la fase).
--   triangular : sube de -127 a 127 en la primera mitad y baja en
--                la segunda (bits 22 a 15 de la fase).
--   sierra     : rampa de -127 a 127 (bits 23 a 16).
--   seno       : tabla de 256 puntos de synth_pkg (bits 23 a 16),
--                guardada en un bloque M4K.
-- La forma se cambia en operacion.
-- Tuberia de 2 etapas: en la primera se lee la ROM del seno y se
-- registran la fase (bits 23 a 15) y la forma; en la segunda se
-- elige la muestra. La salida llega 2 ciclos despues de la fase.
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
    type t_rom_seno is array (0 to 255) of std_logic_vector(7 downto 0);

    function rom_seno return t_rom_seno is
        variable r : t_rom_seno;
    begin
        for i in 0 to 255 loop
            r(i) := std_logic_vector(to_signed(seno(i), 8));
        end loop;
        return r;
    end function;

    -- ROM del seno en un bloque de memoria (plantilla de ROM de Quartus)
    signal rom : t_rom_seno := rom_seno;
    attribute romstyle : string;
    attribute romstyle of rom : signal is "M4K";

    -- etapa 1
    signal seno_r  : std_logic_vector(7 downto 0) := (others => '0');
    signal fase_r  : std_logic_vector(8 downto 0) := (others => '0');   -- fase(23 downto 15)
    signal forma_r : std_logic_vector(1 downto 0) := W_CUADRADA;
    -- etapa 2
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

    -- etapa 1: ROM del seno y registros de la fase y la forma
    process (clk)
    begin
        if rising_edge(clk) then
            seno_r  <= rom(to_integer(unsigned(fase(23 downto 16))));
            fase_r  <= fase(23 downto 15);
            forma_r <= forma;
        end if;
    end process;

    -- etapa 2: muestra de la forma elegida (combinacional)
    process (forma_r, fase_r, seno_r)
        variable t : integer range 0 to 255;
    begin
        case forma_r is
            when W_CUADRADA =>
                if fase_r(8) = '0' then
                    s_c <= to_signed(127, 8);
                else
                    s_c <= to_signed(-127, 8);
                end if;
            when W_TRIANGULAR =>
                t := to_integer(unsigned(fase_r(7 downto 0)));
                if fase_r(8) = '0' then
                    s_c <= limita(t - 128);
                else
                    s_c <= limita(127 - t);
                end if;
            when W_SIERRA =>
                s_c <= limita(to_integer(unsigned(fase_r(8 downto 1))) - 128);
            when others =>
                s_c <= signed(seno_r);
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
