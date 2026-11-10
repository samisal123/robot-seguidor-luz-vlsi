# TAREA-024
Estado: OK (instalado con Cyclone II; la interfaz grafica no abre por falta de libpng12, ver Notas)
Fecha: 2026-11-09 22:12
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

Paso 1:

```
$ df -h ~
/dev/nvme0n1p6   59G   44G   13G  78% /
$ ls -d ~/altera_lite
/home/samuel/altera_lite
```

13 GB libres (mas de 6.5 GB), asi que se siguio. `~/altera_lite` todavia existe como carpeta, pero ya no ocupa los 8.9 GB (el espacio libre subio de 4.0 a 13 GB).

Paso 2 (instaladores en `~/Descargas/quartus13`, sin sudo):

```
$ ./QuartusSetupWeb-13.0.1.232.run --mode unattended --unattendedmodeui none --installdir /home/samuel/altera/13.0sp1
exit=0
```

Espacio libre en `/` y tamano de `~/altera/13.0sp1`, una lectura por minuto (con paro automatico si bajaba de 300 MB):

```
22:04 libre=12788M instalado=0M
22:05 libre=10711M instalado=2078M
22:06 libre=9855M instalado=2916M
22:07 libre=8291M instalado=4489M
22:08 fin; libre= 6530M
```

Final de `/tmp/bitrock_installer_50480.log`:

```
Creating uninstaller 100%
Installation completed
Log finished 11/09/2026 at 22:08:21
```

Paso 3 (pasos 5 a 8 de la TAREA-018):

```
$ ~/altera/13.0sp1/quartus/bin/quartus_sh --version
Quartus II 32-bit Shell
Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition
$ ls ~/altera/13.0sp1/quartus/common/devinfo
configuration  cycloneii  cycloneiii  cycloneive  cycloneivgx  ddb_cumulative_family.ddb
ddb_cumulative_info.ddb  device.db  device_empty.db  legacy  programmer
$ du -sh ~/altera/13.0sp1
6.2G
```

Interfaz grafica:

```
$ ~/altera/13.0sp1/quartus/bin/quartus --64bit
quartus: error while loading shared libraries: libpng12.so.0: cannot open shared object file: No such file or directory
$ ~/altera/13.0sp1/quartus/bin/quartus
quartus: error while loading shared libraries: libpng12.so.0: cannot open shared object file: No such file or directory
```

Bibliotecas que faltan (`ldd` con `LD_LIBRARY_PATH` en la carpeta de Quartus):

```
linux64/quartus: libpng12.so.0 => not found
linux/quartus (32 bits): libICE.so.6, libpng12.so.0, libSM.so.6 => not found
linux y linux64: quartus_sh, quartus_map, quartus_fit, quartus_asm, quartus_sta, quartus_pgm => ok
```

USB-Blaster:

```
$ ~/altera/13.0sp1/quartus/bin/jtagconfig
No JTAG hardware available
```

Paso 4:

```
$ df -h ~
/dev/nvme0n1p6   59G   50G  6.4G  89% /
```

## Notas

- **Quartus II 13.0 SP1 Web Edition quedo instalado** en `~/altera/13.0sp1` (6.2 GB) con Cyclone II, III y IV. Toda la cadena de linea de comandos (sintesis, fitter, ensamblador, tiempos, programador) tiene sus bibliotecas, asi que se puede compilar (TAREA-025).
- **La interfaz grafica no abre**: le falta `libpng12.so.0`, que ya no viene en las distribuciones actuales. No se instalo nada (la TAREA-018 pide solo reportarlo). El equipo la necesita para la TAREA-020; opciones:
  - Con sudo: instalar el paquete `libpng12-0` (ya no esta en los repositorios de Ubuntu/Mint recientes; se baja el `.deb` de Ubuntu 16.04 `xenial`, `libpng12-0_1.2.54-1ubuntu1_amd64.deb`, o del PPA `linuxuprising/libpng12`) y abrir con `quartus --64bit`.
  - Sin sudo: compilar libpng 1.2.x desde el codigo fuente y copiar `libpng12.so.0` a `~/altera/13.0sp1/quartus/linux64/` (Quartus ya busca bibliotecas ahi).
  - Siempre usar `--64bit`: la version de 32 bits ademas pide `libICE.so.6` y `libSM.so.6` de 32 bits.
- **No se borraron los instaladores** de `~/Descargas/quartus13` (2.2 GB): el paso 4 dice hacerlo "si todo quedo bien" y la interfaz grafica no quedo. La instalacion no depende de ellos para arreglar lo de libpng12, asi que el equipo puede borrarlos si quiere (`rm ~/Descargas/quartus13/*`); bajarlos otra vez pide cuenta de Altera.
- El USB-Blaster no esta conectado. Si al conectarlo `jtagconfig` no lo ve, la regla de udev es la de `resultados/TAREA-018.md`.
