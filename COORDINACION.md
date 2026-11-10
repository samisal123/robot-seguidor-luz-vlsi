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

Cyclone II solo se compila con Quartus II 13.0 SP1 Web Edition (gratis, sin licencia).

1. Descargar de la pagina oficial de Intel (Software Download Center, Quartus II Web Edition 13.0 SP1, Linux) el instalador de Quartus II y el archivo de dispositivos de Cyclone (Cyclone II, III y IV). No hace falta ModelSim.
2. Instalar sin sudo en `~/altera/13.0sp1` con el archivo de dispositivos en la misma carpeta que el instalador.
3. Revisar que `~/altera/13.0sp1/quartus/bin/quartus_sh --version` responda y que la Cyclone II este instalada (por ejemplo, que exista `~/altera/13.0sp1/quartus/common/devinfo/cycloneii`).
4. USB-Blaster: si `~/altera/13.0sp1/quartus/bin/jtagconfig` no ve el cable cuando el equipo lo conecte, hace falta la regla de udev (`/etc/udev/rules.d/51-usbblaster.rules`, necesita sudo): no la instales, solo reporta el texto exacto de la regla para que el equipo la agregue.
5. En `resultados/TAREA-018.md`: que se descargo (nombres de archivo y tamanos), donde quedo instalado, la salida de `quartus_sh --version` y cualquier error tal como salio.

## TAREA-019 @claude-code: Compilar para la EP2C5T144

1. `git pull --rebase`.
2. `sh quartus/compilar.sh` (crea el proyecto para la EP2C5T144C8 con `crear_proyecto.tcl`, nivel superior `quartus/sintetizador.bdf`, y compila con Quartus II 13.0 SP1). Si falla por el `.bdf`, copia ese log a `logs/TAREA-019_bdf.log`, corre `sh quartus/compilar.sh sinte_top` (el mismo circuito en VHDL) y reporta las dos corridas. Si falla por el PLL (`quartus/ip/pll_25mhz.vhd`), reporta el error y regenera el PLL con el MegaWizard como dice el encabezado de ese archivo.
3. En `resultados/TAREA-019.md`: estado de cada etapa (Analysis & Synthesis, Fitter, Assembler, TimeQuest), errores y advertencias criticas tal como salen, el `output_files/sintetizador.fit.summary` completo, la tabla "Fitter Resource Utilization by Entity" (solo elementos logicos, registros y memoria por modulo) y Fmax y slack del reloj de 25 MHz del PLL (`output_files/sintetizador.sta.rpt`).
4. Log completo en `logs/TAREA-019.log` (copia de `logs/compilacion.log`).
5. Si la tarjeta esta conectada (`quartus_pgm -l` la muestra), **no** la programes: solo reportalo.
