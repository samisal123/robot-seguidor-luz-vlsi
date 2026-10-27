-- ============================================================
-- adsr.vhd
-- Envolvente ADSR de una voz. Acumulador de 24 bits; el nivel
-- de salida son sus 8 bits altos (0 a 255). Avanza una vez por
-- muestra (tick_fs) con los pasos de synth_pkg:
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
    constant MAXIMO : natural := 2 ** 24 - 1;

    signal est : t_etapa := REPOSO;
    signal acc : natural range 0 to MAXIMO := 0;

    -- pasos de cada etapa y nivel de sustain en 24 bits (multiplexores
    -- de constantes; cambian solo cuando cambia la configuracion)
    signal pa, pd, pr : natural range 0 to 2 ** 18 - 1;
    signal objetivo   : natural range 0 to MAXIMO;
begin

    pa       <= paso_attack(atk);
    pd       <= paso_decay(dec);
    pr       <= paso_release(rel);
    objetivo <= nivel_sustain(sus) * 65536 + 65535 * (nivel_sustain(sus) / 255);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                est <= REPOSO;
                acc <= 0;
            elsif tick_fs = '1' then
                case est is
                    when REPOSO =>
                        acc <= 0;
                        if gate = '1' then
                            est <= ATAQUE;
                        end if;

                    when ATAQUE =>
                        if gate = '0' then
                            est <= LIBERACION;
                        elsif acc >= MAXIMO - pa then
                            acc <= MAXIMO;
                            est <= DECAIMIENTO;
                        else
                            acc <= acc + pa;
                        end if;

                    when DECAIMIENTO =>
                        if gate = '0' then
                            est <= LIBERACION;
                        elsif acc <= objetivo + pd then
                            acc <= objetivo;
                            est <= SOSTENIDO;
                        else
                            acc <= acc - pd;
                        end if;

                    when SOSTENIDO =>
                        if gate = '0' then
                            est <= LIBERACION;
                        elsif acc > objetivo + pd then
                            acc <= acc - pd;
                        elsif acc + pd < objetivo then
                            acc <= acc + pd;
                        else
                            acc <= objetivo;
                        end if;

                    when LIBERACION =>
                        if gate = '1' then
                            est <= ATAQUE;
                        elsif acc <= pr then
                            acc <= 0;
                            est <= REPOSO;
                        else
                            acc <= acc - pr;
                        end if;
                end case;
            end if;
        end if;
    end process;

    nivel  <= std_logic_vector(to_unsigned(acc / 65536, 8));
    activa <= '0' when est = REPOSO else '1';

    with est select
        etapa <= "000" when REPOSO,
                 "001" when ATAQUE,
                 "010" when DECAIMIENTO,
                 "011" when SOSTENIDO,
                 "100" when LIBERACION;

end architecture rtl;
