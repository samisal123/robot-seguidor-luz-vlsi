# TAREA-004
Estado: OK
Fecha: 2026-10-22 22:10
Equipo: pc-bd-scm.n.fi.unam

Módulos de infraestructura (Semana 2). Por módulo: simulación del testbench con `sim/correr.sh <modulo>` y síntesis aislada con `quartus/sintetizar_modulo.sh <modulo> [dependencias]` (Quartus 25.1std.0 Lite, 10M50DAF484C7G). Las salidas de abajo son copia de los logs.


## Resumen

| Módulo | Testbench | Síntesis | LE | Registros | Warnings |
|---|---|---|---|---|---|
| `tick_gen` | PASA | OK | 33 | 25 | 0 |
| `sync_2ff` | PASA | OK | 2 | 2 | 0 |
| `debounce` | PASA | OK | 14 | 8 | 0 |
| `pwm_8b` | PASA | OK | 34 | 21 | 0 |
| `motor_if` | PASA | OK | 19 | 11 | 0 |
| `hcsr04` | PASA | OK | 83 | 46 | 0 |
| `seg7_disp` | PASA | OK | 202 | 43 | 5 (puntos decimales fijos, esperado) |

Regresión final (`sim/correr.sh`, log en `logs/sim_todos.log`):

```
sim/tb_debounce.vhd:128:9:@269011750ns:(report note): tb_debounce: OK
== tb_debounce: PASA
sim/tb_hcsr04.vhd:174:9:@151346030ns:(report note): tb_hcsr04: OK
== tb_hcsr04: PASA
sim/tb_motor_if.vhd:134:9:@132012750ns:(report note): tb_motor_if: OK
== tb_motor_if: PASA
sim/tb_pwm_8b.vhd:103:9:@1177790ns:(report note): tb_pwm_8b: OK
== tb_pwm_8b: PASA
sim/tb_robot_top.vhd:50:9:@190ns:(report note): tb_robot_top: OK
== tb_robot_top: PASA
sim/tb_seg7_disp.vhd:165:9:@31351ns:(report note): tb_seg7_disp: OK
== tb_seg7_disp: PASA
sim/tb_sync_2ff.vhd:60:9:@711ns:(report note): tb_sync_2ff: OK
== tb_sync_2ff: PASA
sim/tb_tick_gen.vhd:87:9:@4009070ns:(report note): tb_tick_gen: OK
== tb_tick_gen: PASA
```

Compilación completa del proyecto con los módulos nuevos en `rtl/` (el top sigue siendo el smoke test, así que los módulos se analizan pero no se instancian). Log: `logs/compilacion_semana2.log`.

```
Info: Quartus Prime Shell was successful. 0 errors, 0 warnings
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 11 warnings
Info: Quartus Prime Fitter was successful. 0 errors, 3 warnings
Info: Quartus Prime Assembler was successful. 0 errors, 0 warnings
Info: Quartus Prime Timing Analyzer was successful. 0 errors, 0 warnings
Info (293000): Quartus Prime Full Compilation was successful. 0 errors, 14 warnings
Info: Quartus Prime Shell was successful. 0 errors, 14 warnings
```

### Cómo se validaron los testbenches

Después de que cada testbench pasó, se corrió contra copias del módulo con un error metido a propósito (mutaciones, en el scratchpad, sin commit) para confirmar que el testbench lo detecta. Todas las mutaciones de abajo hicieron FALLAR el testbench, excepto las marcadas:

- `tick_gen`: contar hasta 56 en vez de 57 → falla el periodo de tick_58us.
- `sync_2ff`: un solo flip-flop → q cambia en el primer flanco.
- `debounce`: que un rebote no reinicie la cuenta → falla; aceptar a los 18 ticks → falla la ventana de 19 a 20 ms; `fall` invertido → falla.
- `pwm_8b`: `<=` en vez de `<` → duty 0 da 10 ciclos; capturar duty en cualquier momento → se corta el pulso en curso; prescaler de 9 → falla el ancho.
- `motor_if`: sin pausa en las salidas → falla; pausa de 16 ms → falla la ventana; EN = pwm or dir → falla.
- `hcsr04`: sin redondeo → 620 µs da 10 cm; start sin condición → falla; TRIG de 9.98 µs → falla; sin detección de flanco del eco → la primera versión del testbench **no lo detectó**; se agregó el caso de ECHO pegado que baja a los 5 ms y ahora sí falla.
- `seg7_disp`: patrón del 7 mal → falla; error en el double dabble → 100 se lee " -0"; blanco de decenas mal → 100 se lee "1 0"; sin punto en HEX3 → falla.

### Problemas encontrados en el camino

