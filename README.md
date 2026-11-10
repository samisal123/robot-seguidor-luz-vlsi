# Sintetizador musical digital en FPGA

Proyecto final de Diseño Digital VLSI (Facultad de Ingeniería, UNAM). Un sintetizador que se toca con dos teclados matriciales, genera las notas por síntesis digital directa (DDS) con envolvente ADSR, graba y reproduce secuencias, tiene metrónomo y suena por una bocina. Toda la lógica está en VHDL sobre una FPGA Cyclone II (tarjeta mínima EP2C5T144); afuera solo hay un filtro RC, un amplificador PAM8403, tres botones y tres resistencias para el monitor VGA.

![Diagrama de bloques](docs/img/bloques.png)

## Qué hace

- **Teclado:** dos teclados 4 × 4, cada uno con 12 notas cromáticas (dos octavas a la vez) y 4 teclas de función. Octava base de 2 a 6.
- **Síntesis:** 3 voces simultáneas, cada una con su acumulador de fase de 24 bits (DDS) y su envolvente ADSR. Formas de onda cuadrada, triangular, sierra y seno.
- **Envolvente ADSR:** 4 tiempos de attack, 4 de decay, 4 niveles de sustain y 4 tiempos de release, modificables en operación.
- **Volumen digital:** 4 niveles más silencio, independiente de la envolvente.
- **Modos:** interpretación, grabación, reproducción y configuración (botón MODO).
- **Secuenciador:** graba hasta 256 eventos (notas, acordes y silencios con su duración en ms) en una RAM interna y los reproduce con la misma duración.
- **Metrónomo:** 60, 90, 120 y 150 BPM, con acento cada 4 tiempos y un clic que no pasa por los efectos ni el volumen.
- **Efectos:** trémolo y eco (RAM de 4096 muestras, 84 ms).
- **Interfaz:** pantalla VGA de 640 × 480 con 8 colores (el modo, un piano que muestra las notas que suenan, los parámetros, la forma de onda, las voces y el secuenciador), botones MODO, ACCIÓN y METRÓNOMO y los 3 LEDs de la tarjeta.
- **Salida:** PWM de 8 bits a 97.7 kHz, filtro RC de 2 etapas, PAM8403 y bocina de 8 Ω.
- **Reloj:** 25 MHz desde el PLL de la Cyclone II (oscilador de 50 MHz de la tarjeta).

Características de nivel implementadas: polifonía de tres voces, efectos digitales (trémolo y eco) e interfaz gráfica VGA.

**Estado:** verificado en simulación (26 testbenches y 145 de 145 errores a propósito detectados) y compilado en Quartus II 13.0 SP1 para la EP2C5T144C8: 3 782 elementos lógicos (82 %), 63 % de la memoria y el reloj de 25 MHz con 12.3 ns de margen. Falta armarlo y probarlo en la tarjeta.

## Estructura

| Carpeta | Contenido |
|---|---|
| `rtl/` | VHDL sintetizable (VHDL-93), un módulo por archivo |
| `sim/` | Un testbench por módulo, prueba del sistema completo, modelos y `correr.sh` para GHDL |
| `quartus/` | Scripts que crean y compilan el proyecto, diagrama de bloques del nivel superior (`sintetizador.bdf`), símbolos, PLL (`ip/`), pines, restricciones de tiempo y reportes de la compilación (`reportes/`) |
| `docs/` | Arquitectura y FSM, módulos e interfaces, cableado, materiales, pruebas y diagramas |
| `tools/` | `genera_top.py`, que genera el nivel superior (`.bdf` y `.vhd`) |

## Cómo reproducir

Requisitos: Quartus II 13.0 SP1 Web Edition (la última versión con Cyclone II), un USB-Blaster y GHDL para simular.

```bash
git clone https://github.com/samisal123/robot-seguidor-luz-vlsi.git
cd robot-seguidor-luz-vlsi
sh quartus/compilar.sh     # crea el proyecto, compila y muestra recursos y Fmax
sh quartus/programar.sh    # carga el .sof en la EP2C5T144 por USB-Blaster (JTAG)
sh quartus/grabar_flash.sh # opcional: lo graba en la EPCS4 para que arranque solo
```

`compilar.sh` corre `quartus_sh -t crear_proyecto.tcl` y `quartus_sh --flow compile sintetizador`. Después el proyecto se abre en la interfaz de Quartus con `quartus/sintetizador.qpf`; el nivel superior es el diagrama de bloques `sintetizador.bdf`.

Simulación con GHDL (todos los testbenches, o solo los que se nombren):

```bash
sh sim/correr.sh
sh sim/correr.sh secuenciador adsr
```

## Documentación

- [Arquitectura, módulos y máquinas de estados](docs/ARQUITECTURA.md)
- [Módulos e interfaces: descripción y puertos de cada módulo](docs/MODULOS.md)
- [Cableado: teclados, botones, audio y VGA](docs/CABLEADO.md)
- [Materiales](docs/MATERIALES.md)
- [Pruebas: simulación, compilación y pruebas en la tarjeta](docs/PRUEBAS.md)

## Uso rápido

| Control | Función |
|---|---|
| MODO | interpretación → grabación → reproducción → configuración → interpretación |
| ACCIÓN | grabación: iniciar / finalizar; reproducción: iniciar / detener |
| METRÓNOMO | metrónomo encendido / apagado |
| RESET (en la tarjeta) | reinicia el sintetizador |
| Teclado 1, A B C D | octava −, octava +, forma siguiente, efecto siguiente |
| Teclado 2, A B C D | volumen −, volumen +, tempo −, tempo + |
| Configuración | A / B cambian el valor, C / D eligen el parámetro (forma, attack, decay, sustain, release, volumen, tempo, efecto) |
