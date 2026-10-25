# ============================================================
# pines.tcl
# Asignacion de pines del robot en la DE10-Lite (10M50DAF484C7G).
# Pines de la tarjeta (reloj, KEY, SW, LEDR, HEX, VGA) copiados
# del DE10_LITE_Golden_Top.qsf de Terasic. Sensores y motores
# van al header GPIO de 2x20 (3.3 V); el numero de pin fisico del
# header esta en el comentario (pin 11 = 5 V, 12 y 30 = GND,
# 29 = 3.3 V). Ver docs/CABLEADO.md.
# Los nombres con corchetes van entre llaves para que Tcl no los
# interprete como sustitucion de comandos.
# Lo carga crear_proyecto.tcl.
# ============================================================

# ---- Reloj ----
set_location_assignment PIN_P11 -to MAX10_CLK1_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MAX10_CLK1_50

# ---- Botones (activos en bajo) ----
set_location_assignment PIN_B8 -to {KEY[0]}
set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to {KEY[0]}
set_location_assignment PIN_A7 -to {KEY[1]}
set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to {KEY[1]}

# ---- Switches ----
set_location_assignment PIN_C10 -to {SW[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[0]}
set_location_assignment PIN_C11 -to {SW[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[1]}
set_location_assignment PIN_D12 -to {SW[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[2]}
set_location_assignment PIN_C12 -to {SW[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[3]}
set_location_assignment PIN_A12 -to {SW[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[4]}
set_location_assignment PIN_B12 -to {SW[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[5]}
set_location_assignment PIN_A13 -to {SW[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[6]}
set_location_assignment PIN_A14 -to {SW[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[7]}
set_location_assignment PIN_B14 -to {SW[8]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[8]}
set_location_assignment PIN_F15 -to {SW[9]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[9]}

# ---- LEDs ----
set_location_assignment PIN_A8 -to {LEDR[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[0]}
set_location_assignment PIN_A9 -to {LEDR[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[1]}
set_location_assignment PIN_A10 -to {LEDR[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[2]}
set_location_assignment PIN_B10 -to {LEDR[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[3]}
set_location_assignment PIN_D13 -to {LEDR[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[4]}
set_location_assignment PIN_C13 -to {LEDR[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[5]}
set_location_assignment PIN_E14 -to {LEDR[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[6]}
set_location_assignment PIN_D14 -to {LEDR[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[7]}
set_location_assignment PIN_A11 -to {LEDR[8]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[8]}
set_location_assignment PIN_B11 -to {LEDR[9]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LEDR[9]}

# ---- Displays de 7 segmentos (bit 7 = punto) ----
set_location_assignment PIN_C14 -to {HEX0[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[0]}
set_location_assignment PIN_E15 -to {HEX0[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[1]}
set_location_assignment PIN_C15 -to {HEX0[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[2]}
set_location_assignment PIN_C16 -to {HEX0[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[3]}
set_location_assignment PIN_E16 -to {HEX0[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[4]}
set_location_assignment PIN_D17 -to {HEX0[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[5]}
set_location_assignment PIN_C17 -to {HEX0[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[6]}
set_location_assignment PIN_D15 -to {HEX0[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX0[7]}
set_location_assignment PIN_C18 -to {HEX1[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[0]}
set_location_assignment PIN_D18 -to {HEX1[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[1]}
set_location_assignment PIN_E18 -to {HEX1[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[2]}
set_location_assignment PIN_B16 -to {HEX1[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[3]}
set_location_assignment PIN_A17 -to {HEX1[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[4]}
set_location_assignment PIN_A18 -to {HEX1[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[5]}
set_location_assignment PIN_B17 -to {HEX1[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[6]}
set_location_assignment PIN_A16 -to {HEX1[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX1[7]}
set_location_assignment PIN_B20 -to {HEX2[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[0]}
set_location_assignment PIN_A20 -to {HEX2[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[1]}
set_location_assignment PIN_B19 -to {HEX2[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[2]}
set_location_assignment PIN_A21 -to {HEX2[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[3]}
set_location_assignment PIN_B21 -to {HEX2[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[4]}
set_location_assignment PIN_C22 -to {HEX2[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[5]}
set_location_assignment PIN_B22 -to {HEX2[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[6]}
set_location_assignment PIN_A19 -to {HEX2[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX2[7]}
set_location_assignment PIN_F21 -to {HEX3[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[0]}
set_location_assignment PIN_E22 -to {HEX3[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[1]}
set_location_assignment PIN_E21 -to {HEX3[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[2]}
set_location_assignment PIN_C19 -to {HEX3[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[3]}
set_location_assignment PIN_C20 -to {HEX3[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[4]}
set_location_assignment PIN_D19 -to {HEX3[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[5]}
set_location_assignment PIN_E17 -to {HEX3[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[6]}
set_location_assignment PIN_D22 -to {HEX3[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX3[7]}
set_location_assignment PIN_F18 -to {HEX4[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[0]}
set_location_assignment PIN_E20 -to {HEX4[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[1]}
set_location_assignment PIN_E19 -to {HEX4[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[2]}
set_location_assignment PIN_J18 -to {HEX4[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[3]}
set_location_assignment PIN_H19 -to {HEX4[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[4]}
set_location_assignment PIN_F19 -to {HEX4[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[5]}
set_location_assignment PIN_F20 -to {HEX4[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[6]}
set_location_assignment PIN_F17 -to {HEX4[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX4[7]}
set_location_assignment PIN_J20 -to {HEX5[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[0]}
set_location_assignment PIN_K20 -to {HEX5[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[1]}
set_location_assignment PIN_L18 -to {HEX5[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[2]}
set_location_assignment PIN_N18 -to {HEX5[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[3]}
set_location_assignment PIN_M20 -to {HEX5[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[4]}
set_location_assignment PIN_N19 -to {HEX5[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[5]}
set_location_assignment PIN_N20 -to {HEX5[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[6]}
set_location_assignment PIN_L19 -to {HEX5[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {HEX5[7]}

# ---- VGA ----
set_location_assignment PIN_AA1 -to {VGA_R[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_R[0]}
set_location_assignment PIN_V1 -to {VGA_R[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_R[1]}
set_location_assignment PIN_Y2 -to {VGA_R[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_R[2]}
set_location_assignment PIN_Y1 -to {VGA_R[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_R[3]}
set_location_assignment PIN_W1 -to {VGA_G[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_G[0]}
set_location_assignment PIN_T2 -to {VGA_G[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_G[1]}
set_location_assignment PIN_R2 -to {VGA_G[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_G[2]}
set_location_assignment PIN_R1 -to {VGA_G[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_G[3]}
set_location_assignment PIN_P1 -to {VGA_B[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_B[0]}
set_location_assignment PIN_T1 -to {VGA_B[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_B[1]}
set_location_assignment PIN_P4 -to {VGA_B[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_B[2]}
set_location_assignment PIN_N2 -to {VGA_B[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_B[3]}
set_location_assignment PIN_N3 -to VGA_HS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
set_location_assignment PIN_N1 -to VGA_VS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS

# ---- Header GPIO 2x20: sensores, driver, encoders y UART ----
set_location_assignment PIN_V10 -to {US_TRIG[0]}   ;# header pin 1, GPIO[0]: TRIG ultrasonico frente
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_TRIG[0]}
set_location_assignment PIN_W10 -to {US_ECHO[0]}   ;# header pin 2, GPIO[1]: ECHO ultrasonico frente (con divisor)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_ECHO[0]}
set_location_assignment PIN_V9 -to {US_TRIG[1]}   ;# header pin 3, GPIO[2]: TRIG ultrasonico diagonal izquierda
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_TRIG[1]}
set_location_assignment PIN_W9 -to {US_ECHO[1]}   ;# header pin 4, GPIO[3]: ECHO ultrasonico diagonal izquierda (con divisor)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_ECHO[1]}
set_location_assignment PIN_V8 -to {US_TRIG[2]}   ;# header pin 5, GPIO[4]: TRIG ultrasonico diagonal derecha
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_TRIG[2]}
set_location_assignment PIN_W8 -to {US_ECHO[2]}   ;# header pin 6, GPIO[5]: ECHO ultrasonico diagonal derecha (con divisor)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_ECHO[2]}
set_location_assignment PIN_V7 -to {US_TRIG[3]}   ;# header pin 7, GPIO[6]: TRIG ultrasonico atras
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_TRIG[3]}
set_location_assignment PIN_W7 -to {US_ECHO[3]}   ;# header pin 8, GPIO[7]: ECHO ultrasonico atras (con divisor)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {US_ECHO[3]}
set_location_assignment PIN_W6 -to {LDR_VE[0]}   ;# header pin 9, GPIO[8]: LM339 #1, comparador LDR frente
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LDR_VE[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {LDR_VE[0]}
set_location_assignment PIN_V5 -to {LDR_VE[1]}   ;# header pin 10, GPIO[9]: LM339 #1, comparador LDR izquierda
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LDR_VE[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {LDR_VE[1]}
set_location_assignment PIN_W5 -to {LDR_VE[2]}   ;# header pin 13, GPIO[10]: LM339 #1, comparador LDR derecha
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LDR_VE[2]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {LDR_VE[2]}
set_location_assignment PIN_AA15 -to {LDR_VE[3]}   ;# header pin 14, GPIO[11]: LM339 #1, comparador LDR atras
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LDR_VE[3]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {LDR_VE[3]}
set_location_assignment PIN_AA14 -to LDR_CERCA   ;# header pin 15, GPIO[12]: Comparador de luz cerca (LDR frente, umbral alto)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LDR_CERCA
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to LDR_CERCA
set_location_assignment PIN_W12 -to MOT_PWMA   ;# header pin 17, GPIO[14]: TB6612FNG PWMA (rueda izquierda)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_PWMA
set_location_assignment PIN_AB13 -to MOT_AIN1   ;# header pin 18, GPIO[15]: TB6612FNG AIN1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_AIN1
set_location_assignment PIN_AB12 -to MOT_AIN2   ;# header pin 19, GPIO[16]: TB6612FNG AIN2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_AIN2
set_location_assignment PIN_Y11 -to MOT_STBY   ;# header pin 20, GPIO[17]: TB6612FNG STBY
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_STBY
set_location_assignment PIN_AB11 -to MOT_BIN1   ;# header pin 21, GPIO[18]: TB6612FNG BIN1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_BIN1
set_location_assignment PIN_W11 -to MOT_BIN2   ;# header pin 22, GPIO[19]: TB6612FNG BIN2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_BIN2
set_location_assignment PIN_AB10 -to MOT_PWMB   ;# header pin 23, GPIO[20]: TB6612FNG PWMB (rueda derecha)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MOT_PWMB
set_location_assignment PIN_AA9 -to {ENC_L[0]}   ;# header pin 25, GPIO[22]: Encoder izquierdo canal A (o sensor de ranura)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {ENC_L[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {ENC_L[0]}
set_location_assignment PIN_Y8 -to {ENC_L[1]}   ;# header pin 26, GPIO[23]: Encoder izquierdo canal B (opcional)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {ENC_L[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {ENC_L[1]}
set_location_assignment PIN_AA8 -to {ENC_R[0]}   ;# header pin 27, GPIO[24]: Encoder derecho canal A (o sensor de ranura)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {ENC_R[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {ENC_R[0]}
set_location_assignment PIN_Y7 -to {ENC_R[1]}   ;# header pin 28, GPIO[25]: Encoder derecho canal B (opcional)
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {ENC_R[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {ENC_R[1]}
set_location_assignment PIN_AA7 -to UART_TX   ;# header pin 31, GPIO[26]: Al RX del convertidor USB-TTL
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_TX

