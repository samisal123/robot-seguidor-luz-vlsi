-- ============================================================
-- volumen.vhd
-- Control digital de volumen, independiente de la envolvente:
--   vol = 0 silencio, 1 = 25 %, 2 = 50 %, 3 = 75 %, 4 = 100 %
--   y = (x * vol) / 4  (corrimiento aritmetico, redondeo hacia
--   abajo); vol de 5 a 7 se toma como 4.
-- x * vol se arma con corrimientos y una suma (sin multiplicador).
-- Muestras de 12 bits con signo; |y| <= |x|.
-- sal_valida llega 1 ciclo despues de ent_valida.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity volumen is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        ent_valida : in  std_logic;
        x          : in  std_logic_vector(11 downto 0);
        vol        : in  std_logic_vector(2 downto 0);
        y          : out std_logic_vector(11 downto 0);
        sal_valida : out std_logic
    );
end entity volumen;

architecture rtl of volumen is
    signal s_y   : signed(11 downto 0) := (others => '0');
    signal s_val : std_logic := '0';
begin

    process (clk)
        variable xs : signed(14 downto 0);
        variable p  : signed(14 downto 0);
    begin
        if rising_edge(clk) then
            s_val <= '0';
            if rst = '1' then
                s_y <= (others => '0');
            elsif ent_valida = '1' then
                xs := resize(signed(x), 15);
                case vol is
                    when "000"  => p := (others => '0');            -- 0
                    when "001"  => p := xs;                         -- x
                    when "010"  => p := shift_left(xs, 1);          -- 2x
                    when "011"  => p := xs + shift_left(xs, 1);     -- 3x
                    when others => p := shift_left(xs, 2);          -- 4x
                end case;
                s_y   <= resize(shift_right(p, 2), 12);
                s_val <= '1';
            end if;
        end if;
    end process;

    y          <= std_logic_vector(s_y);
    sal_valida <= s_val;

end architecture rtl;
