# TAREA-025
Estado: OK (compila completo para la EP2C5T144C8 con el nivel superior sintetizador.bdf; hubo que corregir el PLL y liberar el pin 76, ver Notas)
Fecha: 2026-11-09 22:18
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

Paso 1: `git pull --rebase` (al dia, en `bee894b`).

Paso 2, `sh quartus/compilar.sh` (nivel superior `quartus/sintetizador.bdf`), cuatro corridas:

Corrida 1: `Fallo crear_proyecto.tcl`. Al correr `quartus_sh -t crear_proyecto.tcl` a mano termino bien (`Evaluation of Tcl script crear_proyecto.tcl was successful`); fue la primera ejecucion de la 13.0 SP1 en esta cuenta. No se volvio a repetir.

Corrida 2, falla el PLL (`quartus/ip/pll_25mhz.vhd`), log en `logs/TAREA-025_pll.log`:

```
Error (14157): PLL "pll" uses test-only parameter c0_test_source, but parameter must be used only in test mode File: .../altpll.tdf Line: 539
Error (14157): PLL "pll" uses test-only parameter c1_test_source, ...
Error (14157): PLL "pll" uses test-only parameter c2_test_source, ...
Error (14157): PLL "pll" uses test-only parameter m_test_source, ...
Error (14141): PLL "pll" has illegal or nonnumeric value 0 for inclk1_input_frequency parameter File: .../altpll.tdf Line: 539
Error (12152): Can't elaborate user hierarchy "pll_25mhz:u_pll|altpll:u_pll" File: .../quartus/ip/pll_25mhz.vhd Line: 38
Error: Quartus II 32-bit Analysis & Synthesis was unsuccessful. 6 errors, 1 warning
```

El MegaWizard no se pudo usar para regenerarlo: la interfaz no abre (TAREA-024) y en linea de comandos tambien falla:

```
$ qmegawiz -silent module=altpll ... pll_25mhz.vhd
/home/samuel/altera/13.0sp1/quartus/linux/mega_altpllq: error while loading shared libraries: libpng12.so.0: cannot open shared object file
```

Se reescribio `pll_25mhz.vhd` como lo escribe el MegaWizard (ver Notas).

Corrida 3, falla el Fitter por el pin 76:

```
Info: Quartus II 32-bit Analysis & Synthesis was successful. 0 errors, 1 warning
    Info (169125): Pin ~LVDS41p/nCEO~ is reserved at location 76
Error (176310): Can't place multiple pins assigned to pin location Pin_76 (IOC_X28_Y2_N0)
    Info (176311): Pin TEC2_COL[2] is assigned to pin location Pin_76 (IOC_X28_Y2_N0)
    Info (176311): Pin ~LVDS41p/nCEO~ is assigned to pin location Pin_76 (IOC_X28_Y2_N0)
Error (171000): Can't fit design in device
```

(En esa corrida Analysis & Synthesis ya daba 4 049 / 4 608 LE.) Se agrego `CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"` a `crear_proyecto.tcl`.

Corrida 4 (la buena, log completo en `logs/TAREA-025.log`, 42 s):

```
Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition
Info: Quartus II 32-bit Analysis & Synthesis was successful. 0 errors, 1 warning
Info (170137): Fitter placement was successful
Info: Quartus II 32-bit Fitter was successful. 0 errors, 4 warnings
Info: Quartus II 32-bit Assembler was successful. 0 errors, 0 warnings
Info: Quartus II 32-bit TimeQuest Timing Analyzer was successful. 0 errors, 2 warnings
Info (293000): Quartus II Full Compilation was successful. 0 errors, 7 warnings
```

Advertencias (todas; no hay Critical Warning):

```
Warning (20028): Parallel compilation is not licensed and has been disabled   (x3)
Warning (292013): Feature LogicLock is only available with a valid subscription license.
Warning (332153): Family doesn't support jitter analysis.                      (x2)
Warning (306006): Found 17 output pins without output pin load capacitance assignment
```

`output_files/sintetizador.fit.summary`:

```
Fitter Status : Successful - Mon Nov  9 22:15:18 2026
Quartus II 32-bit Version : 13.0.1 Build 232 06/12/2013 SP 1 SJ Web Edition
Revision Name : sintetizador
Top-level Entity Name : sintetizador
Family : Cyclone II
Device : EP2C5T144C8
Timing Models : Final
Total logic elements : 3,782 / 4,608 ( 82 % )
    Total combinational functions : 3,631 / 4,608 ( 79 % )
    Dedicated logic registers : 1,403 / 4,608 ( 30 % )
Total registers : 1403
Total pins : 30 / 89 ( 34 % )
Total virtual pins : 0
Total memory bits : 76,032 / 119,808 ( 63 % )
Embedded Multiplier 9-bit elements : 6 / 26 ( 23 % )
Total PLLs : 1 / 2 ( 50 % )
```

Fitter Resource Utilization by Entity (elementos logicos, registros y bits de memoria; entre parentesis lo propio del modulo sin sus hijos):

