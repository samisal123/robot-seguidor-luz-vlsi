# Coordinación del proyecto

Canal único entre **Claude (nube)**, que escribe código y documentación, y **Claude Code (PC local)**, que compila, simula y reporta. El equipo humano solo entra en las tareas `@equipo`.

## Cómo funciona

| Quién | Qué hace | Dónde escribe |
|---|---|---|
| `@claude-nube` | RTL, testbenches, docs; revisa resultados y crea tareas | `rtl/`, `sim/`, `quartus/`, `docs/`, este archivo |
| `@claude-code` | Ejecuta tareas en la PC (Quartus, simulador, git) | solo `resultados/` y `logs/` |
| `@equipo` | Compras, armado, cableado, calibración, pruebas físicas, video | lo que diga la tarea |

- Una tarea = una línea en la lista de abajo + una sección `## TAREA-NNN` con los pasos.
- Casillas: `[ ]` pendiente, `[x]` revisada y aceptada, `[!]` falló, `[-]` cancelada.
- Una tarea `@claude-code` cuenta como ejecutada cuando existe `resultados/TAREA-NNN.md`. La nube la revisa y cambia la casilla.
- Las tareas no se repiten: si algo falla, la nube crea una tarea nueva con otro número.
- Nadie inventa salidas. Lo que no se pudo ejecutar se reporta como FALLO con el error real.
- Mensajes de commit: `nube: ...` para la nube, `cc: ...` para Claude Code.

Claude Code sigue `tools/PROMPT_CLAUDE_CODE.md`. Lo despierta `tools/watcher.sh` (Linux) o `tools/watcher.ps1` (Windows).

**Cambio del 2026-10-22:** por indicación del equipo, Claude Code en la PC también escribe RTL, testbenches y docs (hizo TAREA-004). Las reglas de evidencia siguen igual: todo resultado sale de una ejecución real y queda en `resultados/` y `logs/`.

### Para Claude nube (cada sesión empieza sin memoria)

1. Leer `README.md`, la sección Estado de `docs/PLAN.md` y este archivo.
2. Revisar las hojas nuevas en `resultados/`, validarlas contra lo esperado y actualizar las casillas.
3. Hacer la siguiente tarea `@claude-nube` y actualizar la sección Estado de `docs/PLAN.md`.
4. Dejar como máximo 3 tareas `@claude-code` nuevas, pequeñas y verificables.
5. Lo que requiera personas va como `@equipo` y no bloquea lo demás.

## Tareas

- [x] TAREA-001 @claude-nube: Estructura del repo, plan, arquitectura, hardware y coordinación
- [x] TAREA-002 @claude-code: Verificar el entorno de la PC
- [x] TAREA-003 @claude-code: Compilar el smoke test en Quartus
- [x] TAREA-004 @claude-code: Módulos de infraestructura con testbench (hecha en la PC)
- [ ] TAREA-005 @equipo: Confirmar las decisiones pendientes de hardware
- [ ] TAREA-006 @claude-code: `ultra_sched` y `ldr_dir` con testbench
- [ ] TAREA-007 @claude-code: Top de banco (Nivel 2) con `quartus/pines.tcl`

---

## TAREA-002 @claude-code: Verificar el entorno de la PC

Solo consulta y reporta. No instales ni cambies nada.

1. `hostname`, sistema operativo (`cat /etc/os-release` o equivalente), `git --version`, `claude --version`.
2. `git config user.name`, `git config user.email` y `git remote -v`.
3. Quartus: ubica `quartus_sh` (PATH, `~/altera_lite/*/quartus/bin/`, `~/intelFPGA_lite/*/quartus/bin/`). Reporta la ruta y la salida de `quartus_sh --version`.
4. Simuladores: busca `vsim` (Questa o ModelSim, por ejemplo en `~/altera_lite/*/questa_fse/bin/` o `~/altera_lite/*/modelsim_ase/bin/`) y `ghdl`. De cada uno, ruta y versión, o "no encontrado". Si hay `vsim`, corre `vsim -c -do "quit -f"` y reporta si sale error de licencia.
5. Programador: `quartus_pgm -l` (solo lista el hardware conectado, no programa nada).

## TAREA-003 @claude-code: Compilar el smoke test en Quartus

Objetivo: confirmar que la cadena completa de Quartus funciona por línea de comandos. No programes la tarjeta.

1. `cd quartus`
2. `quartus_sh -t crear_proyecto.tcl`
3. `quartus_sh --flow compile robot`
4. Guarda la salida completa en `logs/TAREA-003.log`.
5. En la hoja de resultado: la línea final de éxito o los errores, el número de warnings y el contenido de `quartus/output_files/robot.fit.summary`.

## TAREA-004 @claude-code: Módulos de infraestructura

`tick_gen`, `sync_2ff`, `debounce`, `pwm_8b`, `motor_if`, `hcsr04` y `seg7_disp` en `rtl/`, cada uno con su testbench en `sim/`. Cada módulo se simula con `sim/correr.sh <modulo>` y se sintetiza aislado con `quartus/sintetizar_modulo.sh <modulo> [dependencias]`. Resultado en `resultados/TAREA-004.md`.

## TAREA-005 @equipo: Confirmar decisiones de hardware

Responder en la sección Decisiones pendientes de `docs/HARDWARE.md` o en el chat con Claude:

1. ¿La tarjeta es la DE10-Lite?
2. Driver: TB6612FNG (recomendado), L298N u otro.
3. ¿Los motores traen encoder?
4. Para detectar la meta: segundo LM339 o ADC de la MAX 10.
5. Fecha real de entrega y nombres del equipo.

## TAREA-006 @claude-code: `ultra_sched` y `ldr_dir`

1. `ultra_sched`: turna 4 instancias de `hcsr04` cada 30 ms (un `start` a la vez, sin traslape) y guarda las 4 distancias. Testbench: orden de disparo, separación de 30 ms y ningún traslape de TRIG.
2. `ldr_dir`: 4 bits de luz (frente, izquierda, derecha, atrás) → `dir_luz`, `hay_luz`, `luz_cerca`. Testbench: las 16 combinaciones.
3. Simular, sintetizar aislado y reportar en `resultados/TAREA-006.md`.

## TAREA-007 @claude-code: Top de banco (Nivel 2)

Depende de TAREA-005 (tarjeta y driver confirmados).

1. `quartus/pines.tcl` con KEY, SW, LEDR, HEX y GPIO según el manual de la DE10-Lite y la tabla de `docs/HARDWARE.md`.
2. Un top de banco que muestre los sensores en LEDR y HEX y saque PWM fijo por los pines de motor, para medir con osciloscopio.
3. Compilar sin el Critical Warning de pines. No programar la tarjeta sin confirmación del equipo.
