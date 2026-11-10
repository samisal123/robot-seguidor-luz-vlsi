# TAREA-017
Estado: FALLO (el script no corre: Cyclone IV E no esta instalada). Se agrega una estimacion equivalente con MAX 10.
Fecha: 2026-11-09 20:40
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
$ git pull --rebase
Already up to date.
$ sh quartus/estimar_recursos.sh        # rc=3, 3 s
map.log:Error (20004): Your design targets the device family "Cyclone IV E". The specified family is not a valid device family, is not installed, or is not supported in this version of the Quartus Prime software. If you restored a project from an archived version, your project was successfully restored, but you still must specify or install a supported device family.
map.log:Error: Quartus Prime Analysis & Synthesis was unsuccessful. 1 error, 0 warnings
grep: fit.log: No such file or directory

==== Elementos logicos por modulo (Fitter Resource Utilization by Entity) ====
grep: output_files/estimacion.fit.rpt: No such file or directory
```

El Quartus Prime 25.1std.0 Lite de `~/altera_lite` solo tiene instalados los dispositivos MAX 10 (`quartus/common/devinfo/` contiene `55nm` y nada de Cyclone IV). El Fitter no llego a correr, asi que no hay `fit.log`.

### Estimacion extra con MAX 10 (no pedida, mismo elemento logico de 4 entradas)

Copia del script en el scratchpad, cambiando solo familia y dispositivo (`"MAX 10"`, `10M50DAF484C7G`) y la carpeta de trabajo; no se toco `quartus/`. Mismos fuentes (`rtl/*.vhd` + `sim/modelo_pll.vhd`, nivel superior `sinte_top`). rc=0, 1 min 31 s.

```
map.log:Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
fit.log:Info: Quartus Prime Fitter was successful. 0 errors, 4 warnings

Fitter Status : Successful - Mon Nov  9 20:39:54 2026
Quartus Prime Version : 25.1std.0 Build 1129 10/21/2025 SC Lite Edition
Revision Name : estimacion
Top-level Entity Name : sinte_top
Family : MAX 10
Device : 10M50DAF484C7G
Timing Models : Final
Total logic elements : 5,431 / 49,760 ( 11 % )
    Total combinational functions : 5,278 / 49,760 ( 11 % )
    Dedicated logic registers : 1,459 / 49,760 ( 3 % )
Total registers : 1459
Total pins : 30 / 360 ( 8 % )
Total virtual pins : 0
Total memory bits : 54,528 / 1,677,312 ( 3 % )
Embedded Multiplier 9-bit elements : 6 / 288 ( 2 % )
Total PLLs : 0 / 4 ( 0 % )
UFM blocks : 0 / 1 ( 0 % )
ADC blocks : 0 / 2 ( 0 % )
```

Elementos logicos por modulo (columnas: LE totales (propios); registros (propios); ...; memoria M9K en bits):

```
; |sinte_top                                   ; 5431 (1)    ; 1459 (0)                  ; 0 (0)         ; 545
;    |audio_salida:u_audio|                    ; 384 (22)    ; 212 (8)                   ; 0 (0)         ; 450
;       |eco:u_eco|                            ; 86 (86)     ; 53 (53)                   ; 0 (0)         ; 450
;       |metronomo:u_met|                      ; 99 (99)     ; 52 (52)                   ; 0 (0)         ; 0
;       |mezclador:u_mez|                      ; 37 (37)     ; 10 (10)                   ; 0 (0)         ; 0
;       |salida_pwm:u_pwm|                     ; 28 (28)     ; 17 (17)                   ; 0 (0)         ; 0
;       |tremolo:u_tre|                        ; 74 (74)     ; 63 (63)                   ; 0 (0)         ; 0
;       |volumen:u_vol|                        ; 38 (38)     ; 9 (9)                     ; 0 (0)         ; 0
;    |base_tiempo:u_tiempo|                    ; 36 (36)     ; 26 (26)                   ; 0 (0)         ; 0
;    |control:u_control|                       ; 97 (97)     ; 27 (27)                   ; 0 (0)         ; 0
;    |entradas_placa:u_placa|                  ; 44 (2)      ; 29 (2)                    ; 0 (0)         ; 0
;       |debounce:u_deb_accion|                ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0
;       |debounce:u_deb_metro|                 ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0
;       |debounce:u_deb_modo|                  ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0
;       |sync_2ff:u_sync|                      ; 6 (6)       ; 6 (6)                     ; 0 (0)         ; 0
;    |gestor_voces:u_gestor|                   ; 179 (179)   ; 24 (24)                   ; 0 (0)         ; 0
;    |interfaz_teclados:u_teclados|            ; 196 (0)     ; 146 (0)                   ; 0 (0)         ; 0
;       |sync_2ff:u_sync|                      ; 16 (16)     ; 16 (16)                   ; 0 (0)         ; 0
;       |teclado_scan:u_scan|                  ; 182 (182)   ; 130 (130)                 ; 0 (0)         ; 0
;    |leds_estado:u_leds|                      ; 15 (15)     ; 10 (10)                   ; 0 (0)         ; 0
;    |pll_25mhz:u_pll|                         ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0
;    |reset_encendido:u_rst|                   ; 11 (7)      ; 9 (5)                     ; 0 (0)         ; 0
;       |sync_2ff:u_sync|                      ; 4 (4)       ; 4 (4)                     ; 0 (0)         ; 0
;    |secuenciador:u_sec|                      ; 337 (337)   ; 160 (160)                 ; 0 (0)         ; 947
;       |memoria_eventos:u_mem|                ; 0 (0)       ; 0 (0)                     ; 0 (0)         ; 947
;    |selector_notas:u_sel|                    ; 21 (21)     ; 0 (0)                     ; 0 (0)         ; 0
;    |teclas_notas:u_notas|                    ; 128 (128)   ; 94 (94)                   ; 0 (0)         ; 0
;    |vga_ui:u_vga|                            ; 1912 (1912) ; 416 (416)                 ; 0 (0)         ; 0
;    |voz:u_voz0|                              ; 673 (173)   ; 99 (21)                   ; 0 (0)         ; 0
;       |adsr:u_adsr|                          ; 315 (315)   ; 29 (29)                   ; 0 (0)         ; 0
;       |dds:u_dds|                            ; 24 (24)     ; 24 (24)                   ; 0 (0)         ; 0
;       |forma_onda:u_onda|                    ; 161 (161)   ; 25 (25)                   ; 0 (0)         ; 0
;    |voz:u_voz1|                              ; 681 (173)   ; 99 (21)                   ; 0 (0)         ; 0
;       |adsr:u_adsr|                          ; 321 (321)   ; 29 (29)                   ; 0 (0)         ; 0
;       |dds:u_dds|                            ; 24 (24)     ; 24 (24)                   ; 0 (0)         ; 0
;       |forma_onda:u_onda|                    ; 163 (163)   ; 25 (25)                   ; 0 (0)         ; 0
;    |voz:u_voz2|                              ; 711 (173)   ; 101 (21)                  ; 0 (0)         ; 0
;       |adsr:u_adsr|                          ; 351 (348)   ; 29 (29)                   ; 0 (0)         ; 0
;       |dds:u_dds|                            ; 24 (24)     ; 24 (24)                   ; 0 (0)         ; 0
;       |forma_onda:u_onda|                    ; 163 (163)   ; 27 (27)                   ; 0 (0)         ; 0
```

Advertencias criticas del Fitter MAX 10 (esperadas en una estimacion sin pines ni SDC): `Critical Warning (169085): No exact pin location assignment(s) for 30 pins` y `Critical Warning (332012): Synopsys Design Constraints File file not found`.

## Notas

- **Riesgo: con esta estimacion el diseno NO cabe en la EP2C5.** 5 431 LE contra 4 608 disponibles (118 %, sobran ~823 LE). Es una estimacion (MAX 10, no Cyclone II), pero el elemento logico es el mismo de 4 entradas, asi que el orden de magnitud deberia mantenerse; hay que confirmarlo con TAREA-019.
- Los modulos mas grandes: `vga_ui` 1 912 LE (35 %), las tres `voz` ~2 065 LE en total (cada `adsr` ~320 LE), `secuenciador` 337, `audio_salida` 384.
- Multiplicadores: 6 de 9 bits (la EP2C5 tiene 26). Memoria: 54 528 bits en M9K; no es comparable con los M4K de la Cyclone II (la EP2C5 tiene 119 808 bits).
- El PLL aqui es el modelo de simulacion (divisor de 12 LE); en la tarjeta sera un PLL real y esos LE desaparecen.
- Logs: `logs/TAREA-017_map.log` (corrida pedida, falla). No existe `fit.log` de la corrida pedida. Logs de la estimacion MAX 10: `logs/TAREA-017_max10_map.log` y `logs/TAREA-017_max10_fit.log`.
- Para que el script corra tal cual haria falta instalar el soporte de Cyclone IV en Quartus 25.1; no se hizo porque TAREA-018 instala Quartus II 13.0 SP1, que compila la EP2C5 directamente.
