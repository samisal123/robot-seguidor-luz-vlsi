-- ============================================================
-- pll_25mhz.vhd
-- PLL de la Cyclone II: 50 MHz del oscilador de la tarjeta
-- (pin 17) -> 25 MHz para todo el sistema (c0). locked = '1'
-- cuando la salida ya es estable; mientras tanto el sistema se
-- queda en reset (reset_encendido).
-- Es una instancia directa de altpll (biblioteca altera_mf de
-- Quartus), escrita como la escribe el MegaWizard (ALTPLL,
-- entrada de 50 MHz, c0 = 50 * 1 / 2). Solo existe en el
-- proyecto de Quartus; en simulacion se usa sim/modelo_pll.vhd,
-- que tiene la misma entidad.
-- Ojo: el componente altpll se declara aqui con solo los
-- genericos que se usan, igual que el MegaWizard. Si se usa la
-- declaracion de altera_mf.altera_mf_components, VHDL le pasa
-- todos los genericos (con sus valores por omision) y Quartus
-- 13.0 SP1 los toma como "usados": falla con "PLL uses test-only
-- parameter c0_test_source" (error 14157) y "illegal value 0 for
-- inclk1_input_frequency" (error 14141).
-- Si Quartus no acepta este archivo, se puede regenerar igual:
-- Tools > MegaWizard Plug-In Manager > ALTPLL, nombre pll_25mhz,
-- VHDL, inclk0 de 50 MHz, salida c0 de 25 MHz y salida locked.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

entity pll_25mhz is
    port (
        inclk0 : in  std_logic;   -- 50 MHz
        c0     : out std_logic;   -- 25 MHz
        locked : out std_logic
    );
end entity pll_25mhz;

architecture syn of pll_25mhz is

    component altpll
        generic (
            clk0_divide_by          : natural;
            clk0_duty_cycle         : natural;
            clk0_multiply_by        : natural;
            clk0_phase_shift        : string;
            compensate_clock        : string;
            inclk0_input_frequency  : natural;
            intended_device_family  : string;
            lpm_hint                : string;
            lpm_type                : string;
            operation_mode          : string;
            port_activeclock        : string;
            port_areset             : string;
            port_clkbad0            : string;
            port_clkbad1            : string;
            port_clkloss            : string;
            port_clkswitch          : string;
            port_configupdate       : string;
            port_fbin               : string;
            port_inclk0             : string;
            port_inclk1             : string;
            port_locked             : string;
            port_pfdena             : string;
            port_phasecounterselect : string;
            port_phasedone          : string;
            port_phasestep          : string;
            port_phaseupdown        : string;
            port_pllena             : string;
            port_scanaclr           : string;
            port_scanclk            : string;
            port_scanclkena         : string;
            port_scandata           : string;
            port_scandataout        : string;
            port_scandone           : string;
            port_scanread           : string;
            port_scanwrite          : string;
            port_clk0               : string;
            port_clk1               : string;
            port_clk2               : string;
            port_clk3               : string;
            port_clk4               : string;
            port_clk5               : string;
            port_clkena0            : string;
            port_clkena1            : string;
            port_clkena2            : string;
            port_clkena3            : string;
            port_clkena4            : string;
            port_clkena5            : string;
            port_extclk0            : string;
            port_extclk1            : string;
            port_extclk2            : string;
            port_extclk3            : string
        );
        port (
            inclk  : in  std_logic_vector(1 downto 0);
            clk    : out std_logic_vector(5 downto 0);
            locked : out std_logic
        );
    end component;

    signal relojes : std_logic_vector(5 downto 0);
    signal entrada : std_logic_vector(1 downto 0);
begin

    entrada <= '0' & inclk0;
    c0      <= relojes(0);

    u_pll : altpll
        generic map (
            clk0_divide_by          => 2,
            clk0_duty_cycle         => 50,
            clk0_multiply_by        => 1,
            clk0_phase_shift        => "0",
            compensate_clock        => "CLK0",
            inclk0_input_frequency  => 20000,      -- ps (50 MHz)
            intended_device_family  => "Cyclone II",
            lpm_hint                => "CBX_MODULE_PREFIX=pll_25mhz",
            lpm_type                => "altpll",
            operation_mode          => "NORMAL",
            port_activeclock        => "PORT_UNUSED",
            port_areset             => "PORT_UNUSED",
            port_clkbad0            => "PORT_UNUSED",
            port_clkbad1            => "PORT_UNUSED",
            port_clkloss            => "PORT_UNUSED",
            port_clkswitch          => "PORT_UNUSED",
            port_configupdate       => "PORT_UNUSED",
            port_fbin               => "PORT_UNUSED",
            port_inclk0             => "PORT_USED",
            port_inclk1             => "PORT_UNUSED",
            port_locked             => "PORT_USED",
            port_pfdena             => "PORT_UNUSED",
            port_phasecounterselect => "PORT_UNUSED",
            port_phasedone          => "PORT_UNUSED",
            port_phasestep          => "PORT_UNUSED",
            port_phaseupdown        => "PORT_UNUSED",
            port_pllena             => "PORT_UNUSED",
            port_scanaclr           => "PORT_UNUSED",
            port_scanclk            => "PORT_UNUSED",
            port_scanclkena         => "PORT_UNUSED",
            port_scandata           => "PORT_UNUSED",
            port_scandataout        => "PORT_UNUSED",
            port_scandone           => "PORT_UNUSED",
            port_scanread           => "PORT_UNUSED",
            port_scanwrite          => "PORT_UNUSED",
            port_clk0               => "PORT_USED",
            port_clk1               => "PORT_UNUSED",
            port_clk2               => "PORT_UNUSED",
            port_clk3               => "PORT_UNUSED",
            port_clk4               => "PORT_UNUSED",
            port_clk5               => "PORT_UNUSED",
            port_clkena0            => "PORT_UNUSED",
            port_clkena1            => "PORT_UNUSED",
            port_clkena2            => "PORT_UNUSED",
            port_clkena3            => "PORT_UNUSED",
            port_clkena4            => "PORT_UNUSED",
            port_clkena5            => "PORT_UNUSED",
            port_extclk0            => "PORT_UNUSED",
            port_extclk1            => "PORT_UNUSED",
            port_extclk2            => "PORT_UNUSED",
            port_extclk3            => "PORT_UNUSED"
        )
        port map (
            inclk  => entrada,
            clk    => relojes,
            locked => locked
        );

end architecture syn;
