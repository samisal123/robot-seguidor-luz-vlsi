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
- [ ] TAREA-013 @claude-code: Compilar el sintetizador en Quartus
- [ ] TAREA-014 @equipo: Comprar el material ([docs/MATERIALES.md](docs/MATERIALES.md))
- [ ] TAREA-015 @equipo: Cablear teclados y audio ([docs/CABLEADO.md](docs/CABLEADO.md))
- [ ] TAREA-016 @equipo: Pruebas en la tarjeta y ensayo de la demostración ([docs/PRUEBAS.md](docs/PRUEBAS.md))

---

## TAREA-013 @claude-code: Compilar el sintetizador en Quartus

1. `git pull --rebase`.
2. `sh quartus/compilar.sh` (crea el proyecto con `crear_proyecto.tcl`, nivel superior `quartus/sintetizador.bdf`, y compila). Si falla por el `.bdf`, copia ese log a `logs/TAREA-013_bdf.log`, corre `sh quartus/compilar.sh sinte_top` (el mismo circuito en VHDL, `rtl/sinte_top.vhd`) y reporta las dos corridas.
3. En `resultados/TAREA-013.md`: estado de cada etapa (Analysis & Synthesis, Fitter, Assembler, Timing Analyzer), los errores y advertencias críticas tal como salen, el `output_files/sintetizador.fit.summary` completo y el resumen de Fmax y slack del reloj `clk50` (`output_files/sintetizador.sta.rpt`).
4. Log completo en `logs/TAREA-013.log` (lo deja `compilar.sh` en `logs/compilacion.log`; cópialo).
5. Si la tarjeta está conectada (`quartus_pgm -l` la muestra), **no** la programes: solo repórtalo.

## TAREA-016 @equipo: Pruebas en la tarjeta

Seguir la lista de [docs/PRUEBAS.md](docs/PRUEBAS.md#pruebas-en-la-tarjeta) y anotar en `resultados/TAREA-016.md` cada prueba con OK o lo que se observó. Grabar el video de la demostración siguiendo el guion.
