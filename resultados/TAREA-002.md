# TAREA-002
Estado: OK
Fecha: 2026-10-22 21:11
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real

```
$ cat /etc/os-release | grep PRETTY_NAME ; uname -r
PRETTY_NAME="Linux Mint 22.3"
7.0.0-38-generic
$ git --version
git version 2.43.0
$ claude --version
2.1.309 (Claude Code)
$ git config user.name ; git config user.email
BassAndres
91858035+BassAndres@users.noreply.github.com
$ git remote -v
origin	https://github.com/samisal123/robot-seguidor-luz-vlsi.git (fetch)
origin	https://github.com/samisal123/robot-seguidor-luz-vlsi.git (push)

$ which quartus_sh vsim ghdl
(sin salida: ninguno está en el PATH)
$ ~/altera_lite/25.1std/quartus/bin/quartus_sh --version
Quartus Prime Shell
Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition
Copyright (C) 2025  Altera Corporation. All rights reserved.

$ ls ~/altera_lite/25.1std/
devdata  ip  licenses  logs  nios2eds  niosv  quartus  uninstall
$ find ~/altera_lite /opt /usr/local -maxdepth 4 -name vsim
(sin salida)
$ dpkg -l | grep -i ghdl
(sin salida)
$ apt-cache policy ghdl
ghdl:
  Installed: (none)
  Candidate: 4.1.0+dfsg-0ubuntu2.1

$ quartus_pgm -l
...
Info: Quartus Prime Programmer was successful. 0 errors, 0 warnings
No JTAG hardware available
$ jtagconfig
No JTAG hardware available
```

## Notas

- Quartus: `~/altera_lite/25.1std/quartus/bin/quartus_sh` (25.1std.0 Lite). No está en el PATH; los comandos se llaman con ruta completa.
- Questa/ModelSim: no encontrado (no hay `questa_fse/` ni `modelsim_ase/` en la instalación). No se pudo probar licencia.
- GHDL: no instalado al momento de esta tarea; disponible en apt (4.1.0). Se instaló después, por indicación del usuario, para simular la Semana 2 (ver resultados de simulación).
- Programador: no hay USB-Blaster conectado; `lsusb` no muestra dispositivos Altera (09fb).
