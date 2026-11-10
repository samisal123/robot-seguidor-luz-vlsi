# TAREA-023
Estado: FALLO (no hay Quartus II 13.0 SP1: la TAREA-022 no pudo instalarlo por falta de espacio)
Fecha: 2026-11-09 21:51
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
$ ls ~/altera/13.0sp1/quartus/bin/quartus_sh
ls: cannot access '/home/samuel/altera/13.0sp1/quartus/bin/quartus_sh': No such file or directory
```

## Notas

- La tarea pide correr solo si la TAREA-022 dejo instalado Quartus II 13.0 SP1, y no fue asi: no se corrio `quartus/compilar.sh`. No hay `fit.summary`, tabla por entidad ni Fmax, y no se creo `logs/TAREA-023.log`.
- No se reviso la tarjeta con `quartus_pgm -l` (no hay `quartus_pgm` de la 13.0 SP1; en la TAREA-019 el de la 25.1 dijo "No JTAG hardware available").
- Buena noticia de la TAREA-021: con las tablas en memoria la estimacion bajo a 3 805 LE (de 4 608 de la EP2C5), asi que es probable que quepa cuando se pueda compilar.
