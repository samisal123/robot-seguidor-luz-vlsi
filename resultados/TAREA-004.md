# TAREA-004
Estado: EN CURSO
Fecha: 2026-10-22
Equipo: pc-bd-scm.n.fi.unam

Módulos de infraestructura (Semana 2). Por módulo: simulación del testbench con `sim/correr.sh <modulo>` y síntesis aislada con `quartus/sintetizar_modulo.sh <modulo> [dependencias]` (Quartus 25.1std.0 Lite, 10M50DAF484C7G). Las salidas de abajo son copia de los logs.

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
