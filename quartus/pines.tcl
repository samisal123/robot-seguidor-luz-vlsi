# ============================================================
# pines.tcl
# Asignacion de pines del sintetizador en la tarjeta minima
# EP2C5T144 (Cyclone II EP2C5T144C8). Reloj, LEDs y boton RESET
# son los de la tarjeta; lo demas va a sus conectores (todos los
# pines de E/S son de 3.3 V y no toleran 5 V). El numero de cada
# pin esta impreso junto al conector de la tarjeta.
# Pines que NO se usan: 26 y 81 (unidos a 1.2 V) y 27 y 80
# (unidos a GND) por resistencias de 0 ohm para la EP2C8, y 73
# (red RC de reset). crear_proyecto.tcl deja todos los pines sin
# uso como entradas en alta impedancia.
# Ver docs/CABLEADO.md. Lo carga crear_proyecto.tcl.
# Los nombres con corchetes van entre llaves para que Tcl no los
# interprete como sustitucion de comandos.
# ============================================================

# ---- Reloj de 50 MHz del oscilador de la tarjeta ----
set_location_assignment PIN_17 -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

# ---- Boton RESET de la tarjeta (activo en bajo, sin resistencia externa) ----
set_location_assignment PIN_144 -to BTN_RESET
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_RESET
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_RESET

# ---- LEDs D2, D4 y D5 de la tarjeta (se encienden con 0) ----
set_location_assignment PIN_3 -to {LED[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[0]}
set_location_assignment PIN_7 -to {LED[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[1]}
set_location_assignment PIN_9 -to {LED[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[2]}

# ---- Teclado 1, pines 1-4 del conector: filas (colector abierto) ----
set_location_assignment PIN_25 -to {TEC1_FIL[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[0]}
set_location_assignment PIN_31 -to {TEC1_FIL[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[1]}
set_location_assignment PIN_41 -to {TEC1_FIL[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[2]}
set_location_assignment PIN_40 -to {TEC1_FIL[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_FIL[3]}

# ---- Teclado 1, pines 5-8 del conector: columnas (pull-up interno) ----
set_location_assignment PIN_43 -to {TEC1_COL[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[0]}
set_location_assignment PIN_42 -to {TEC1_COL[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[1]}
set_location_assignment PIN_45 -to {TEC1_COL[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[2]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[2]}
set_location_assignment PIN_44 -to {TEC1_COL[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC1_COL[3]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC1_COL[3]}

# ---- Teclado 2, pines 1-4 del conector: filas (colector abierto) ----
set_location_assignment PIN_48 -to {TEC2_FIL[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[0]}
set_location_assignment PIN_47 -to {TEC2_FIL[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[1]}
set_location_assignment PIN_52 -to {TEC2_FIL[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[2]}
set_location_assignment PIN_51 -to {TEC2_FIL[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_FIL[3]}

# ---- Teclado 2, pines 5-8 del conector: columnas (pull-up interno) ----
set_location_assignment PIN_58 -to {TEC2_COL[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[0]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[0]}
set_location_assignment PIN_55 -to {TEC2_COL[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[1]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[1]}
set_location_assignment PIN_76 -to {TEC2_COL[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[2]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[2]}
set_location_assignment PIN_60 -to {TEC2_COL[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {TEC2_COL[3]}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to {TEC2_COL[3]}

# ---- Audio: PWM al filtro RC ----
set_location_assignment PIN_93 -to AUDIO_PWM
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_PWM
