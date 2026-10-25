-- ============================================================
-- ldr_dir.vhd
-- Convierte las 4 salidas del LM339 (una por LDR) en la
-- direccion de la luz, y el comparador de "luz cerca" del
-- frente en la condicion de meta.
--   ve(0) frente, ve(1) izquierda, ve(2) derecha, ve(3) atras.
--   cerca: segundo umbral, mas alto, solo para la LDR del frente.
-- Cada entrada pasa por un filtro (debounce de FILTRO_MS) porque
-- el comparador titubea cuando la luz esta cerca del umbral.
-- LUZ_ACTIVA indica que nivel del comparador significa "hay luz"
-- (depende de como quedo armado el divisor de la LDR).
--
-- Direccion (prioridad de arriba hacia abajo):
--   F        : I sin D -> FRENTE_IZQ, D sin I -> FRENTE_DER,
--              en otro caso FRENTE
--   I sin D  : IZQ
--   D sin I  : DER
--   I y D    : FRENTE (la luz esta al frente pero no le pega
--              directo al sensor del frente)
--   solo A   : ATRAS
--   ninguna  : NINGUNA
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use work.robot_pkg.all;

entity ldr_dir is
    generic (
        FILTRO_MS  : positive  := 10;
        LUZ_ACTIVA : std_logic := '1'
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;   -- sincrono, activo en alto
        tick_1ms  : in  std_logic;
        ve        : in  std_logic_vector(3 downto 0);  -- sincronizadas
        cerca     : in  std_logic;                     -- sincronizada
        luz       : out std_logic_vector(3 downto 0);  -- filtradas, '1' = luz
        dir_luz   : out std_logic_vector(2 downto 0);
        hay_luz   : out std_logic;
        luz_cerca : out std_logic
    );
end entity ldr_dir;

architecture rtl of ldr_dir is
    signal crudo  : std_logic_vector(4 downto 0);
    signal filt   : std_logic_vector(4 downto 0);
    signal s_dir  : std_logic_vector(2 downto 0) := D_NINGUNA;
    signal s_hay  : std_logic := '0';
    signal s_cer  : std_logic := '0';
begin

    -- '1' = hay luz, sin importar la polaridad del comparador
    crudo(3 downto 0) <= ve when LUZ_ACTIVA = '1' else not ve;
    crudo(4)          <= cerca when LUZ_ACTIVA = '1' else not cerca;

    filtros : for i in 0 to 4 generate
        u_f : entity work.debounce
            generic map (N_MS => FILTRO_MS, INIT => '0')
            port map (
                clk      => clk,
                rst      => rst,
                tick_1ms => tick_1ms,
                raw      => crudo(i),
                clean    => filt(i),
                rise     => open,
                fall     => open
            );
    end generate;

    process (clk)
        variable f, iz, de, at : std_logic;
    begin
        if rising_edge(clk) then
            f  := filt(L_FRENTE);
            iz := filt(L_IZQ);
            de := filt(L_DER);
            at := filt(L_ATRAS);
            if f = '1' then
                if iz = '1' and de = '0' then
                    s_dir <= D_FRENTE_IZQ;
                elsif de = '1' and iz = '0' then
                    s_dir <= D_FRENTE_DER;
                else
                    s_dir <= D_FRENTE;
                end if;
            elsif iz = '1' and de = '0' then
                s_dir <= D_IZQ;
            elsif de = '1' and iz = '0' then
                s_dir <= D_DER;
            elsif iz = '1' and de = '1' then
                s_dir <= D_FRENTE;
            elsif at = '1' then
                s_dir <= D_ATRAS;
            else
                s_dir <= D_NINGUNA;
            end if;
            s_hay <= f or iz or de or at;
            s_cer <= filt(4);
        end if;
    end process;

    luz       <= filt(3 downto 0);
    dir_luz   <= s_dir;
    hay_luz   <= s_hay;
    luz_cerca <= s_cer;

end architecture rtl;
