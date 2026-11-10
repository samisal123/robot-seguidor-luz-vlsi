-- ============================================================
-- adsr.vhd
-- Envolvente ADSR de una voz. Acumulador de 24 bits; el nivel
-- de salida son sus 8 bits altos (0 a 255). Avanza una vez por
-- muestra (tick_fs) con los pasos de synth_pkg, usando un solo
-- sumador/restador y un comparador contra la meta de la etapa:
--
--   REPOSO  nivel 0; con gate = '1' pasa a ATAQUE.
--   ATAQUE  sube con paso_attack hasta el maximo -> DECAIMIENTO.
--   DECAIMIENTO baja con paso_decay hasta el nivel de sustain.
--   SOSTENIDO   se queda en el sustain mientras gate = '1'; si el
--               sustain cambia en operacion, va hacia el nuevo
--               nivel con el paso de decay (sin saltos).
--   LIBERACION  baja con paso_release hasta 0 -> REPOSO.
--
-- Al soltar la nota (gate = '0') en cualquier etapa pasa a
-- LIBERACION desde el nivel en que este; si la nota vuelve
-- (gate = '1') durante la liberacion, ataca desde ese nivel, sin
-- caer a 0 (no hay chasquido). Attack, decay y release son
-- tiempos (de toda la escala); sustain es un nivel.
-- activa = '1' mientras no este en REPOSO.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.synth_pkg.all;

entity adsr is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;   -- sincrono, activo en alto
        tick_fs : in  std_logic;
        gate    : in  std_logic;
        atk     : in  std_logic_vector(1 downto 0);
        dec     : in  std_logic_vector(1 downto 0);
        sus     : in  std_logic_vector(1 downto 0);
        rel     : in  std_logic_vector(1 downto 0);
        nivel   : out std_logic_vector(7 downto 0);
        etapa   : out std_logic_vector(2 downto 0);   -- 0 reposo .. 4 liberacion
        activa  : out std_logic
    );
end entity adsr;

architecture rtl of adsr is
    type t_etapa is (REPOSO, ATAQUE, DECAIMIENTO, SOSTENIDO, LIBERACION);
    constant MAXIMO : unsigned(23 downto 0) := (others => '1');

    -- nivel de sustain en 24 bits (255 es el maximo exacto)
    function sustain_24 (sel : std_logic_vector(1 downto 0)) return unsigned is
    begin
        if nivel_sustain(sel) = 255 then
            return MAXIMO;
        else
            return to_unsigned(nivel_sustain(sel) * 65536, 24);
        end if;
    end function;

    signal est : t_etapa := REPOSO;
    signal acc : unsigned(23 downto 0) := (others => '0');

    -- Un solo sumador/restador por voz: en cada muestra la etapa
    -- elige el paso, el sentido y la meta; s = acc +/- paso (con el
    -- bit 24 de acarreo o prestamo) y "llega" dice si s alcanzo o
    -- paso la meta. Equivale a las comparaciones de cada etapa:
    --   ATAQUE      acc + pa >= maximo
    --   DECAIMIENTO acc - pd <= sustain
    --   SOSTENIDO   hacia el sustain con pd, de arriba o de abajo
    --   LIBERACION  acc - pr <= 0
    signal paso     : unsigned(23 downto 0);
    signal objetivo : unsigned(23 downto 0);
    signal meta     : unsigned(23 downto 0);
    signal sube     : std_logic;
    signal s        : unsigned(24 downto 0);
    signal menor    : std_logic;   -- s(23..0) < meta
    signal igual    : std_logic;   -- s(23..0) = meta
    signal llega    : std_logic;
begin

    objetivo <= sustain_24(sus);

    with est select
        paso <= to_unsigned(paso_attack(atk), 24)  when ATAQUE,
                to_unsigned(paso_release(rel), 24) when LIBERACION,
                to_unsigned(paso_decay(dec), 24)   when others;

    with est select
        meta <= MAXIMO          when ATAQUE,
                (others => '0') when LIBERACION,
                objetivo        when others;

    sube <= '1' when est = ATAQUE or (est = SOSTENIDO and acc < objetivo) else '0';

    s <= ('0' & acc) + ('0' & paso) when sube = '1' else
         ('0' & acc) - ('0' & paso);

    menor <= '1' when s(23 downto 0) < meta else '0';
    igual <= '1' when s(23 downto 0) = meta else '0';

    -- subiendo: llega si se desborda o s >= meta;
    -- bajando: llega si hay prestamo (s < 0) o s <= meta
    llega <= (s(24) or not menor) when sube = '1' else
             (s(24) or menor or igual);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                est <= REPOSO;
                acc <= (others => '0');
            elsif tick_fs = '1' then
                if est = REPOSO then
                    acc <= (others => '0');
                    if gate = '1' then
                        est <= ATAQUE;
                    end if;
                elsif gate = '0' and est /= LIBERACION then
                    est <= LIBERACION;      -- soltar: libera desde donde este
                elsif gate = '1' and est = LIBERACION then
                    est <= ATAQUE;          -- volver a tocar: ataca desde ese nivel
                elsif llega = '1' then
                    acc <= meta;
                    case est is
                        when ATAQUE      => est <= DECAIMIENTO;
                        when DECAIMIENTO => est <= SOSTENIDO;
                        when LIBERACION  => est <= REPOSO;
                        when others      => null;    -- SOSTENIDO se queda
                    end case;
                else
                    acc <= s(23 downto 0);
                end if;
            end if;
        end if;
    end process;

    nivel  <= std_logic_vector(acc(23 downto 16));
    activa <= '0' when est = REPOSO else '1';

    with est select
        etapa <= "000" when REPOSO,
                 "001" when ATAQUE,
                 "010" when DECAIMIENTO,
                 "011" when SOSTENIDO,
                 "100" when LIBERACION;

end architecture rtl;
