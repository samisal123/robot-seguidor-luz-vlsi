# Plan del proyecto

## Estado

- **Actualizado:** 2026-10-22
- **Fase:** Semana 1 (propuesta y diagramas)
- **Hecho:** estructura del repo, plan, arquitectura, notas de hardware y smoke test (`rtl/robot_top.vhd`) listo para compilar; analiza limpio en VHDL-93 y su testbench `sim/tb_robot_top.vhd` pasa en GHDL 4.1.
- **Siguiente:** verificar el entorno de la PC (TAREA-002), compilar el smoke test (TAREA-003) y escribir los módulos de infraestructura (TAREA-004).
- **Bloqueos:** decisiones de hardware pendientes (TAREA-005).

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
| `pwm_8b` | duty 0, 1, 128 y 255 con ancho de pulso exacto; periodo de 51.2 µs |
| `debounce` | rebotes de 2 ms se filtran; un nivel estable de 20 ms pasa |
| `hcsr04` | eco de 580 µs da 10 cm; sin eco da timeout y distancia máxima |
| `ultra_sched` | los 4 sensores se disparan por turnos, sin traslape |
| `ldr_dir` | cada combinación de 4 bits da la dirección esperada |
| `stall_detect` | sin cambio en N s levanta atasco; con avance no |
| `fsm_nav` | luz al frente, luz atrás, obstáculo, esquina, atasco y meta |

**Nivel 2, banco (FPGA sin chasis).** LEDs y displays muestran cada sensor en vivo; el PWM se mide con osciloscopio (frecuencia y duty).

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
- Claude Code en la PC: compila, simula y reporta (ver `COORDINACION.md`).
- Equipo: compras, armado, cableado, calibración, pruebas físicas y video.

En la evaluación el profesor pregunta a cada integrante, así que todos deben poder explicar cada módulo. Antes de la entrega se hace un repaso completo con `docs/ARQUITECTURA.md`.
