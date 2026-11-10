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
- [!] TAREA-017 @claude-code: Estimar recursos con el Quartus que ya esta instalado (el Quartus de la PC no trae Cyclone IV; la estimacion con MAX 10 dio 5 431 LE, inflada porque las tablas se armaron con logica)
- [!] TAREA-018 @claude-code: Instalar Quartus II 13.0 SP1 (la descarga pide cuenta de Altera; el equipo baja los archivos)
- [!] TAREA-019 @claude-code: Compilar el sintetizador para la EP2C5T144 (sin Quartus 13.0 SP1)
- [ ] TAREA-020 @equipo: Capturas de Quartus para el primer avance (despues de la TAREA-025)
- [x] TAREA-021 @claude-code: Estimar recursos otra vez (MAX 10 con las tablas en memoria): 3 805 LE, cabe en la EP2C5 (83 %)
- [!] TAREA-022 @claude-code: Instalar Quartus II 13.0 SP1 con los archivos ya descargados (no cupo en el disco: necesita 6 a 7 GB libres)
- [!] TAREA-023 @claude-code: Compilar el sintetizador para la EP2C5T144 (sin Quartus 13.0 SP1)
- [x] TAREA-024 @claude-code: Instalar Quartus II 13.0 SP1 (ya con espacio): instalado con Cyclone II; la interfaz grafica pide libpng12
- [x] TAREA-025 @claude-code: Compilar el sintetizador para la EP2C5T144: 3 782 LE (82 %), 25 MHz con 12.3 ns de margen
- [ ] TAREA-026 @claude-code: Hacer que abra la interfaz grafica de Quartus 13.0 (libpng12 sin sudo)

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

Despues de que la TAREA-025 compile bien. Se siguen los pasos del manual del profesor (*Creacion y uso de bloques en Quartus*): simbolos desde los `.vhd`, diagrama de bloques como nivel superior, compilacion y Pin Planner.

Abrir el proyecto: `sh quartus/abrir_quartus.sh &` (Quartus 13.0 de 64 bits; necesita la TAREA-026). Cada captura de la ventana completa de Quartus (tecla Impr Pant o `gnome-screenshot -w -f <archivo>`), en PNG, dentro de la carpeta `capturas/` del repo con estos nombres:

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
| `12_fsm_adsr.png` | *Tools > Netlist Viewers > State Machine Viewer*, la maquina `est` de `adsr` (cualquiera de las 3 voces), con el diagrama y la tabla de transiciones |
| `13_fsm_secuenciador.png` | lo mismo para la maquina `est` de `secuenciador` |
| `14_simbolos.png` | el BDF con zoom en dos o tres bloques donde se lean los nombres de sus puertos (por ejemplo `voz`, `adsr` dentro de su simbolo o `secuenciador`) |

No hace falta hacer commit: la nube las toma de la carpeta, arma el PDF del avance solo con estas capturas y las sube al repo. Si la interfaz de la 13.0 SP1 no abre, avisar: las capturas 02 a 05 se pueden tomar con el Quartus Prime de `~/altera_lite` abriendo solo los archivos `.vhd` y `.bdf`.

## TAREA-021 @claude-code: Estimar recursos otra vez

La TAREA-017 mostro que la MAX 10 de la estimacion no acepto las tablas con contenido inicial ("MIF is not supported for the selected family") y las armo con logica. `quartus/estimar_recursos.sh` ya usa el Quartus Prime de `~/altera_lite` con la MAX 10 en modo de imagen unica con memoria inicializada, para que las tablas vayan a bloques de memoria como en la Cyclone II.

1. `git pull --rebase`.
2. `sh quartus/estimar_recursos.sh` (trabaja en `quartus/estimacion/`, no toca el proyecto real).
3. En `resultados/TAREA-021.md`: la salida completa del script (las secciones de tablas no inferidas y memorias inferidas, el `fit.summary` y la tabla de elementos logicos por modulo). Si Analysis & Synthesis rechaza la asignacion `INTERNAL_FLASH_UPDATE_MODE`, reporta el error tal como sale y vuelve a correr quitando solo esa linea del `crear.tcl` generado; reporta las dos corridas.
4. Logs: `quartus/estimacion/map.log` y `fit.log` a `logs/TAREA-021_map.log` y `logs/TAREA-021_fit.log`.

## TAREA-022 @claude-code: Instalar Quartus II 13.0 SP1

Igual que la TAREA-018 desde su paso 3: el equipo ya bajo `QuartusSetupWeb-13.0.1.232.run` y `cyclone_web-13.0.1.232.qdz` con su cuenta de Altera.

