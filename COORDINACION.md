# Coordinación del proyecto

Canal entre **Claude (nube)**, que escribe el código, las pruebas y la documentación, **Claude Code (PC del laboratorio)**, que compila y programa con Quartus, y el **equipo**, que compra, arma, prueba y presenta.

## Cómo funciona

| Quién | Qué hace | Dónde escribe |
|---|---|---|
| `@claude-nube` | RTL, testbenches, docs; revisa resultados y crea tareas | `rtl/`, `sim/`, `quartus/`, `docs/`, `tools/`, este archivo |
| `@claude-code` | Ejecuta tareas en la PC (Quartus, git) y reporta | solo `resultados/` y `logs/` |
| `@equipo` | Compras, cableado, pruebas en la tarjeta, reporte y demostración | lo que diga la tarea |

- Una tarea = una línea en la lista de abajo + una sección `## TAREA-NNN` con los pasos.
- Casillas: `[ ]` pendiente, `[x]` revisada y aceptada, `[!]` falló, `[-]` cancelada.
- Una tarea `@claude-code` cuenta como ejecutada cuando existe `resultados/TAREA-NNN.md`.
- Nadie inventa salidas. Lo que no se pudo ejecutar se reporta como FALLO con el error real.
- Claude Code sigue `tools/PROMPT_CLAUDE_CODE.md` (se lanza a mano con `claude -p`; no hay watcher).

## Tareas

Las tareas 001 a 012 fueron del robot seguidor de luz (proyecto anterior, ver el historial de git hasta `9a4ae0c`).

- [-] TAREA-009 @claude-code: Compilar el robot en Quartus (cancelada por el cambio de proyecto)
- [-] TAREA-010 a TAREA-012 @equipo: armado y pruebas del robot (canceladas)
- [x] TAREA-013 @claude-code: Compilar el sintetizador en Quartus para la DE10-Lite (hecha; ya no aplica: la tarjeta del equipo es la EP2C5T144)
- [ ] TAREA-014 @equipo: Comprar el material ([docs/MATERIALES.md](docs/MATERIALES.md))
- [ ] TAREA-015 @equipo: Cablear teclados, botones, audio y VGA ([docs/CABLEADO.md](docs/CABLEADO.md))
- [ ] TAREA-016 @equipo: Pruebas en la tarjeta y ensayo de la demostración ([docs/PRUEBAS.md](docs/PRUEBAS.md))
- [ ] TAREA-017 @claude-code: Estimar recursos con el Quartus que ya esta instalado
- [ ] TAREA-018 @claude-code: Instalar Quartus II 13.0 SP1 con soporte de Cyclone II
- [ ] TAREA-019 @claude-code: Compilar el sintetizador para la EP2C5T144
- [ ] TAREA-020 @equipo: Capturas de Quartus para el primer avance (despues de la TAREA-019)

---

## TAREA-013 @claude-code: Compilar el sintetizador en Quartus (DE10-Lite)

Hecha el 7 de noviembre de 2026 (`resultados/TAREA-013.md`). Se conserva como referencia de recursos: 6 464 elementos logicos en la MAX 10, con displays de 7 segmentos y VGA de 12 bits.

## TAREA-016 @equipo: Pruebas en la tarjeta

