# ============================================================
# pines.tcl
# Asignacion de pines del sintetizador en la DE10-Lite
# (10M50DAF484C7G). Los pines de la tarjeta (reloj, KEY, SW,
# LEDR, HEX y VGA) son los del DE10_LITE_Golden_Top.qsf de
# Terasic. Los teclados y la salida de audio van al header GPIO
# de 2x20 (3.3 V); el pin fisico del header esta en cada
# comentario (pin 11 = 5 V, 12 y 30 = GND, 29 = 3.3 V).
# Ver docs/CABLEADO.md.
# Los nombres con corchetes van entre llaves para que Tcl no los
# interprete como sustitucion de comandos.
# Lo carga crear_proyecto.tcl.
# ============================================================

# ---- Reloj de 50 MHz ----
set_location_assignment PIN_P11 -to MAX10_CLK1_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MAX10_CLK1_50

# ---- Botones (activos en bajo): KEY0 accion, KEY1 metronomo ----
set_location_assignment PIN_B8 -to {KEY[0]}
set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to {KEY[0]}
set_location_assignment PIN_A7 -to {KEY[1]}
set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to {KEY[1]}

# ---- Switches: SW9-SW8 modo (SW0-SW7 sin uso) ----
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

# ---- Displays de 7 segmentos (bit 7 = punto, activos en bajo) ----
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

# ---- VGA (DAC resistivo de 4 bits por color en la tarjeta) ----
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

# ---- Teclado 1 (octava base): pines 1 a 8 del teclado -> pines 1 a 8 del header ----
# Filas en colector abierto ('0' o 'Z'); columnas con pull-up interno.
set_location_assignment PIN_V10 -to {TEC1_FIL[0]}    ;# GPIO[0], header 1, fila 1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[0]}
set_location_assignment PIN_W10 -to {TEC1_FIL[1]}    ;# GPIO[1], header 2, fila 2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[1]}
set_location_assignment PIN_V9 -to {TEC1_FIL[2]}    ;# GPIO[2], header 3, fila 3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[2]}
set_location_assignment PIN_W9 -to {TEC1_FIL[3]}    ;# GPIO[3], header 4, fila 4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[3]}
set_location_assignment PIN_V8 -to {TEC1_COL[0]}    ;# GPIO[4], header 5, columna 1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[0]}
set_location_assignment PIN_W8 -to {TEC1_COL[1]}    ;# GPIO[5], header 6, columna 2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[1]}
set_location_assignment PIN_V7 -to {TEC1_COL[2]}    ;# GPIO[6], header 7, columna 3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[2]}
set_location_assignment PIN_W7 -to {TEC1_COL[3]}    ;# GPIO[7], header 8, columna 4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[3]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[2]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[3]}

# ---- Teclado 2 (octava base + 1): pines 1 a 8 del teclado -> pines 13 a 20 del header ----
set_location_assignment PIN_W5 -to {TEC2_FIL[0]}    ;# GPIO[10], header 13, fila 1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[0]}
set_location_assignment PIN_AA15 -to {TEC2_FIL[1]}    ;# GPIO[11], header 14, fila 2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[1]}
set_location_assignment PIN_AA14 -to {TEC2_FIL[2]}    ;# GPIO[12], header 15, fila 3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[2]}
set_location_assignment PIN_W13 -to {TEC2_FIL[3]}    ;# GPIO[13], header 16, fila 4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[3]}
set_location_assignment PIN_W12 -to {TEC2_COL[0]}    ;# GPIO[14], header 17, columna 1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[0]}
set_location_assignment PIN_AB13 -to {TEC2_COL[1]}    ;# GPIO[15], header 18, columna 2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[1]}
set_location_assignment PIN_AB12 -to {TEC2_COL[2]}    ;# GPIO[16], header 19, columna 3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[2]}
set_location_assignment PIN_Y11 -to {TEC2_COL[3]}    ;# GPIO[17], header 20, columna 4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[3]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[2]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[3]}

# ---- Audio: PWM de 195.3 kHz hacia el filtro RC y el PAM8403 ----
set_location_assignment PIN_AA7 -to AUDIO_PWM    ;# GPIO[26], header 31
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_PWM
