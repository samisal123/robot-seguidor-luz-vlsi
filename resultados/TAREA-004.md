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
