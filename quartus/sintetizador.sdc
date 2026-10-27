# Reloj principal de la DE10-Lite: 50 MHz
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

# Las entradas externas son asincronas y entran por sync_2ff; las
# salidas van a LEDs, displays, filas de los teclados, PWM de audio
# y VGA, sin requisito de tiempo respecto a otro reloj.
set_false_path -from [get_ports {KEY[*] SW[*] TEC1_COL[*] TEC2_COL[*]}]
set_false_path -to [get_ports {LEDR[*] HEX*[*] TEC1_FIL[*] TEC2_FIL[*] AUDIO_PWM VGA_*}]
