# TAREA-021
Estado: OK
Fecha: 2026-11-09 21:40
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
$ git pull --rebase
Already up to date.
$ sh quartus/estimar_recursos.sh        # 45 s, rc=0
map.log:Info: Quartus Prime Analysis & Synthesis was successful. 0 errors, 0 warnings
fit.log:Info (170137): Fitter placement was successful
fit.log:Info: Quartus Prime Fitter was successful. 0 errors, 4 warnings

==== Tablas que no fueron a memoria (deberia no salir ninguna) ====
==== Memorias inferidas ====
"vga_ui:u_vga|rom_fuente_rtl_0" 
"secuenciador:u_sec|memoria_eventos:u_mem|ram_rtl_0" 
"vga_ui:u_vga|rom_onda_rtl_0" 
"audio_salida:u_audio|eco:u_eco|ram_rtl_0" 
"voz:u_voz1|forma_onda:u_onda|rom_rtl_0" 
"voz:u_voz0|forma_onda:u_onda|rom_rtl_0" 
"voz:u_voz2|forma_onda:u_onda|rom_rtl_0" 
"voz:u_voz1|rom_rtl_0" 
"voz:u_voz0|rom_rtl_0" 
"voz:u_voz2|rom_rtl_0" 

Fitter Status : Successful - Mon Nov  9 21:40:33 2026
Quartus Prime Version : 25.1std.0 Build 1129 10/21/2025 SC Lite Edition
Revision Name : estimacion
Top-level Entity Name : sinte_top
Family : MAX 10
Device : 10M50DAF484C7G
Timing Models : Final
Total logic elements : 3,805 / 49,760 ( 8 % )
    Total combinational functions : 3,610 / 49,760 ( 7 % )
    Dedicated logic registers : 1,410 / 49,760 ( 3 % )
Total registers : 1410
Total pins : 30 / 360 ( 8 % )
Total virtual pins : 0
Total memory bits : 76,032 / 1,677,312 ( 5 % )
Embedded Multiplier 9-bit elements : 6 / 288 ( 2 % )
Total PLLs : 0 / 4 ( 0 % )
UFM blocks : 0 / 1 ( 0 % )
ADC blocks : 0 / 2 ( 0 % )

