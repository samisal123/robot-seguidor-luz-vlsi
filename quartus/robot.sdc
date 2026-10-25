# Reloj principal de la DE10-Lite: 50 MHz
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

# Las entradas externas son asincronas y entran por sync_2ff; las
# salidas van a LEDs, displays, driver, sensores, UART y VGA, sin
# requisito de tiempo respecto a otro reloj.
set_false_path -from [get_ports {KEY[*] SW[*] US_ECHO[*] LDR_VE[*] LDR_CERCA ENC_L[*] ENC_R[*]}]
set_false_path -to [get_ports {LEDR[*] HEX*[*] US_TRIG[*] MOT_* UART_TX VGA_*}]
