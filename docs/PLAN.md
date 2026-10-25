# Plan del proyecto

## Estado

- **Actualizado:** 2026-10-25
- **Fase:** diseño digital completo; falta compilarlo en Quartus en la PC y todo lo físico.
- **Hecho:** los 20 módulos de `rtl/` (sensores, FSM de 7 estados, motores, PI, UART, VGA y el top con los 110 pines de la DE10-Lite). 19 testbenches pasan en GHDL, incluida una prueba del robot completo con modelos de los sensores (arranque, búsqueda, seguimiento, esquiva y meta). Los testbenches detectaron los 26 errores que se les metieron a propósito. `ghdl --synth` sintetiza todo sin latches. Evidencia en `resultados/TAREA-008.md`.
- **Siguiente:** compilar el diseño completo en Quartus en la PC (TAREA-009); comprar y armar ([MATERIALES.md](MATERIALES.md), [CABLEADO.md](CABLEADO.md)); calibrar y probar ([PRUEBAS_FISICAS.md](PRUEBAS_FISICAS.md)).
- **Bloqueos:** ninguno en el diseño. Falta la fecha real de entrega y los nombres del equipo.

## Objetivo

Robot de máximo 20 × 20 × 20 cm que, en una arena de 1 m × 1.7 m con obstáculos, encuentra un foco y llega a él sin chocar, de forma autónoma y repetible.

## Requisitos y cómo se cubren

| ID | Pide el enunciado | Cómo lo cumplimos | Módulos |
|---|---|---|---|
| R1 | 2 motores DC, PWM de 8 bits o más, fuera de banda audible (18 kHz o más), driver | PWM de 8 bits a 19.53 kHz (50 MHz / 10 / 256) por rueda | `pwm_8b`, `motor_if` |
| R2a | Al menos 4 LDR o fotodiodos | 4 LDR con LM339 calibrados por potenciómetro | `sync_2ff`, `ldr_dir` |
| R2b | Al menos 4 sensores ultrasónicos | 4 HC-SR04 disparados por turnos | `hcsr04`, `ultra_sched`, `obst_eval` |
| R3 | FSM principal de 5 estados o más; debounce | FSM de 7 estados; debounce en KEY y SW | `fsm_nav`, `debounce` |
| R4 | Sin avance durante N s: maniobra de escape y reintento | Atasco a los N = 3 s (genérico), estado ESCAPE | `stall_detect`, `fsm_nav` |
| R5 | Visualizar estado, % de duty y eventos | HEX5 a HEX0, LEDR y UART opcional | `seg7_disp`, `telemetry` |
| Extra | Control PI/PID de velocidad con encoders | PI por rueda | `quad_dec`, `speed_meas`, `pi_ctrl` |
| Extra | Depuración por VGA | 640 × 480 con estado, sensores y duty | `vga_debug` |

## Cronograma

| Semana | Fechas | Meta | Se da por hecha cuando |
|---|---|---|---|
| 1 | 22 al 28 oct | Propuesta, diagrama de bloques, diagrama eléctrico, plan de pruebas | Docs completos y smoke test compilando en la PC |
| 2 | 29 oct al 4 nov | Infraestructura: ticks, sincronizadores, debounce, PWM, HC-SR04, LDR, displays | Cada módulo con su testbench pasando |
| 3 | 5 al 11 nov | FSM básica, integración en chasis, seguimiento de luz | El robot gira y avanza hacia el foco sin obstáculos |
| 4 | 12 al 18 nov | Evasión de obstáculos, esquinas y atasco | Recorre la arena sin chocar y sale de un atasco forzado |
| 5 | 19 al 25 nov | Integración final y extras (PI con encoders, VGA) | Corrida completa de búsqueda a meta |
| 6 | 26 nov al 2 dic | Validación, video y reporte | 5 corridas registradas; reporte y repo listos |

La fecha real de entrega está por confirmar (TAREA-005).

## Plan de pruebas

**Nivel 1, simulación (GHDL o Questa).** Un testbench por módulo, con `assert`.

