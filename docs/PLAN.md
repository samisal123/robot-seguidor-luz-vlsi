# Plan del proyecto

## Estado

- **Actualizado:** 2026-10-27
- **Proyecto:** sintetizador musical digital (cambio de tema del 26 de octubre; el robot seguidor de luz queda en el historial de git hasta el commit `9a4ae0c`).
- **Hecho:** diseño digital completo en `rtl/` y verificado en simulación (ver [PRUEBAS.md](PRUEBAS.md)): un testbench por módulo más la prueba del sistema completo con modelos de los teclados. Nivel superior como diagrama de bloques (`quartus/sintetizador.bdf`) y como VHDL estructural (`rtl/sinte_top.vhd`).
- **Siguiente:** compilar en Quartus en la PC del laboratorio, comprar el material ([MATERIALES.md](MATERIALES.md)), cablear ([CABLEADO.md](CABLEADO.md)) y hacer las pruebas en la tarjeta ([PRUEBAS.md](PRUEBAS.md#pruebas-en-la-tarjeta)).

## Requisitos y cómo se cubren

| # | Pide la especificación | Cómo se cumple | Módulos |
|---|---|---|---|
| 1 | FPGA libre, arquitectura en VHDL | DE10-Lite (MAX 10); todo el diseño en VHDL-93 | todos |
| 2 | Botones físicos, al menos dos octavas cromáticas | 2 teclados 4 × 4: 24 notas cromáticas a la vez (octava base y la siguiente), octava base de 2 a 6 | `interfaz_teclados`, `teclado_scan`, `teclas_notas` |
| 3 | Notas por DDS, al menos un acumulador de fase, cambio de nota en operación | Un acumulador de fase de 24 bits por voz; la nota solo cambia el incremento | `dds`, `voz` |
| 4 | Al menos cuadrada y triangular, seleccionables en operación | Cuadrada, triangular, sierra y seno; tecla C del teclado 1 o modo configuración | `forma_onda`, `control` |
| 5 | ADSR con 4 attack, 4 decay, 4 sustain y 4 release, modificables en operación | 4 valores de cada uno en modo configuración; A, D y R son tiempos, S es nivel | `adsr`, `control` |
| 6 | Volumen digital independiente del ADSR, 4 niveles más silencio | Volumen 0 (silencio) a 4 después de la mezcla y los efectos | `volumen`, `control` |
| 7 | Modos interpretación, grabación, reproducción y configuración | SW9-SW8 eligen el modo; KEY0 es la acción del modo | `control`, `entradas_placa` |
| 8 | Secuenciador de al menos 64 eventos (nota o silencio con su tiempo); iniciar y finalizar grabación, iniciar y detener reproducción; regresar a espera | 256 eventos en RAM interna, con notas, acordes y silencios en ms; FSM con estado de espera | `secuenciador`, `memoria_eventos` |
| 9 | Metrónomo independiente, encender y apagar, 4 tempos, en interpretación y grabación, audible y distinto de las notas | KEY1; 60, 90, 120 y 150 BPM; clic de 2 kHz (3 kHz en el acento) que no pasa por efectos ni volumen | `metronomo`, `audio_salida` |
| 10 | Interfaz con controles e indicadores claros | Displays, LEDs y pantalla VGA | `display_hex`, `leds_estado`, `vga_ui` |
| 11 | Salida por bocina; audio generado y controlado en la FPGA | PWM de 8 bits, filtro RC, PAM8403 y bocina; todo el procesamiento es digital | `salida_pwm`, `audio_salida` |
| +10 | Polifonía de 3 voces, cada una con su DDS y su ADSR, mezcladas antes de la salida | 3 voces y gestor de voces; el metrónomo no cuenta como voz | `gestor_voces`, `voz`, `mezclador` |
| +10 | Efecto digital | Trémolo (LFO de 5 Hz) y eco (168 ms, realimentación 1/2) | `tremolo`, `eco` |
| +10 | Interfaz gráfica VGA | 640 × 480: modo, metrónomo, piano con las notas que suenan, parámetros, forma de onda, voces y secuenciador | `vga_ui` |

## Plan de entrega

| Paso | Quién | Se da por hecho cuando |
|---|---|---|
| Comprar material | equipo | todo lo de [MATERIALES.md](MATERIALES.md) en mano |
| Compilar en Quartus y programar | PC del laboratorio | `quartus/compilar.sh` sin errores y `quartus/programar.sh` carga la tarjeta |
| Cablear teclados y audio | equipo | revisión de [CABLEADO.md](CABLEADO.md) completa |
| Pruebas en la tarjeta | equipo | lista de [PRUEBAS.md](PRUEBAS.md#pruebas-en-la-tarjeta) completa |
| Reporte | equipo | capítulos que pide la especificación, con las simulaciones de `docs/img/` y la evidencia de pruebas |
| Demostración | equipo | guion de [PRUEBAS.md](PRUEBAS.md#guion-de-la-demostración) ensayado |
