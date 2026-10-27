-- ============================================================
-- eco.vhd
-- Efecto de eco (retardo con realimentacion):
--   y[n] = saturar( x[n] + y[n - RETARDO] / 2 )
-- Con RETARDO = 8192 muestras el eco llega 168 ms despues y cada
-- repeticion vale la mitad de la anterior.
-- La linea de retardo es una RAM de RETARDO x 12 bits con
-- escritura sincrona y lectura registrada (plantilla de RAM de un
-- puerto de Quartus, se mapea en bloques M9K). Por cada muestra se
-- lee la posicion ptr (lo que se escribio hace RETARDO muestras),
-- se calcula y, se escribe y en esa misma posicion y ptr avanza.
-- La RAM no necesita valores iniciales: hasta que ptr da la
-- primera vuelta despues del reset (lleno = '0') el retardo se
-- toma como 0, asi nunca se oye basura.
-- Con activo = '0' la muestra pasa sin cambio y en la RAM se
-- escribe x, asi al activarlo el eco empieza con lo reciente.
-- sal_valida llega 3 ciclos despues de ent_valida; acepta una
-- muestra cada 3 ciclos o mas. satura = '1' junto con sal_valida
-- si la suma se tuvo que saturar.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eco is
    generic (
        RETARDO : positive := 8192     -- muestras
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;   -- sincrono, activo en alto
        activo     : in  std_logic;
        ent_valida : in  std_logic;
        x          : in  std_logic_vector(11 downto 0);
        y          : out std_logic_vector(11 downto 0);
        sal_valida : out std_logic;
        satura     : out std_logic
    );
end entity eco;

architecture rtl of eco is
    constant TOPE : integer := 2032;   -- 127 * 16

    type t_ram is array (0 to RETARDO - 1) of std_logic_vector(11 downto 0);
    signal ram : t_ram;

    signal ptr   : natural range 0 to RETARDO - 1 := 0;
    signal q     : std_logic_vector(11 downto 0);
    signal we    : std_logic := '0';
    signal wdato : std_logic_vector(11 downto 0) := (others => '0');
    signal lleno : std_logic := '0';

    type t_fase is (REPOSO, CALCULA, ESCRIBE);
    signal fase  : t_fase := REPOSO;
    signal x_r   : signed(11 downto 0) := (others => '0');
    signal act_r : std_logic := '0';
    signal s_y   : signed(11 downto 0) := (others => '0');
    signal s_val : std_logic := '0';
    signal s_sat : std_logic := '0';
begin

    -- RAM: escritura sincrona, lectura registrada (M9K)
    process (clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(ptr) <= wdato;
            end if;
            q <= ram(ptr);
        end if;
    end process;

    process (clk)
        variable d : integer range -2048 to 2047;
        variable s : integer range -4096 to 4096;
        variable r : integer range -2032 to 2032;
    begin
        if rising_edge(clk) then
            we    <= '0';
            s_val <= '0';
            if rst = '1' then
                fase  <= REPOSO;
                ptr   <= 0;
                lleno <= '0';
                s_y   <= (others => '0');
                s_sat <= '0';
            else
                case fase is
                    when REPOSO =>
                        -- q ya trae ram(ptr): ptr no cambio desde la ultima escritura
                        if ent_valida = '1' then
                            x_r   <= signed(x);
                            act_r <= activo;
                            fase  <= CALCULA;
                        end if;

                    when CALCULA =>
                        if lleno = '1' then
                            d := to_integer(signed(q));
                        else
                            d := 0;
                        end if;
                        -- y = x + d/2 (corrimiento aritmetico), saturado
                        s := to_integer(x_r) + to_integer(shift_right(to_signed(d, 12), 1));
                        if s > TOPE then
                            r := TOPE;
                        elsif s < -TOPE then
                            r := -TOPE;
                        else
                            r := s;
                        end if;
                        if act_r = '1' then
                            s_y   <= to_signed(r, 12);
                            wdato <= std_logic_vector(to_signed(r, 12));
                            if s > TOPE or s < -TOPE then
                                s_sat <= '1';
                            else
                                s_sat <= '0';
                            end if;
                        else
                            s_y   <= x_r;
                            wdato <= std_logic_vector(x_r);
                            s_sat <= '0';
                        end if;
                        we   <= '1';
                        fase <= ESCRIBE;

                    when ESCRIBE =>
                        -- en este flanco la RAM escribe wdato en ram(ptr)
                        if ptr = RETARDO - 1 then
                            ptr   <= 0;
                            lleno <= '1';
                        else
                            ptr <= ptr + 1;
                        end if;
                        s_val <= '1';
                        fase  <= REPOSO;
                end case;
            end if;
        end if;
    end process;

    y          <= std_logic_vector(s_y);
    sal_valida <= s_val;
    satura     <= s_sat;

end architecture rtl;
