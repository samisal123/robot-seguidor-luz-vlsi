# TAREA-022
Estado: FALLO (no cabe en el disco: se detuvo la instalacion con el disco al 100 %)
Fecha: 2026-11-09 21:50
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

Paso 1: los archivos estaban completos en `~/Downloads` (sin `.crdownload`); se movieron a `~/Descargas/quartus13`.

```
$ ls -l ~/Descargas/quartus13
-rw-rw-r-- 1 samuel samuel  596526264 Nov  9 21:20 cyclone_web-13.0.1.232.qdz
-rw-rw-r-- 1 samuel samuel 1753569283 Nov  9 21:24 QuartusSetupWeb-13.0.1.232.run
$ sha1sum *
882b19a8ffee1edd133693ff422a3f6c5a615589  cyclone_web-13.0.1.232.qdz       # coincide
1418b2971aa44686c5d11b6c8ef81eee137379e8  QuartusSetupWeb-13.0.1.232.run   # coincide
```

Paso 2: no hay ningun `Quartus-web-13.0.1.232-linux.tar` en `~/Descargas` ni en `~/Downloads`.

Paso 3:

```
$ df -h ~
/dev/nvme0n1p6   59G   52G  4.1G  93% /
```

Paso 4 (instalacion desatendida, sin sudo):

```
$ ./QuartusSetupWeb-13.0.1.232.run --help
Quartus II Web Edition (Free) 13.0.1.232 13.0sp1
 --unattendedmodeui <unattendedmodeui>  Allowed: none minimal minimalWithDialogs
 --mode <mode>          Allowed: qt gtk xwindow text unattended
 --installdir <installdir>   Default: /home/samuel/altera/13.0sp1
$ ./QuartusSetupWeb-13.0.1.232.run --mode unattended --unattendedmodeui none --installdir /home/samuel/altera/13.0sp1
```

Avance (espacio libre en `/` y tamano de `~/altera/13.0sp1`, una lectura por minuto):

```
libre=4102M  instalado=0M
libre=1852M  instalado=2162M
libre= 465M  instalado=3546M
libre= 381M  (ip 1056M, nios2eds 129M, quartus 2442M; devinfo sin cycloneii)
```

Con menos de 400 MB libres, sin haber empezado con los dispositivos Cyclone (el `.qdz` mide 570 MB comprimido), se detuvo el instalador para no llenar el disco del sistema. Al detenerlo quedaban 160 MB libres.

Antes de borrarla se probo la parte instalada:

```
$ ~/altera/13.0sp1/quartus/bin/quartus_sh --version
Quartus II 32-bit Shell
Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Full Version
$ ls ~/altera/13.0sp1/quartus/common/devinfo
configuration  ddb_cumulative_family.ddb  ddb_cumulative_info.ddb  device.db  device_empty.db  legacy  programmer
```

(no existe `devinfo/cycloneii`). Despues se borro la instalacion incompleta (`~/altera/13.0sp1`) para recuperar el espacio:

```
$ df -h ~
/dev/nvme0n1p6   59G   52G  4.0G  93% /
```

Pasos 5 a 7 (interfaz grafica, Cyclone II, USB-Blaster): no se hicieron porque no quedo instalado.

## Notas

- **Los instaladores estan bien** (SHA-1 correctos) y siguen en `~/Descargas/quartus13`; no se borraron.
- **El binario de la 13.0 SP1 si corre en esta PC** (`quartus_sh --version` respondio sin pedir bibliotecas), asi que la unica traba es el espacio.
- **Espacio necesario:** sin Cyclone ya iba en 3.85 GB; con los dispositivos Cyclone se calculan unos 5 a 6 GB en total. Como los instaladores (2.2 GB) estan en el mismo disco y no se pueden borrar durante la instalacion, hacen falta **al menos 6 a 7 GB libres** antes de reintentar (hoy hay 4.0 GB).
- Que ocupa espacio en `~`: `~/altera_lite` 8.9 GB (Quartus Prime 25.1, lo usa `estimar_recursos.sh`), `~/Descargas` 2.2 GB (los instaladores), `~/Downloads` 1.6 GB, `~/.cache` 311 MB. No se borro nada de eso; el equipo decide que liberar (por ejemplo `~/Downloads`, o instalar en otra unidad/USB cambiando `--installdir`).
- Para reintentar: liberar espacio y volver a correr esta tarea desde el paso 3.
- La regla de udev para el USB-Blaster es la misma de `resultados/TAREA-018.md`.
