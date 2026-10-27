-- ============================================================
-- entradas_placa.vhd
-- Botones y switches de la DE10-Lite:
--   KEY0 (activo en bajo) -> accion: pulso de un ciclo al presionar
--   KEY1 (activo en bajo) -> metro_btn: pulso al presionar
--   SW9-SW8               -> modo (00 interpretacion, 01 grabacion,
--                            10 reproduccion, 11 configuracion)
-- Cada entrada pasa por un sincronizador de 2 flip-flops y un
-- antirrebote de 20 ms. SW0-SW7 no se usan.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity entradas_placa is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;   -- sincrono, activo en alto
        tick_1ms  : in  std_logic;
        key       : in  std_logic_vector(1 downto 0);
        sw        : in  std_logic_vector(9 downto 0);
        accion    : out std_logic;
        metro_btn : out std_logic;
        modo      : out std_logic_vector(1 downto 0)
    );
end entity entradas_placa;

architecture estructural of entradas_placa is
    signal key_s   : std_logic_vector(1 downto 0);
    signal sw_s    : std_logic_vector(1 downto 0);
    signal key_on  : std_logic_vector(1 downto 0);
    signal sw_modo : std_logic_vector(1 downto 0);
begin

    sw_modo <= sw(9 downto 8);

    u_sync_key : entity work.sync_2ff
        generic map (WIDTH => 2, INIT => '1')
        port map (clk => clk, d => key, q => key_s);

    u_sync_sw : entity work.sync_2ff
        generic map (WIDTH => 2, INIT => '0')
        port map (clk => clk, d => sw_modo, q => sw_s);

    key_on <= not key_s;     -- '1' = presionado

    u_deb_key0 : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => key_on(0),
                  clean => open, rise => accion, fall => open);

    u_deb_key1 : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => key_on(1),
                  clean => open, rise => metro_btn, fall => open);

    u_deb_sw8 : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => sw_s(0),
                  clean => modo(0), rise => open, fall => open);

    u_deb_sw9 : entity work.debounce
        generic map (N_MS => 20, INIT => '0')
        port map (clk => clk, rst => rst, tick_1ms => tick_1ms, raw => sw_s(1),
                  clean => modo(1), rise => open, fall => open);

end architecture estructural;
