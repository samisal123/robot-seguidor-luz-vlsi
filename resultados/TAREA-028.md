# TAREA-028
Estado: OK (13 de 14 capturas; falta 13_fsm_secuenciador.png, ver Notas)
Fecha: 2026-11-10 08:53
Equipo: pc-bd-scm.n.fi.unam

## Comandos y salida real
Requisitos: TAREA-026 OK (la interfaz abre) y TAREA-027 compilo bien.

Pantalla virtual (sin sudo):
```
$ which Xvfb xdotool import        -> solo /usr/bin/xdotool (no hay Xvfb ni ImageMagick)
$ mkdir -p ~/altera/13.0sp1/extra/xvfb && cd ~/altera/13.0sp1/extra/xvfb
$ apt-get download xvfb
Fetched 877 kB in 2s (483 kB/s)          -> xvfb_2%3a21.1.12-1ubuntu1.9_amd64.deb
$ dpkg -x xvfb_*.deb root                -> root/usr/bin/Xvfb, root/usr/bin/xvfb-run
$ root/usr/bin/Xvfb :99 -screen 0 1600x900x24 -nolisten tcp &
  (solo avisos de xkbcomp: "Could not resolve keysym XF86...", "Errors from xkbcomp are not fatal")
$ DISPLAY=:99 xdpyinfo | grep dimensions
  dimensions:    1600x900 pixels (406x229 millimeters)
$ DISPLAY=:99 metacity --sm-disable &    (ya instalado; para poder maximizar)
$ DISPLAY=:99 sh quartus/abrir_quartus.sh &
$ DISPLAY=:99 wmctrl -l
0x0040032c  0 pc-bd-scm.n.fi.unam Quartus II 64-Bit - .../quartus/sintetizador - sintetizador
```
Las dependencias de xvfb ya estaban todas en la PC (xserver-common, libxfont2, xauth, x11-xkb-utils, libpixman-1-0, libunwind8, libgl1...), asi que no hizo falta `LD_LIBRARY_PATH`. Al final se cerraron Quartus (ventana), metacity y Xvfb; no queda ningun proceso.

Capturas en `capturas/` (PNG 1600x900, pantalla completa de :99 con Pillow `ImageGrab.grab(xdisplay=":99")`, sin recortes):

| Archivo | Que muestra |
|---|---|
| 01_proyecto.png | Project Navigator, pestana Files: los 30 `.vhd` de `rtl/`, `ip/pll_25mhz.vhd` y `sintetizador.bdf`; a la derecha el Flow Summary con Device EP2C5T144C8 |
| 02_simbolo.png | `rtl/voz.vhd` abierto con File > Create/Update desplegado y *Create Symbol Files for Current File* resaltado (no se le dio clic) |
| 03_bdf_completo.png | `sintetizador.bdf` con View > Fit in Window |
| 04_bdf_voces.png | mitad derecha: selector_notas, gestor_voces, las 3 `voz`, audio_salida, vga_ui, leds_estado y pines de salida |
| 05_bdf_control.png | mitad izquierda: pll_25mhz, reset_encendido, base_tiempo, entradas_placa, interfaz_teclados, teclas_notas, control, secuenciador y selector_notas (este ultimo cortado a la derecha) |
| 06_top_level.png | pestana Hierarchy: Cyclone II EP2C5T144C8, `sintetizador` y sus 16 bloques, con `voz:u_voz0` abierto (adsr, dds, forma_onda) |
| 07_flow_summary.png | Compilation Report > Flow Summary (3,782 LE, 1403 registros, 30 pines, 76,032 bits, 6 multiplicadores, 1 PLL) |
| 08_recursos_entidad.png | Fitter > Resource Section > Resource Utilization by Entity (columnas LE, registros, I/O, memoria) |
| 09_pin_planner.png | Pin Planner maximizado con los 30 pines (Node Name, Direction, Location, I/O Bank...) |
| 10_fmax.png | TimeQuest > Slow Model > Fmax Summary: 36.05 MHz, u_pll\|u_pll\|pll\|clk[0] |
| 11_rtl_viewer.png | RTL Viewer, nivel superior completo (Fit in Window) |
| 12_fsm_adsr.png | State Machine Viewer `\|sintetizador\|voz:u_voz0\|adsr:u_adsr\|est`: diagrama con REPOSO, ATAQUE, LIBERACION, DECAIMIENTO, SOSTENIDO y tabla de transiciones |
| 14_simbolos.png | acercamiento al BDF donde se leen los puertos de teclas_notas, control y secuenciador |

## Notas
- **13_fsm_secuenciador.png no se logro.** En el State Machine Viewer la maquina `|sintetizador|secuenciador:u_sec|est` aparece en la lista, pero al elegirla el diagrama y la pestana *Transitions* quedan en blanco (se probo 4 veces: seleccion con clic, con Enter y esperando 30 s). La pestana *Encoding* si carga (ESPERA, GRABANDO, LEER, CARGAR, TOCAR, one-hot, igual que en `sintetizador.map.rpt`). Las otras maquinas (las tres ADSR y `eco:u_eco|fase`) si se dibujan, asi que es algo de esa maquina en el visor. La captura del visor vacio queda como evidencia en `logs/TAREA-028_fsm_secuenciador_vacia.png` (no se puso con el nombre 13 para que no entre al PDF).
- 11_rtl_viewer: con Fit in Window el nivel superior entra completo pero los nombres de los bloques no se dibujan a ese tamano; con un paso de zoom tampoco aparecen y ya no entra todo. Se dejo la vista completa.
- 05: entre ver todo el lado izquierdo con letra chica o leer los bloques se eligio un zoom donde se leen; selector_notas queda cortado a la derecha (su titulo y puertos de entrada si se ven). 04 tambien lo muestra completo.
- Para tener mas espacio se cerraron los paneles Tasks, Project Navigator y Messages durante algunas capturas y se ensancharon columnas o divisores; no se edito ninguna imagen.
- No se guardo nada en Quartus: `git status` no muestra cambios en `quartus/` ni en `rtl/` (en la 02 no se le dio clic a Create Symbol Files, que habria escrito un `.bsf` en `rtl/`).
- Paquete bajado y extraido: `xvfb 2:21.1.12-1ubuntu1.9` en `~/altera/13.0sp1/extra/xvfb/`. Ya instalados y usados: xdotool 3.20160805.1, wmctrl 1.07-7ubuntu3, metacity 3.52.0, Pillow 10.2.0. No hay ImageMagick.
- No se uso la pantalla real (:0) en esta tarea.
