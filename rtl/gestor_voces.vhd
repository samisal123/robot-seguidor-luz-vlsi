-- ============================================================
-- gestor_voces.vhd
-- Reparte hasta 3 notas pedidas entre las 3 voces (polifonia).
-- Entrada conjunto: notas pedidas, 7 bits cada una (0 = vacia),
-- del teclado o del secuenciador. Cada ciclo de reloj:
--   1) Suelta (gate = '0') toda voz cuya nota ya no se pide. La
--      voz conserva su nota para que la liberacion suene en la
--      misma frecuencia.
--   2) Busca la primera nota pedida que no tenga voz y le da una
--      voz libre (gate = '0'), en este orden de preferencia:
--        a) la voz que ya tenia esa nota (se volvio a presionar
--           durante su liberacion; asi no se duplica la nota),
--        b) una voz en reposo (activa = '0'),
--        c) cualquier voz libre (corta una liberacion).
--      Se asigna una nota por ciclo; un acorde de 3 notas queda
--      repartido en 3 ciclos (60 ns).
-- Como hay 3 voces y a lo mas 3 notas, siempre hay voz libre
-- para cada nota pedida.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gestor_voces is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- sincrono, activo en alto
        conjunto : in  std_logic_vector(20 downto 0);   -- notas pedidas
        activas  : in  std_logic_vector(2 downto 0);    -- voces que aun suenan
        notas_v  : out std_logic_vector(20 downto 0);   -- nota de cada voz
        gates    : out std_logic_vector(2 downto 0)
    );
end entity gestor_voces;

architecture rtl of gestor_voces is
    subtype t_nota is std_logic_vector(6 downto 0);
    type t_notas is array (0 to 2) of t_nota;

    constant VACIA : t_nota := (others => '0');

    -- estado registrado y siguiente estado
    signal nv, nv_sig : t_notas := (others => VACIA);
    signal gt, gt_sig : std_logic_vector(2 downto 0) := (others => '0');

    function pedida (c : std_logic_vector(20 downto 0); i : natural) return t_nota is
    begin
        return c(7 * i + 6 downto 7 * i);
    end function;
begin

    -- siguiente estado (combinacional)
    process (conjunto, activas, nv, gt)
        variable g       : std_logic_vector(2 downto 0);
        variable n       : t_notas;
        variable esta    : boolean;
        variable h       : t_nota;
        variable elegida : integer range -1 to 2;
        variable listo   : boolean;
    begin
        g := gt;
        n := nv;

        -- 1) soltar las voces cuya nota ya no se pide
        for v in 0 to 2 loop
            esta := false;
            for i in 0 to 2 loop
                if pedida(conjunto, i) /= VACIA and pedida(conjunto, i) = nv(v) then
                    esta := true;
                end if;
            end loop;
            if not esta then
                g(v) := '0';
            end if;
        end loop;

        -- 2) dar voz a la primera nota pedida que no tenga
        listo := false;
        for i in 0 to 2 loop
            h := pedida(conjunto, i);
            if h /= VACIA and not listo then
                esta := false;
                for v in 0 to 2 loop
                    if g(v) = '1' and nv(v) = h then
                        esta := true;
                    end if;
                end loop;
                if not esta then
                    -- preferencias de menor a mayor; la ultima que
                    -- se cumple gana, y en cada una gana la voz 0
                    elegida := -1;
                    for v in 2 downto 0 loop
                        if g(v) = '0' then
                            elegida := v;               -- c) libre
                        end if;
                    end loop;
                    for v in 2 downto 0 loop
                        if g(v) = '0' and activas(v) = '0' then
                            elegida := v;               -- b) en reposo
                        end if;
                    end loop;
                    for v in 2 downto 0 loop
                        if g(v) = '0' and nv(v) = h then
                            elegida := v;               -- a) misma nota
                        end if;
                    end loop;
                    if elegida >= 0 then
                        n(elegida) := h;
                        g(elegida) := '1';
                    end if;
                    listo := true;
                end if;
            end if;
        end loop;

        nv_sig <= n;
        gt_sig <= g;
    end process;

    -- registros
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                nv <= (others => VACIA);
                gt <= (others => '0');
            else
                nv <= nv_sig;
                gt <= gt_sig;
            end if;
        end if;
    end process;

    salida : for v in 0 to 2 generate
        notas_v(7 * v + 6 downto 7 * v) <= nv(v);
    end generate;
    gates <= gt;

end architecture rtl;