==== Elementos logicos por modulo (Fitter Resource Utilization by Entity) ====
; |sinte_top                                   ; 3805 (1)    ; 1410 (0)                  ; 0 (0)         ; 760
;    |audio_salida:u_audio|                    ; 376 (22)    ; 212 (8)                   ; 0 (0)         ; 450
;       |eco:u_eco|                            ; 92 (92)     ; 53 (53)                   ; 0 (0)         ; 450
;       |metronomo:u_met|                      ; 98 (98)     ; 52 (52)                   ; 0 (0)         ; 0  
;       |mezclador:u_mez|                      ; 37 (37)     ; 10 (10)                   ; 0 (0)         ; 0  
;       |salida_pwm:u_pwm|                     ; 28 (28)     ; 17 (17)                   ; 0 (0)         ; 0  
;       |tremolo:u_tre|                        ; 74 (74)     ; 63 (63)                   ; 0 (0)         ; 0  
;       |volumen:u_vol|                        ; 38 (38)     ; 9 (9)                     ; 0 (0)         ; 0  
;    |base_tiempo:u_tiempo|                    ; 36 (36)     ; 26 (26)                   ; 0 (0)         ; 0  
;    |control:u_control|                       ; 95 (95)     ; 27 (27)                   ; 0 (0)         ; 0  
;    |entradas_placa:u_placa|                  ; 44 (2)      ; 29 (2)                    ; 0 (0)         ; 0  
;       |debounce:u_deb_accion|                ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0  
;       |debounce:u_deb_metro|                 ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0  
;       |debounce:u_deb_modo|                  ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0  
;       |sync_2ff:u_sync|                      ; 6 (6)       ; 6 (6)                     ; 0 (0)         ; 0  
;    |gestor_voces:u_gestor|                   ; 172 (172)   ; 24 (24)                   ; 0 (0)         ; 0  
;    |interfaz_teclados:u_teclados|            ; 201 (0)     ; 146 (0)                   ; 0 (0)         ; 0  
;       |sync_2ff:u_sync|                      ; 16 (16)     ; 16 (16)                   ; 0 (0)         ; 0  
;       |teclado_scan:u_scan|                  ; 187 (187)   ; 130 (130)                 ; 0 (0)         ; 0  
;    |leds_estado:u_leds|                      ; 15 (15)     ; 10 (10)                   ; 0 (0)         ; 0  
;    |pll_25mhz:u_pll|                         ; 12 (12)     ; 7 (7)                     ; 0 (0)         ; 0  
;    |reset_encendido:u_rst|                   ; 11 (7)      ; 9 (5)                     ; 0 (0)         ; 0  
;       |sync_2ff:u_sync|                      ; 4 (4)       ; 4 (4)                     ; 0 (0)         ; 0  
;    |secuenciador:u_sec|                      ; 341 (341)   ; 160 (160)                 ; 0 (0)         ; 947
;       |memoria_eventos:u_mem|                ; 0 (0)       ; 0 (0)                     ; 0 (0)         ; 947
;    |selector_notas:u_sel|                    ; 21 (21)     ; 0 (0)                     ; 0 (0)         ; 0  
;    |teclas_notas:u_notas|                    ; 130 (130)   ; 94 (94)                   ; 0 (0)         ; 0  
;    |vga_ui:u_vga|                            ; 1546 (1546) ; 454 (454)                 ; 0 (0)         ; 614
;    |voz:u_voz0|                              ; 272 (0)     ; 70 (0)                    ; 0 (0)         ; 512
;       |adsr:u_adsr|                          ; 210 (210)   ; 29 (29)                   ; 0 (0)         ; 0  
;       |dds:u_dds|                            ; 24 (24)     ; 24 (24)                   ; 0 (0)         ; 0  
;       |forma_onda:u_onda|                    ; 38 (38)     ; 17 (17)                   ; 0 (0)         ; 204
;    |voz:u_voz1|                              ; 272 (0)     ; 70 (0)                    ; 0 (0)         ; 512
;       |adsr:u_adsr|                          ; 211 (211)   ; 29 (29)                   ; 0 (0)         ; 0  
;       |dds:u_dds|                            ; 24 (24)     ; 24 (24)                   ; 0 (0)         ; 0  
;       |forma_onda:u_onda|                    ; 37 (37)     ; 17 (17)                   ; 0 (0)         ; 204
;    |voz:u_voz2|                              ; 277 (0)     ; 72 (0)                    ; 0 (0)         ; 512
;       |adsr:u_adsr|                          ; 216 (216)   ; 29 (29)                   ; 0 (0)         ; 0  
;       |dds:u_dds|                            ; 24 (24)     ; 24 (24)                   ; 0 (0)         ; 0  
;       |forma_onda:u_onda|                    ; 37 (37)     ; 19 (19)                   ; 0 (0)         ; 204
```

Advertencias del Fitter (las 4 de `fit.log`, ninguna en Analysis & Synthesis):

```
Warning (292013): Feature LogicLock is only available with a valid subscription license. You can purchase a software subscription to gain full access to this feature.
Warning (15714): Some pins have incomplete I/O assignments. Refer to the I/O Assignment Warnings report for details
Critical Warning (169085): No exact pin location assignment(s) for 30 pins of 30 total pins. For the list of pins please refer to the I/O Assignment Warnings table in the fitter report.
Critical Warning (332012): Synopsys Design Constraints File file not found: 'estimacion.sdc'. A Synopsys Design Constraints File is required by the Timing Analyzer to get proper timing constraints. Without it, the Compiler will not properly optimize the design.
```

## Notas

- Analysis & Synthesis acepto `INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE WITH ERAM"` a la primera, asi que solo hubo una corrida (no hizo falta quitar esa linea del `crear.tcl`).
- Ya no sale ninguna tabla "uninferred": las 10 tablas se infirieron como `altsyncram` (ROM de fuente y de onda de la VGA, memoria de eventos del secuenciador, RAM del eco, las 3 ROM de `forma_onda` y las 3 ROM de cada `voz`).
- Resultado: **3 805 elementos logicos** (antes 5 431 en la TAREA-017), por debajo de los 4 608 LE de la EP2C5 (~83 %). Registros: 1 410. `vga_ui` bajo de 1 912 a 1 546 LE.
- Otros recursos frente a la EP2C5T144: 30 pines (la EP2C5T144 tiene 89 de E/S), 6 multiplicadores de 9 bits (tiene 26), 76 032 bits de memoria en M9K (tiene 119 808 bits en 26 M4K). Los bits no se comparan directo (la cuenta de bloques M4K puede ser otra); eso lo dira la TAREA-023.
- La ultima columna de la tabla por modulo (cortada a 110 caracteres por el script) es la de bits de memoria.
- Logs: `logs/TAREA-021_map.log` y `logs/TAREA-021_fit.log`.
