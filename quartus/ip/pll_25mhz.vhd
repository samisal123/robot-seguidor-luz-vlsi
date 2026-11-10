-- ============================================================
-- pll_25mhz.vhd
-- PLL de la Cyclone II: 50 MHz del oscilador de la tarjeta
-- (pin 17) -> 25 MHz para todo el sistema (c0). locked = '1'
-- cuando la salida ya es estable; mientras tanto el sistema se
-- queda en reset (reset_encendido).
-- Es una instancia directa de altpll (biblioteca altera_mf de
-- Quartus), con los mismos parametros que pone el MegaWizard
-- (ALTPLL, entrada de 50 MHz, c0 = 50 * 1 / 2). Solo existe en el
-- proyecto de Quartus; en simulacion se usa sim/modelo_pll.vhd,
-- que tiene la misma entidad.
-- Si Quartus no acepta este archivo, se puede regenerar igual:
-- Tools > MegaWizard Plug-In Manager > ALTPLL, nombre pll_25mhz,
-- VHDL, inclk0 de 50 MHz, salida c0 de 25 MHz y salida locked.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity pll_25mhz is
    port (
        inclk0 : in  std_logic;   -- 50 MHz
        c0     : out std_logic;   -- 25 MHz
        locked : out std_logic
    );
end entity pll_25mhz;

architecture syn of pll_25mhz is
    signal relojes : std_logic_vector(5 downto 0);
    signal entrada : std_logic_vector(1 downto 0);
begin

    entrada <= '0' & inclk0;
    c0      <= relojes(0);

    u_pll : altpll
        generic map (
            intended_device_family => "Cyclone II",
            lpm_type               => "altpll",
            lpm_hint               => "CBX_MODULE_PREFIX=pll_25mhz",
            operation_mode         => "NORMAL",
            compensate_clock       => "CLK0",
            inclk0_input_frequency => 20000,      -- ps (50 MHz)
            clk0_multiply_by       => 1,
            clk0_divide_by         => 2,
            clk0_duty_cycle        => 50,
            clk0_phase_shift       => "0",
            port_inclk0            => "PORT_USED",
            port_clk0              => "PORT_USED",
            port_locked            => "PORT_USED",
            port_clk1              => "PORT_UNUSED",
            port_clk2              => "PORT_UNUSED",
            port_clk3              => "PORT_UNUSED",
            port_clk4              => "PORT_UNUSED",
            port_clk5              => "PORT_UNUSED",
            port_areset            => "PORT_UNUSED",
            port_pfdena            => "PORT_UNUSED",
            port_inclk1            => "PORT_UNUSED"
        )
        port map (
            inclk  => entrada,
            clk    => relojes,
            locked => locked
        );

end architecture syn;