- `seg7_disp`: la primera versión tenía `p := resize(unsigned(d), 15) * to_unsigned(100, 7)`, que da 22 bits y no cabe en 15. GHDL lo detectó como `bound check failure`. Se corrigió a `unsigned(d) * to_unsigned(100, 7)` (8 + 7 = 15 bits).
- Testbenches: tres errores del propio testbench, corregidos antes del commit: chequeo a t = 0 antes de la primera delta (`tb_sync_2ff`), `t0` tomado 2 ms tarde (`tb_debounce`) y una espera a `busy = '0'` que ya había ocurrido y colgaba la simulación (`tb_hcsr04`). Por ese cuelgue, `sim/correr.sh` ahora usa `--stop-time=2sec` y exige el `report "tb_<modulo>: OK"` final.

### Entorno

GHDL 4.1.0 (backend mcode) no estaba instalado y no hay sudo sin contraseña, así que se extrajeron los paquetes `ghdl-mcode` y `ghdl-common` de apt (`apt-get download` + `dpkg -x`) en `~/.local/opt/ghdl-deb/` con un wrapper en `~/.local/bin/ghdl`. No hay Questa/ModelSim en la instalación de Quartus.

## tick_gen

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_tick_gen.log`

```
sim/tb_tick_gen.vhd:87:9:@4009070ns:(report note): tb_tick_gen: OK
== tb_tick_gen: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_tick_gen.log`

```
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
Total logic elements : 33
Dedicated logic registers : 25
Total pins : 5
Embedded Multiplier 9-bit elements : 0
```

## sync_2ff

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_sync_2ff.log`

```
sim/tb_sync_2ff.vhd:60:9:@711ns:(report note): tb_sync_2ff: OK
== tb_sync_2ff: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_sync_2ff.log`

```
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
Total logic elements : 2
Dedicated logic registers : 2
Total pins : 3
Embedded Multiplier 9-bit elements : 0
```

## debounce

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_debounce.log`

```
sim/tb_debounce.vhd:128:9:@269011750ns:(report note): tb_debounce: OK
== tb_debounce: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_debounce.log`

```
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
Total logic elements : 14
Dedicated logic registers : 8
Total pins : 7
Embedded Multiplier 9-bit elements : 0
```

## pwm_8b

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_pwm_8b.log`

```
sim/tb_pwm_8b.vhd:103:9:@1177790ns:(report note): tb_pwm_8b: OK
== tb_pwm_8b: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_pwm_8b.log`

```
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
Total logic elements : 34
Dedicated logic registers : 21
Total pins : 11
Embedded Multiplier 9-bit elements : 0
```

## motor_if

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_motor_if.log`

```
sim/tb_motor_if.vhd:134:9:@132012750ns:(report note): tb_motor_if: OK
== tb_motor_if: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_motor_if.log`

```
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
Total logic elements : 19
Dedicated logic registers : 11
Total pins : 8
Embedded Multiplier 9-bit elements : 0
```

## hcsr04

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_hcsr04.log`

```
sim/tb_hcsr04.vhd:174:9:@151346030ns:(report note): tb_hcsr04: OK
== tb_hcsr04: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_hcsr04.log`

```
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
Total logic elements : 83
Dedicated logic registers : 46
Total pins : 18
Embedded Multiplier 9-bit elements : 0
```

## seg7_disp

Simulación (GHDL 4.1.0): PASA. Log: `logs/sim_seg7_disp.log`

```
sim/tb_seg7_disp.vhd:165:9:@31351ns:(report note): tb_seg7_disp: OK
== tb_seg7_disp: PASA
```

Síntesis (quartus_map, módulo como top): OK. Log: `logs/map_seg7_disp.log`

```
Warning (13024): Output pins are stuck at VCC or GND
Warning (13410): Pin "hex0[7]" is stuck at VCC File: /home/samuel/proyectos/robot-seguidor-luz-vlsi/rtl/seg7_disp.vhd Line: 99
Warning (13410): Pin "hex1[7]" is stuck at VCC File: /home/samuel/proyectos/robot-seguidor-luz-vlsi/rtl/seg7_disp.vhd Line: 99
Warning (13410): Pin "hex2[7]" is stuck at VCC File: /home/samuel/proyectos/robot-seguidor-luz-vlsi/rtl/seg7_disp.vhd Line: 99
Warning (13410): Pin "hex4[7]" is stuck at VCC File: /home/samuel/proyectos/robot-seguidor-luz-vlsi/rtl/seg7_disp.vhd Line: 99
Warning (13410): Pin "hex5[7]" is stuck at VCC File: /home/samuel/proyectos/robot-seguidor-luz-vlsi/rtl/seg7_disp.vhd Line: 99
Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 6 warnings
Total logic elements : 202
Dedicated logic registers : 43
Total pins : 83
Embedded Multiplier 9-bit elements : 0
```

Los 5 warnings 13410 son los puntos decimales de HEX0, HEX1, HEX2, HEX4 y HEX5, fijos en apagado por diseño (solo HEX3 usa el punto, en modo distancia).
