# Robot móvil seguidor de luz con evasión de obstáculos

Proyecto final de Diseño Digital VLSI (Facultad de Ingeniería, UNAM). Un robot de máximo 20 × 20 × 20 cm encuentra un foco en una arena de 1 m × 1.7 m con obstáculos y llega a él de forma autónoma. Toda la lógica de control está en VHDL sobre una FPGA MAX 10 (tarjeta DE10-Lite).

## Estado

Semana 2: módulos de infraestructura (ticks, sincronizador, debounce, PWM, interfaz de motor, HC-SR04 y displays), cada uno con testbench pasando en GHDL y sintetizando en Quartus. Detalle en [docs/PLAN.md](docs/PLAN.md#estado) y evidencia en [resultados/](resultados/).

## Estructura

| Carpeta | Contenido |
|---|---|
| `rtl/` | VHDL sintetizable, un módulo por archivo |
| `sim/` | Testbenches (GHDL o Questa) |
| `quartus/` | Script que genera el proyecto, restricciones de tiempo y pines |
| `docs/` | Plan, arquitectura, hardware, datasheets y figuras del reporte |
| `resultados/`, `logs/` | Evidencia de compilaciones y simulaciones |
| `tools/` | Automatización del flujo de trabajo |

## Cómo reproducir

Requisitos: Quartus Prime Lite con soporte para MAX 10, y Questa, ModelSim o GHDL para simular.

```bash
git clone https://github.com/samisal123/robot-seguidor-luz-vlsi.git
cd robot-seguidor-luz-vlsi/quartus
quartus_sh -t crear_proyecto.tcl                     # genera robot.qpf y robot.qsf
quartus_sh --flow compile robot                      # síntesis, fitter y bitstream
quartus_pgm -m jtag -o "p;output_files/robot.sof"    # programa la DE10-Lite
```

Después de correr el script, el proyecto también se abre en la interfaz de Quartus con `quartus/robot.qpf`.

Simulación con GHDL (todos los testbenches, o solo los que se nombren):

```bash
sim/correr.sh
sim/correr.sh pwm_8b hcsr04
```

## Documentación

- [Plan, cronograma y pruebas](docs/PLAN.md)
- [Arquitectura y FSM](docs/ARQUITECTURA.md)
- [Hardware y conexiones](docs/HARDWARE.md)

## Equipo

Por completar.
