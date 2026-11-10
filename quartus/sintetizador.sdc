# Reloj de la tarjeta EP2C5T144: 50 MHz en el pin 17. El PLL
# (pll_25mhz) saca el reloj del sistema de 25 MHz; derive_pll_clocks
# crea esa restriccion automaticamente.
create_clock -name clk50 -period 20.000 [get_ports {CLOCK_50}]
derive_pll_clocks
derive_clock_uncertainty

# Las entradas externas son asincronas y entran por sync_2ff; las
# salidas van a LEDs, filas de los teclados, PWM de audio y VGA,
# sin requisito de tiempo respecto a otro reloj.
set_false_path -from [get_ports {BTN_RESET BTN[*] TEC1_COL[*] TEC2_COL[*]}]
set_false_path -to [get_ports {LED[*] TEC1_FIL[*] TEC2_FIL[*] AUDIO_PWM VGA_*}]
