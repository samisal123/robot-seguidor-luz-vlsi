# TAREA-003
Estado: OK
Fecha: 2026-10-22 21:12
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

Log completo (267 líneas): `logs/TAREA-003.log`.

```
$ export PATH=~/altera_lite/25.1std/quartus/bin:$PATH
$ cd quartus
$ quartus_sh -t crear_proyecto.tcl
Info (23030): Evaluation of Tcl script crear_proyecto.tcl was successful
$ quartus_sh --flow compile robot
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 11 warnings
Info: Quartus Prime Fitter was successful. 0 errors, 3 warnings
Info: Quartus Prime Assembler was successful. 0 errors, 0 warnings
Info: Quartus Prime Timing Analyzer was successful. 0 errors, 0 warnings
Info (293000): Quartus Prime Full Compilation was successful. 0 errors, 14 warnings
```

Warnings (14 en total):

```
Warning (13024): Output pins are stuck at VCC or GND
Warning (13410): Pin "LEDR[2]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[3]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[4]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[5]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[6]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[7]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[8]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (13410): Pin "LEDR[9]" is stuck at GND (rtl/robot_top.vhd:18)
Warning (21074): Design contains 1 input pin(s) that do not drive logic
Warning (15610): No output dependent on input pin "KEY[1]" (rtl/robot_top.vhd:17)
Warning (292013): Feature LogicLock is only available with a valid subscription license. You can purchase a software subscription to gain full access to this feature.
Warning (15714): Some pins have incomplete I/O assignments. Refer to the I/O Assignment Warnings report for details
Critical Warning (169085): No exact pin location assignment(s) for 13 pins of 13 total pins. For the list of pins please refer to the I/O Assignment Warnings table in the fitter report.
```

`quartus/output_files/robot.fit.summary`:

```
Fitter Status : Successful - Thu Oct 22 21:12:19 2026
Quartus Prime Version : 25.1std.0 Build 1129 10/21/2025 SC Lite Edition
Revision Name : robot
Top-level Entity Name : robot_top
Family : MAX 10
Device : 10M50DAF484C7G
Timing Models : Final
Total logic elements : 47 / 49,760 ( < 1 % )
    Total combinational functions : 47 / 49,760 ( < 1 % )
    Dedicated logic registers : 26 / 49,760 ( < 1 % )
Total registers : 26
Total pins : 13 / 360 ( 4 % )
Total virtual pins : 0
Total memory bits : 0 / 1,677,312 ( 0 % )
Embedded Multiplier 9-bit elements : 0 / 288 ( 0 % )
Total PLLs : 0 / 4 ( 0 % )
UFM blocks : 0 / 1 ( 0 % )
ADC blocks : 0 / 2 ( 0 % )
```

Tiempo (`robot.sta.rpt` / `robot.sta.summary`), modelo Slow 1200mV 85C:

```
Fmax clk50       : 222.42 MHz
Setup slack clk50: 15.504 ns (TNS 0.000)
Hold slack clk50 : 0.340 ns (TNS 0.000)
```

## Notas

- La compilación completa termina sin errores y genera `output_files/robot.sof` y `robot.pof`. No se programó la tarjeta (además, no hay USB-Blaster conectado, ver TAREA-002).
- Los warnings son esperados para el smoke test: KEY1 sin uso, LEDR9..2 fijos en 0, pines sin asignación (todavía no existe `quartus/pines.tcl`; el Critical Warning 169085 desaparece al agregarlo) y LogicLock (licencia Lite).
- 13 pines = 1 reloj + 2 KEY + 10 LEDR, ubicados automáticamente por el fitter.
