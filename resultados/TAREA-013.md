# TAREA-013
Estado: OK
Fecha: 2026-11-07 11:19
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
sh quartus/compilar.sh          # nivel superior: sintetizador.bdf
```

Etapas (Quartus Prime 25.1std.0 Build 1129, SC Lite Edition, dispositivo 10M50DAF484C7G, MAX 10):

| Etapa | Estado | Errores | Advertencias |
|---|---|---|---|
| Analysis & Synthesis | successful | 0 | 17 |
| Fitter | successful | 0 | 3 |
| Assembler | successful | 0 | 0 |
| Timing Analyzer | successful | 0 | 0 |
| Full Compilation | successful | 0 | 20 |

No fue necesario correr la variante `sinte_top`, porque el `.bdf` compiló sin errores.

Advertencias (tal como salen en el log):

```
Warning (13024): Output pins are stuck at VCC or GND
    Warning (13410): Pin "HEX0[7]" is stuck at VCC
    Warning (13410): Pin "HEX2[7]" is stuck at VCC
    Warning (13410): Pin "HEX3[7]" is stuck at VCC
    Warning (13410): Pin "HEX4[7]" is stuck at VCC
    Warning (13410): Pin "HEX4[3]" is stuck at VCC
    Warning (13410): Pin "HEX5[7]" is stuck at VCC
    Warning (13410): Pin "HEX5[1]" is stuck at VCC
Warning (21074): Design contains 8 input pin(s) that do not drive logic
    Warning (15610): No output dependent on input pin "SW[7]"
    ... (SW[6] a SW[0], uno por línea, mismo mensaje)
Warning (292013): Feature LogicLock is only available with a valid subscription license. ...
Warning (15714): Some pins have incomplete I/O assignments. Refer to the I/O Assignment Warnings report for details
Warning (169177): 21 pins must meet Intel FPGA requirements for 3.3-, 3.0-, and 2.5-V interfaces. ...
```

Las primeras 17 advertencias (líneas 338 a 360 del log) pertenecen a Analysis & Synthesis; las tres últimas (líneas 385, 413 y 448), al Fitter.

Resumen de recursos (`quartus/output_files/sintetizador.fit.summary`, completo):

```
Fitter Status : Successful - Sat Nov  7 11:18:06 2026
Quartus Prime Version : 25.1std.0 Build 1129 10/21/2025 SC Lite Edition
Revision Name : sintetizador
Top-level Entity Name : sintetizador
Family : MAX 10
Device : 10M50DAF484C7G
Timing Models : Final
Total logic elements : 6,464 / 49,760 ( 13 % )
    Total combinational functions : 6,295 / 49,760 ( 13 % )
    Dedicated logic registers : 1,460 / 49,760 ( 3 % )
Total registers : 1460
Total pins : 102 / 360 ( 28 % )
Total virtual pins : 0
Total memory bits : 99,584 / 1,677,312 ( 6 % )
Embedded Multiplier 9-bit elements : 6 / 288 ( 2 % )
Total PLLs : 0 / 4 ( 0 % )
UFM blocks : 0 / 1 ( 0 % )
ADC blocks : 0 / 2 ( 0 % )
```

Fmax y holgura del reloj `clk50` (20.000 ns, 50 MHz; `quartus/output_files/sintetizador.sta.rpt`):

| Modelo | Fmax | Setup slack | Hold slack | Min. pulse width slack |
|---|---|---|---|---|
| Slow 1200mV 85C | 51.71 MHz | 0.663 ns | 0.225 ns | 9.405 ns |
| Slow 1200mV 0C | 56.84 MHz | 2.408 ns | 0.233 ns | 9.423 ns |
| Fast 1200mV 0C | — | 12.236 ns | 0.086 ns | 9.263 ns |

Todas las holguras de setup y hold son positivas; TNS = 0.000 en todos los modelos. Recovery y removal: sin rutas que reportar.

Programación de la tarjeta: `quartus_pgm -l` responde `No JTAG hardware available`. La tarjeta no está conectada y **no** se programó.

Log completo: `logs/TAREA-013.log` (copia de `logs/compilacion.log`).

## Notas

- Compilación con `sh quartus/compilar.sh` sin argumentos (nivel superior `sintetizador.bdf`). Quartus se encontró en `~/altera_lite/25.1std/quartus/bin` mediante la búsqueda del script; no estaba en el PATH.
- `quartus/output_files/` aún contiene archivos `robot.*` (`robot.sof`, `robot.pof`, `robot.sta.rpt`, etc.) de la compilación del proyecto anterior. Están en `.gitignore` y no se tocaron.
- La advertencia de LogicLock dice que esa función requiere suscripción; no es un error de compilación.
- Pines que el log reporta sin uso o fijos: segmentos HEX fijos en VCC (`HEX0[7]`, `HEX2[7]`, `HEX3[7]`, `HEX4[7]`, `HEX4[3]`, `HEX5[7]`, `HEX5[1]`) y entradas `SW[7..0]` sin lógica conectada. No se revisó si es intencional.