```
Modulo                              LE            Registros    Memoria (bits)
|sintetizador                       3782 (1)      1403 (0)     76032
   audio_salida:u_audio              383 (22)      212 (8)      45056
      eco:u_eco                         86 (86)       53 (53)      45056
      metronomo:u_met                   98 (98)       52 (52)      0
      mezclador:u_mez                   37 (37)       10 (10)      0
      salida_pwm:u_pwm                  28 (28)       17 (17)      0
      tremolo:u_tre                     73 (73)       63 (63)      0
      volumen:u_vol                     39 (39)       9 (9)        0
   base_tiempo:u_tiempo              35 (35)       26 (26)      0
   control:u_control                 100 (100)     27 (27)      0
   entradas_placa:u_placa            38 (2)        29 (2)       0
      debounce (x3)                     11 c/u        7 c/u        0
      sync_2ff:u_sync                   6 (6)         6 (6)        0
   gestor_voces:u_gestor             209 (209)     24 (24)      0
   interfaz_teclados:u_teclados      187 (0)       146 (0)      0
      sync_2ff:u_sync                   16 (16)       16 (16)      0
      teclado_scan:u_scan               179 (179)     130 (130)    0
   leds_estado:u_leds                15 (15)       10 (10)      0
   pll_25mhz:u_pll                   0 (0)         0 (0)        0
   reset_encendido:u_rst             10 (6)        9 (5)        0
   secuenciador:u_sec                354 (354)     160 (160)    9472
      memoria_eventos:u_mem             0 (0)         0 (0)        9472
   selector_notas:u_sel              21 (21)       0 (0)        0
   teclas_notas:u_notas              125 (125)     94 (94)      0
   vga_ui:u_vga                      1523 (1523)   454 (454)    6144
   voz:u_voz0                        265 (0)       70 (0)       5120
      adsr:u_adsr                       210 (210)     29 (29)      0
      dds:u_dds                         24 (24)       24 (24)      0
      forma_onda:u_onda                 31 (31)       17 (17)      2048
   voz:u_voz1                        267 (0)       70 (0)       5120   (adsr 210, dds 24, forma_onda 33)
   voz:u_voz2                        271 (0)       72 (0)       5120   (adsr 215, dds 24, forma_onda 32)
```

Fmax y slack del reloj de 25 MHz del PLL (`output_files/sintetizador.sta.rpt`; periodo 40 ns, derivado con `derive_pll_clocks` de `clk50`):

```
; Slow Model Fmax Summary
; 36.05 MHz ; 36.05 MHz       ; u_pll|u_pll|pll|clk[0] ;

Slow Model Setup 'u_pll|u_pll|pll|clk[0]'   Slack : 12.261   TNS : 0.000
Slow Model Hold  'u_pll|u_pll|pll|clk[0]'   Slack :  0.499   TNS : 0.000
Fast Model Setup 'u_pll|u_pll|pll|clk[0]'   Slack : 31.609   TNS : 0.000
Fast Model Hold  'u_pll|u_pll|pll|clk[0]'   Slack :  0.215   TNS : 0.000
Slow Model Minimum Pulse Width 'clk50'      Slack : 10.000
```

Archivos generados: `output_files/sintetizador.sof` (151 396 B) y `sintetizador.pof` (524 508 B).

Paso 6:

```
$ ~/altera/13.0sp1/quartus/bin/quartus_pgm -l
No JTAG hardware available
```

La tarjeta no esta conectada; no se programo nada.

## Notas

- **Cabe y cumple tiempos:** 3 782 LE (82 %), 63 % de la memoria, 6 de 26 multiplicadores, 1 PLL. El reloj de 25 MHz tiene 12.3 ns de margen (Fmax 36 MHz) y no hay violaciones de hold. El modulo mas grande es `vga_ui` (1 523 LE, 40 % del diseno).
- **Cambio 1, `quartus/ip/pll_25mhz.vhd`** (la TAREA-019 pide regenerar el PLL si falla). La causa: el archivo usaba la declaracion de `altpll` de `altera_mf.altera_mf_components`, asi que VHDL le pasaba todos los genericos con sus valores por omision (`c0_test_source := 5`, `inclk1_input_frequency := 0`, ...), y `altpll.tdf` los toma como "usados" (`USED(C0_TEST_SOURCE)`). El MegaWizard declara el componente dentro del archivo con solo los genericos que usa; se hizo igual: misma entidad (`inclk0`, `c0`, `locked`), mismos valores (entrada de 20 000 ps, c0 = 1/2, ciclo 50 %), y todos los demas puertos `PORT_UNUSED`. Como el MegaWizard no corre (falta `libpng12`), no se genero el `.qip`/`.cmp`; no hacen falta para compilar. La simulacion no cambia (usa `sim/modelo_pll.vhd`).
- **Cambio 2, `quartus/crear_proyecto.tcl`:** `pines.tcl` pone `TEC2_COL[2]` en el pin 76, que en la Cyclone II es nCEO (doble proposito) y Quartus lo reserva por omision. Se agrego `set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"`: con un solo FPGA en la tarjeta nCEO no se usa, y asi el pin queda como E/S normal. No cambia ningun pin ni el cableado.
- No hizo falta la corrida con `sinte_top`: el `.bdf` compilo bien.
- La advertencia 306006 (17 salidas sin capacitancia de carga) solo afecta el analisis de tiempos de salida, que de todos modos tiene `set_false_path` en el `.sdc`.
- Las advertencias de licencia (compilacion paralela, LogicLock) son normales en la Web Edition.
- Para las capturas de la TAREA-020 hace falta la interfaz grafica, que todavia no abre por `libpng12.so.0` (ver `resultados/TAREA-024.md`).