| Módulo | Casos |
|---|---|
| `tick_gen` | periodos exactos de 1 µs, 58 µs y 1 ms; pulsos de un ciclo |
| `sync_2ff` | el cambio aparece en el segundo flanco, en cualquier fase |
| `pwm_8b` | duty 0, 1, 64, 128 y 255 con ancho de pulso exacto; periodo de 51.2 µs; cambio de duty sin glitch |
| `debounce` | rebotes de 2 ms y un pulso de 15 ms se filtran; un nivel estable pasa entre 19 y 20 ms |
| `motor_if` | pausa de PAUSA_MS al invertir; nunca IN1 = IN2 = 1 |
| `hcsr04` | eco de 580 µs da 10 cm; sin eco, eco largo o ECHO pegado dan timeout y 511 |
| `seg7_disp` | los 256 duty y las distancias 0 a 511 se leen bien en los displays |
| `ultra_sched` | orden 0, 1, 2, 3 cada 30 ms; nunca dos TRIG a la vez; distancias y sin eco |
| `ldr_dir` | las 16 combinaciones de LDR; un pulso corto no pasa el filtro; luz cerca; polaridad invertida |
| `obst_eval` | umbral e histéresis de cada sensor; sin eco = libre; 0 cm = obstáculo; lado libre |
| `stall_detect` | atasco justo a los N ms; avance real lo evita; cambios de DELTA_CM y ecos intermitentes no cuentan; parado nunca |
| `fsm_nav` | arranque, búsqueda con tramo, seguimiento con cada dirección, esquiva y rodeo, esquina con y sin reversa, atasco, luz perdida, meta junto a la lámpara, giro máximo y paro con KEY0 |
| `drive_cmd` | duty final de cada acción; rampa de 8 por ms; nunca invierte una rueda en movimiento |
| `encoder_vel` | cuadratura y un canal; un cambio simultáneo de A y B no cuenta |
| `pi_ctrl` | lazo abierto; con planta 30 % más débil o 40 % más fuerte llega a la consigna; saturación |
| `uart_tx` | trama 8N1 exacta; un envío con el transmisor ocupado se ignora |
| `telemetria` | línea completa caracter por caracter; un evento dispara una línea extra con datos nuevos |
| `vga_debug` | HSYNC, línea, VSYNC y cuadro exactos; colores en zonas conocidas |
| `robot_top` | sistema completo con modelos de HC-SR04 y LDR: estados en HEX5, sentido y duty medidos en los pines del driver, LEDs y bitácora UART |

Se corren todos con `sim/correr.sh` (unos 2 minutos).

**Nivel 2, banco (FPGA en el robot, ruedas al aire).** LEDs, displays, bitácora UART y VGA muestran cada sensor en vivo; el PWM se mide con osciloscopio (frecuencia y duty). Pasos en [PRUEBAS_FISICAS.md](PRUEBAS_FISICAS.md).

**Nivel 3, robot en arena.** Seguir luz sin obstáculos, obstáculo único, esquina, atasco forzado y arena completa. Se registran 5 corridas con tiempo a la meta y número de choques.

## Entregables

| Entregable | Dónde |
|---|---|
| Repo público con código, docs, diagramas e historial de commits | este repo |
| Diagrama de bloques | Block Editor de Quartus, siguiendo el manual "Creación y uso de bloques en Quartus"; la guía está en `docs/ARQUITECTURA.md` |
| FSMs y esquemas eléctricos | `docs/` |
| Video de 5 min o menos (se graba en la entrega presencial) | enlace en el README |
| Reporte: arquitectura, FSMs, verificación, recursos, resultados y límites | `docs/reporte/` |
| Datasheets y esquemas de conexión como anexos | `docs/datasheets/` |

## Rúbrica

| Criterio | Pts | Qué lo sostiene |
|---|---|---|
| Arquitectura y estilo | 30 | Módulos pequeños con interfaz clara, un solo dominio de reloj, FSM documentada |
| Funcionalidad base | 60 | R1 a R5 estables en las pruebas de nivel 3 |
| Demo y reporte | 20 | Evidencia en `resultados/`, instrucciones de reproducción, video |
| Extras | +10 c/u | PI con encoders, VGA |

## Reparto

- Claude en la nube: RTL, testbenches y documentación.
- Claude Code en la PC: compila en Quartus, simula y reporta; desde el 2026-10-22 también puede escribir RTL y testbenches (ver `COORDINACION.md`).
- Equipo: compras, armado, cableado, calibración, pruebas físicas y video.

En la evaluación el profesor pregunta a cada integrante, así que todos deben poder explicar cada módulo. Antes de la entrega se hace un repaso completo con `docs/ARQUITECTURA.md`.