Seguir la lista de [docs/PRUEBAS.md](docs/PRUEBAS.md#pruebas-en-la-tarjeta) y anotar en `resultados/TAREA-016.md` cada prueba con OK o lo que se observó. Grabar el video de la demostración siguiendo el guion.

## TAREA-017 @claude-code: Estimar recursos con el Quartus instalado

El Quartus Prime de la PC (`~/altera_lite`) ya no soporta Cyclone II, pero sirve para estimar: la Cyclone IV E usa el mismo elemento logico de 4 entradas.

1. `git pull --rebase`.
2. `sh quartus/estimar_recursos.sh` (trabaja en `quartus/estimacion/`, no toca el proyecto real).
3. En `resultados/TAREA-017.md`: si Analysis & Synthesis y Fitter terminaron bien, el `fit.summary` completo y la tabla de elementos logicos por modulo tal como la imprime el script. Si fallo, los errores tal como salen.
4. Log: copia `quartus/estimacion/map.log` y `fit.log` a `logs/TAREA-017_map.log` y `logs/TAREA-017_fit.log`.

## TAREA-018 @claude-code: Instalar Quartus II 13.0 SP1

Cyclone II solo se compila con Quartus II 13.0 SP1 Web Edition (gratis, sin licencia). Se instala sin sudo en `~/altera/13.0sp1`; no toca el Quartus Prime de `~/altera_lite`.

1. Carpeta de descarga: `~/Descargas/quartus13` (crearla). Archivos para Linux, segun la pagina oficial de Altera (Quartus II Web Edition 13.0sp1, Linux):

   | Archivo | Tamano | SHA-1 |
   |---|---|---|
   | `QuartusSetupWeb-13.0.1.232.run` | 1.6 GB | `1418b2971aa44686c5d11b6c8ef81eee137379e8` |
   | `cyclone_web-13.0.1.232.qdz` (Cyclone II, III y IV) | 568.9 MB | `882b19a8ffee1edd133693ff422a3f6c5a615589` |

2. Si los archivos ya estan en esa carpeta, saltar al paso 3. Si no, intentar la descarga directa con `wget -c` desde `https://downloads.intel.com/akdlm/software/acdsinst/13.0sp1/232/ib_installers/<archivo>`. La pagina de Altera ahora pide iniciar sesion: si lo descargado es HTML o el SHA-1 no coincide, borrarlo y terminar con FALLO explicando que el equipo debe bajar los dos archivos desde https://www.altera.com/downloads/fpga-development-tools/quartus-ii-web-edition-design-software-version-13-0sp1-linux con su cuenta y dejarlos en `~/Descargas/quartus13`.
3. `sha1sum` de los dos archivos contra la tabla. Si no coinciden, FALLO.
4. `chmod +x QuartusSetupWeb-13.0.1.232.run` y correrlo en modo desatendido con el `.qdz` en la misma carpeta, instalando en `~/altera/13.0sp1` (revisar las opciones con `--help`; normalmente `--mode unattended --installdir ~/altera/13.0sp1`). Sin sudo. Si faltan bibliotecas de 32 o 64 bits, reportar el error exacto y los paquetes que pide; no instalarlos.
5. Revisar que `~/altera/13.0sp1/quartus/bin/quartus_sh --version` responda y que exista `~/altera/13.0sp1/quartus/common/devinfo/cycloneii`.
6. Probar que la interfaz grafica abra: `~/altera/13.0sp1/quartus/bin/quartus --64bit &` (o sin `--64bit` si no lo acepta), esperar unos 30 s y cerrarla. Reportar si abrio o el error que salio en la terminal; el equipo la necesita para las capturas de la TAREA-020.
7. USB-Blaster: si `~/altera/13.0sp1/quartus/bin/jtagconfig` no ve el cable cuando el equipo lo conecte, hace falta la regla de udev (`/etc/udev/rules.d/51-usbblaster.rules`, necesita sudo): no la instales, solo reporta el texto exacto de la regla para que el equipo la agregue.
8. En `resultados/TAREA-018.md`: que se descargo (nombres, tamanos y SHA-1), donde quedo instalado, la salida de `quartus_sh --version`, si abrio la interfaz grafica y cualquier error tal como salio.

## TAREA-019 @claude-code: Compilar para la EP2C5T144

1. `git pull --rebase`.
2. `sh quartus/compilar.sh` (crea el proyecto para la EP2C5T144C8 con `crear_proyecto.tcl`, nivel superior `quartus/sintetizador.bdf`, y compila con Quartus II 13.0 SP1). Si falla por el `.bdf`, copia ese log a `logs/TAREA-019_bdf.log`, corre `sh quartus/compilar.sh sinte_top` (el mismo circuito en VHDL) y reporta las dos corridas. Si falla por el PLL (`quartus/ip/pll_25mhz.vhd`), reporta el error y regenera el PLL con el MegaWizard como dice el encabezado de ese archivo.
3. En `resultados/TAREA-019.md`: estado de cada etapa (Analysis & Synthesis, Fitter, Assembler, TimeQuest), errores y advertencias criticas tal como salen, el `output_files/sintetizador.fit.summary` completo, la tabla "Fitter Resource Utilization by Entity" (solo elementos logicos, registros y memoria por modulo) y Fmax y slack del reloj de 25 MHz del PLL (`output_files/sintetizador.sta.rpt`).
4. Si el Fitter falla porque el diseno no cabe, incluir el mensaje de error tal como sale y el `output_files/sintetizador.map.summary` completo (Analysis & Synthesis ya da el total de elementos logicos).
5. Log completo en `logs/TAREA-019.log` (copia de `logs/compilacion.log`).
6. Si la tarjeta esta conectada (`quartus_pgm -l` la muestra), **no** la programes: solo reportalo.

## TAREA-020 @equipo: Capturas de Quartus para el primer avance

Despues de que la TAREA-019 compile bien. Se siguen los pasos del manual del profesor (*Creacion y uso de bloques en Quartus*): simbolos desde los `.vhd`, diagrama de bloques como nivel superior, compilacion y Pin Planner.

Abrir el proyecto: `~/altera/13.0sp1/quartus/bin/quartus quartus/sintetizador.qpf &`. Cada captura de la ventana completa de Quartus (tecla Impr Pant o `gnome-screenshot -w -f <archivo>`), en PNG, dentro de la carpeta `capturas/` del repo con estos nombres:

| Archivo | Que debe verse |
|---|---|
| `01_proyecto.png` | Project Navigator en la pestana *Files* con los `.vhd` de `rtl/` y `sintetizador.bdf`; arriba, el dispositivo EP2C5T144C8 |
| `02_simbolo.png` | un `.vhd` abierto (por ejemplo `rtl/voz.vhd`) con el menu *File > Create/Update > Create Symbol Files for Current File* desplegado |
| `03_bdf_completo.png` | `quartus/sintetizador.bdf` abierto completo (*View > Fit in Window*) |
| `04_bdf_voces.png` | acercamiento al BDF donde se lean los bloques de las 3 voces, el gestor de voces y la salida de audio |
| `05_bdf_control.png` | acercamiento donde se lean el PLL, el reset, los teclados, los botones, el control, el secuenciador y la VGA |
| `06_top_level.png` | Project Navigator en la pestana *Hierarchy* con `sintetizador` como nivel superior y sus bloques debajo |
| `07_flow_summary.png` | *Compilation Report > Flow Summary* (elementos logicos, registros, pines, bits de memoria, PLL) |
| `08_recursos_entidad.png` | *Fitter > Resource Section > Resource Utilization by Entity* |
| `09_pin_planner.png` | *Assignments > Pin Planner* con la lista de pines (columnas *Node Name* y *Location*) |
| `10_fmax.png` | *TimeQuest Timing Analyzer > Slow Model > Fmax Summary* |
| `11_rtl_viewer.png` | *Tools > Netlist Viewers > RTL Viewer*, nivel superior |

No hace falta hacer commit: la nube las toma de la carpeta, arma el PDF del avance solo con estas capturas y las sube al repo. Si la interfaz de la 13.0 SP1 no abre, avisar: las capturas 02 a 05 se pueden tomar con el Quartus Prime de `~/altera_lite` abriendo solo los archivos `.vhd` y `.bdf`.

