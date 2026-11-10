# TAREA-019
Estado: FALLO (no hay Quartus II 13.0 SP1: depende de la TAREA-018, que fallo)
Fecha: 2026-11-09 20:42
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
$ git pull --rebase
Already up to date.
$ command -v quartus_sh
(nada: quartus_sh no esta en el PATH)
$ ls ~/altera/13.0sp1/quartus/bin/quartus_sh /opt/altera/13.0sp1/quartus/bin/quartus_sh
ls: cannot access '/home/samuel/altera/13.0sp1/quartus/bin/quartus_sh': No such file or directory
ls: cannot access '/opt/altera/13.0sp1/quartus/bin/quartus_sh': No such file or directory
$ sh quartus/compilar.sh
No encuentro quartus_sh
rc=1
```

Tarjeta (con el `quartus_pgm` del Quartus Prime 25.1 de `~/altera_lite`, solo listado, sin `-o`):

```
$ ~/altera_lite/25.1std/quartus/bin/quartus_pgm -l
No JTAG hardware available
Info: Quartus Prime Programmer was successful. 0 errors, 0 warnings
```

## Notas

- No se compilo nada: ni Analysis & Synthesis, ni Fitter, ni Assembler, ni TimeQuest. No hay `fit.summary`, tabla por entidad ni Fmax que reportar.
- No se agrego el Quartus Prime 25.1 al PATH para forzar la corrida: no tiene Cyclone II (ni Cyclone IV, ver TAREA-017), asi que solo daria el mismo error de familia no instalada.
- `logs/compilacion.log` no cambio (es de la TAREA-013, MAX 10), por eso no se copio a `logs/TAREA-019.log`.
- No hay USB-Blaster conectado; no se programo nada.
- Antecedente importante: la estimacion de la TAREA-017 con MAX 10 dio **5 431 elementos logicos**, mas que los 4 608 de la EP2C5. Es probable que, cuando se pueda compilar, el Fitter de la 13.0 SP1 diga que no cabe; conviene revisar el diseno (`vga_ui` usa 1 912 LE y cada `voz` ~680) antes de volver a correr esta tarea.
- Para reintentar: completar la TAREA-018 (el equipo baja los dos archivos con su cuenta de Altera en `~/Descargas/quartus13` y se libera espacio en disco) y volver a correr esta tarea.