1. Busca los dos archivos en `~/Descargas/quartus13`; si no estan ahi, buscalos en `~/Descargas` y `~/Downloads`. Si alguno sigue bajando (existe su `.crdownload`), espera revisando cada minuto, hasta 45 minutos en total. Cuando esten completos, muevelos a `~/Descargas/quartus13`. Si despues de esperar falta alguno, termina con FALLO diciendo cual.
2. Si quedo un `Quartus-web-13.0.1.232-linux.tar` a medias o completo en `~/Descargas` o `~/Downloads`, no lo borres: reporta su tamano (el equipo decide).
3. `df -h ~` antes de instalar; reporta el espacio libre.
4. Sigue los pasos 3 a 8 de la TAREA-018 (SHA-1, instalacion desatendida sin sudo en `~/altera/13.0sp1`, `quartus_sh --version`, que exista `devinfo/cycloneii`, que abra la interfaz grafica, regla de udev si hace falta) y reporta en `resultados/TAREA-022.md`.
5. Si la instalacion termina bien, `df -h ~` otra vez. No borres los instaladores.

## TAREA-023 @claude-code: Compilar para la EP2C5T144

Igual que la TAREA-019 (sus pasos 1 a 6), con el resultado en `resultados/TAREA-023.md` y el log en `logs/TAREA-023.log`. Solo si la TAREA-022 dejo instalado Quartus II 13.0 SP1.

## TAREA-024 @claude-code: Instalar Quartus II 13.0 SP1 (ya con espacio)

La TAREA-022 mostro que la instalacion necesita de 6 a 7 GB libres. El equipo decidio quitar el Quartus Prime 25.1 de `~/altera_lite` (8.9 GB, solo MAX 10) para hacer espacio; lo borra el equipo antes de esta tarea.

1. `df -h ~` y `ls -d ~/altera_lite`. Si quedan menos de 6.5 GB libres, termina con FALLO reportando el espacio y lo que mas ocupa en `~` (`du -sh ~/* | sort -h | tail`); no borres nada.
2. Instala igual que en la TAREA-022 (`--mode unattended --unattendedmodeui none --installdir ~/altera/13.0sp1`, con `cyclone_web-13.0.1.232.qdz` en la misma carpeta que el `.run`), revisando el espacio libre cada minuto; si baja de 300 MB, deten el instalador y reporta.
3. Sigue los pasos 5 a 8 de la TAREA-018 (`quartus_sh --version`, que exista `devinfo/cycloneii`, que abra la interfaz grafica, regla de udev si hace falta).
4. Si todo quedo bien, borra los dos instaladores de `~/Descargas/quartus13` (ya no hacen falta) y reporta `df -h ~` al final.
5. Resultado en `resultados/TAREA-024.md`.

## TAREA-025 @claude-code: Compilar para la EP2C5T144

Igual que la TAREA-019 (sus pasos 1 a 6), con el resultado en `resultados/TAREA-025.md` y el log en `logs/TAREA-025.log`. Solo si la TAREA-024 dejo instalado Quartus II 13.0 SP1 con Cyclone II.

## TAREA-026 @claude-code: Interfaz grafica de Quartus 13.0 sin sudo

La TAREA-024 dejo Quartus II 13.0 SP1 instalado, pero `quartus --64bit` no abre porque falta `libpng12.so.0`. Se agrega la biblioteca dentro de la carpeta de Quartus, sin sudo y sin instalar paquetes del sistema.

1. `mkdir -p ~/altera/13.0sp1/extra && cd ~/altera/13.0sp1/extra`.
2. Baja el paquete de Ubuntu 16.04 (xenial) desde el archivo oficial de Ubuntu, en este orden hasta que uno responda: `http://security.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb` y `http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb`. No uses otros sitios. Reporta el nombre, tamano y `sha256sum` del `.deb`.
3. `dpkg -x <archivo>.deb libpng12` (no necesita sudo) y copia `libpng12/lib/x86_64-linux-gnu/libpng12.so.0*` a `~/altera/13.0sp1/quartus/linux64/`.
4. `ldd ~/altera/13.0sp1/quartus/linux64/quartus | grep "not found"` no debe mostrar nada; reporta la salida.
5. Si la TAREA-025 ya creo `quartus/sintetizador.qpf`, abre `sh quartus/abrir_quartus.sh` en segundo plano, espera 60 s, revisa que el proceso siga vivo y guarda lo que haya escrito en la terminal; luego cierralo (`pkill -f "quartus --64bit"`). Si la pantalla esta bloqueada no importa: basta con que el proceso arranque sin errores.
6. Resultado en `resultados/TAREA-026.md`. Si el paso 2 o 3 falla, reporta el error tal como sale y no intentes otras fuentes.

