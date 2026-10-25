# Robot móvil seguidor de luz con evasión de obstáculos

Proyecto final de Diseño Digital VLSI (Facultad de Ingeniería, UNAM). Un robot de máximo 20 × 20 × 20 cm encuentra un foco en una arena de 1 m × 1.7 m con obstáculos y llega a él de forma autónoma. Toda la lógica de control está en VHDL sobre una FPGA MAX 10 (tarjeta DE10-Lite).

## Qué hace

- **Sensores:** 4 LDR con comparadores LM339 para la dirección de la luz, un quinto comparador para saber cuándo llegó al foco, y 4 HC-SR04 (frente, diagonales y atrás) disparados por turnos.
- **Control:** FSM de 7 estados (INICIO, BUSCAR, SEGUIR, ESQUIVA, ESQUINA, ESCAPE, META), detección de atasco a los 3 s con maniobra de escape al azar.
- **Motores:** 2 motores DC con PWM de 8 bits a 19.53 kHz por un TB6612FNG, con rampa y pausa al invertir el giro.
- **Visualización:** estado, evento y % de duty en los displays; sensores en los LEDs; bitácora por UART a 115200.
- **Extras:** control PI de velocidad con encoders y tablero de depuración por VGA (640 × 480).

## Estado

El diseño digital está completo y verificado en simulación: 19 testbenches pasan en GHDL, incluida una prueba del robot completo con modelos de los sensores. Falta compilarlo en Quartus en la PC, armar el robot y calibrarlo en la arena. Detalle en [docs/PLAN.md](docs/PLAN.md#estado) y evidencia en [resultados/](resultados/).

## Estructura

| Carpeta | Contenido |
|---|---|
| `rtl/` | VHDL sintetizable (VHDL-93), un módulo por archivo; el top es `robot_top.vhd` |
| `sim/` | Testbenches y `correr.sh` para GHDL |
| `quartus/` | Scripts que generan y compilan el proyecto, pines y restricciones de tiempo |
| `docs/` | Plan, arquitectura y FSM, hardware, materiales, cableado y pruebas físicas |
| `resultados/`, `logs/` | Evidencia de compilaciones y simulaciones |
| `tools/` | Automatización del flujo de trabajo entre la nube y la PC |

## Cómo reproducir

Requisitos: Quartus Prime Lite con soporte para MAX 10 (se probó con 25.1std), y GHDL para simular.

```bash
git clone https://github.com/samisal123/robot-seguidor-luz-vlsi.git
cd robot-seguidor-luz-vlsi
quartus/compilar.sh     # crea el proyecto, compila y muestra recursos y Fmax
quartus/programar.sh    # carga el .sof en la DE10-Lite por USB-Blaster
```

`compilar.sh` corre `quartus_sh -t crear_proyecto.tcl` y `quartus_sh --flow compile robot`; después, el proyecto también se abre en la interfaz de Quartus con `quartus/robot.qpf`.

Simulación con GHDL (todos los testbenches, o solo los que se nombren):

```bash
sim/correr.sh
sim/correr.sh fsm_nav robot_top
```

Bitácora del robot en la PC (con un convertidor USB-TTL en el header, ver [cableado](docs/CABLEADO.md#uart-extra)):

```bash
python3 -m serial.tools.miniterm /dev/ttyUSB0 115200
```

## Uso

| Control | Función |
|---|---|
| KEY0 | Arranca o detiene el recorrido |
| KEY1 | Reset |
| SW8 | Motores habilitados (en 0, modo banco: piensa pero no se mueve) |
| SW7 | Prueba de motores: ambas ruedas adelante |
| SW2 | Control PI con encoders |
| SW9, SW1-SW0 | Displays en modo distancia del sensor elegido |

HEX5 muestra el estado (0 INICIO, 1 BUSCAR, 2 SEGUIR, 3 ESQUIVA, 4 ESQUINA, 5 ESCAPE, 6 META). Todos los controles y salidas están en [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md#interfaz-en-la-tarjeta).

## Documentación

- [Plan, cronograma y pruebas](docs/PLAN.md)
- [Arquitectura, módulos y FSM](docs/ARQUITECTURA.md)
- [Hardware y decisiones](docs/HARDWARE.md)
- [Lista de materiales con precios](docs/MATERIALES.md)
- [Cableado pin por pin](docs/CABLEADO.md)
- [Pruebas físicas y calibración](docs/PRUEBAS_FISICAS.md)

## Equipo

Por completar.
