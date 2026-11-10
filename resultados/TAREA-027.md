# TAREA-027
Estado: OK
Fecha: 2026-11-10 08:40
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real
```
$ git pull --rebase
Already up to date.
$ python3 tools/revisa_bdf.py
179 puertos, 199 cables, 0 uniones, 66 senales revisadas
OK
$ sh quartus/compilar.sh          (35 s)
Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition
Info: Quartus II 32-bit Analysis & Synthesis was successful. 0 errors, 1 warning
Info (170137): Fitter placement was successful
Info: Quartus II 32-bit Fitter was successful. 0 errors, 4 warnings
Info: Quartus II 32-bit Assembler was successful. 0 errors, 0 warnings
Info: Quartus II 32-bit TimeQuest Timing Analyzer was successful. 0 errors, 2 warnings
Info (293000): Quartus II Full Compilation was successful. 0 errors, 7 warnings
```
En el log: `Info (12021): Found 1 design units, including 1 entities, in source file sintetizador.bdf`.

`output_files/sintetizador.fit.summary`:
```
Fitter Status : Successful - Tue Nov 10 08:39:44 2026
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

Tiempos (`output_files/sintetizador.sta.rpt`, reloj `u_pll|u_pll|pll|clk[0]`, 25 MHz):
```
Slow Model Fmax : 36.05 MHz (Restricted 36.05 MHz)
Slow Model Setup slack : 12.261   TNS 0.000
Slow Model Hold  slack :  0.499   TNS 0.000
Fast Model Setup slack : 31.609   TNS 0.000
Fast Model Hold  slack :  0.215   TNS 0.000
```

Advertencias (todas):
```
3 Warning (20028): Parallel compilation is not licensed and has been disabled
1 Warning (292013): Feature LogicLock is only available with a valid subscription license.
1 Warning (306006): Found 17 output pins without output pin load capacitance assignment
2 Warning (332153): Family doesn't support jitter analysis.
```

## Comparacion con la TAREA-025
| | TAREA-025 | TAREA-027 |
|---|---|---|
| Elementos logicos | 3 782 | 3 782 |
| Registros | 1 403 | 1 403 |
| Bits de memoria | 76 032 | 76 032 |
| Multiplicadores 9 bits | 6 | 6 |
| Pines | 30 | 30 |
| PLL | 1 | 1 |
| Fmax | 36.05 MHz | 36.05 MHz |
| Setup slack (slow) | 12.261 | 12.261 |

## Notas
- Todo sale identico; no hay advertencias nuevas (las 7 son las mismas de la TAREA-025, sin Critical Warning). No hizo falta regresar a `--sin-cables`.
- `.sof` 151 396 B y `.pof` 524 508 B, igual que antes.
- Log completo en `logs/TAREA-027.log` (copia de `logs/compilacion.log`).
