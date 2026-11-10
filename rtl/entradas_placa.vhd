-- ============================================================
-- entradas_placa.vhd
-- Botones del panel (activos en bajo, con el pull-up interno de
-- la FPGA):
--   btn(0) MODO      -> cada pulsacion pasa al siguiente modo:
--                       interpretacion, grabacion, reproduccion,
--                       configuracion y de nuevo interpretacion
--   btn(1) ACCION    -> accion: pulso de un ciclo al presionar
--   btn(2) METRONOMO -> metro_btn: pulso de un ciclo al presionar
-- Cada boton pasa por un sincronizador de 2 flip-flops y un
-- antirrebote de 20 ms. Despues del reset el modo es
-- interpretacion.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity entradas_placa is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;   -- sincrono, activo en alto
        tick_1ms  : in  std_logic;
        btn       : in  std_logic_vector(2 downto 0);   -- '0' = presionado
        accion    : out std_logic;
        metro_btn : out std_logic;
        modo      : out std_logic_vector(1 downto 0)
    );
end entity entradas_placa;

architecture estructural of entradas_placa is
    signal btn_s  : std_logic_vector(2 downto 0);
    signal btn_on : std_logic_vector(2 downto 0);
    signal p_modo : std_logic;
    signal r_modo : unsigned(1 downto 0) := "00";
begin

    u_sync : entity work.sync_2ff
        generic map (WIDTH => 3, INIT => '1')
        port map (clk => clk, d => btn, q => btn_s);

    btn_on <= not btn_s;     -- '1' = presionado

    u_deb_modo : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => btn_on(0),
                  clean => open, rise => p_modo, fall => open);

    u_deb_accion : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => btn_on(1),
                  clean => open, rise => accion, fall => open);

    u_deb_metro : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => btn_on(2),
                  clean => open, rise => metro_btn, fall => open);

    -- modo: contador de 2 bits que avanza con cada pulsacion de MODO
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_modo <= "00";
            elsif p_modo = '1' then
                r_modo <= r_modo + 1;
            end if;
        end if;
    end process;

    modo <= std_logic_vector(r_modo);

end architecture estructural;
