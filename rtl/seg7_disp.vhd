-- ============================================================
-- seg7_disp.vhd
-- Displays HEX5..HEX0 de la DE10-Lite (anodo comun: segmento
-- encendido = '0'; bit 7 = punto decimal).
-- Modo normal (modo_dist = '0'):
--   HEX5 estado, HEX4 ultimo evento,
--   HEX3-HEX2 % de duty izquierdo, HEX1-HEX0 % de duty derecho.
--   % = duty * 100 / 256 (0 a 99; duty 255 muestra 99).
-- Modo distancia (modo_dist = '1', SW9):
--   HEX5 estado, HEX4 evento, HEX3 numero de sensor con punto,
--   HEX2-HEX0 distancia en cm sin ceros a la izquierda;
--   511 (timeout del HC-SR04) se muestra como "---".
-- Salidas registradas; las conversiones van en etapas (ver abajo).
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_disp is
    port (
        clk       : in  std_logic;
        estado    : in  std_logic_vector(2 downto 0);
        evento    : in  std_logic_vector(2 downto 0);
        duty_l    : in  std_logic_vector(7 downto 0);
        duty_r    : in  std_logic_vector(7 downto 0);
        modo_dist : in  std_logic;
        sensor    : in  std_logic_vector(1 downto 0);
        dist_cm   : in  std_logic_vector(8 downto 0);
        hex0      : out std_logic_vector(7 downto 0);
        hex1      : out std_logic_vector(7 downto 0);
        hex2      : out std_logic_vector(7 downto 0);
        hex3      : out std_logic_vector(7 downto 0);
        hex4      : out std_logic_vector(7 downto 0);
        hex5      : out std_logic_vector(7 downto 0)
    );
end entity seg7_disp;

architecture rtl of seg7_disp is
    -- Patrones gfedcba, activos en bajo
    constant APAGADO : std_logic_vector(6 downto 0) := "1111111";
    constant GUION   : std_logic_vector(6 downto 0) := "0111111";

    function digito (d : unsigned(3 downto 0)) return std_logic_vector is
    begin
        case to_integer(d) is
            when 0      => return "1000000";
            when 1      => return "1111001";
            when 2      => return "0100100";
            when 3      => return "0110000";
            when 4      => return "0011001";
            when 5      => return "0010010";
            when 6      => return "0000010";
            when 7      => return "1111000";
            when 8      => return "0000000";
            when 9      => return "0010000";
            when others => return GUION;
        end case;
    end function;

    -- Binario de 9 bits a 3 digitos BCD (centenas, decenas, unidades)
    -- por corrimiento y suma de 3 (double dabble)
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

    -- duty * 100 / 256, de 0 a 99
    function porcentaje (d : std_logic_vector(7 downto 0)) return unsigned is
        variable p : unsigned(14 downto 0);
    begin
        p := unsigned(d) * to_unsigned(100, 7);   -- 8 + 7 = 15 bits
        return "00" & p(14 downto 8);   -- 9 bits para a_bcd
    end function;

    signal p_l, p_r                : unsigned(8 downto 0) := (others => '0');
    signal pct_l, pct_r, dist_bcd : unsigned(11 downto 0) := (others => '0');
    signal sin_eco                : std_logic := '0';
begin

    -- Conversiones en etapas registradas (multiplicacion, luego BCD)
    -- para no encadenar multiplicador, double dabble y decodificador
    -- en un solo ciclo de 20 ns. El % llega 3 ciclos despues del
    -- duty y la distancia 2; en un display no se nota.
    process (clk)
    begin
        if rising_edge(clk) then
            p_l      <= porcentaje(duty_l);
            p_r      <= porcentaje(duty_r);
            pct_l    <= a_bcd(p_l);
            pct_r    <= a_bcd(p_r);
            dist_bcd <= a_bcd(unsigned(dist_cm));
            if dist_cm = "111111111" then
                sin_eco <= '1';
            else
                sin_eco <= '0';
            end if;
        end if;
    end process;

    process (clk)
        variable c, d, u : unsigned(3 downto 0);
    begin
        if rising_edge(clk) then
            hex5 <= '1' & digito('0' & unsigned(estado));
            hex4 <= '1' & digito('0' & unsigned(evento));

            if modo_dist = '0' then
                hex3 <= '1' & digito(pct_l(7 downto 4));
                hex2 <= '1' & digito(pct_l(3 downto 0));
                hex1 <= '1' & digito(pct_r(7 downto 4));
                hex0 <= '1' & digito(pct_r(3 downto 0));
            else
                hex3 <= '0' & digito("00" & unsigned(sensor));   -- con punto
                c := dist_bcd(11 downto 8);
                d := dist_bcd(7 downto 4);
                u := dist_bcd(3 downto 0);
                if sin_eco = '1' then
                    hex2 <= '1' & GUION;
                    hex1 <= '1' & GUION;
                    hex0 <= '1' & GUION;
                else
                    if c = 0 then
                        hex2 <= '1' & APAGADO;
                    else
                        hex2 <= '1' & digito(c);
                    end if;
                    if c = 0 and d = 0 then
                        hex1 <= '1' & APAGADO;
                    else
                        hex1 <= '1' & digito(d);
                    end if;
                    hex0 <= '1' & digito(u);
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
