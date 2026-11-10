# Plan del proyecto

## Estado

- **Actualizado:** 2026-11-10
- **Proyecto:** sintetizador musical digital (cambio de tema del 26 de octubre; el robot seguidor de luz queda en el historial de git hasta el commit `9a4ae0c`).
- **Hecho:** diseño digital completo en `rtl/` y verificado en simulación (ver [PRUEBAS.md](PRUEBAS.md)): un testbench por módulo más la prueba del sistema completo con modelos de los teclados. Nivel superior como diagrama de bloques (`quartus/sintetizador.bdf`) y como VHDL estructural (`rtl/sinte_top.vhd`).
- **Cambio de tarjeta (9 de noviembre):** la tarjeta del equipo es una EP2C5T144 (Cyclone II, 4 608 elementos lógicos), no la DE10-Lite. El diseño se ajustó: reloj de 25 MHz con PLL, tablas en bloques M4K, búsqueda de notas en serie, eco de 84 ms, botones MODO, ACCIÓN y METRÓNOMO, los 3 LEDs de la tarjeta y la VGA de 8 colores como interfaz principal (sin displays; la VGA y los botones se quitaron el 10 de noviembre).
- **Ajuste de recursos (9 de noviembre):** la primera estimación con Quartus (MAX 10) dio 5 431 elementos lógicos contra 4 608, inflada porque esa MAX 10 no aceptó las tablas con contenido inicial y las armó con lógica. Se rehízo el ADSR con un solo sumador y sin divisor, la fuente de la VGA pasó a un bloque M4K y la VGA calcula las notas de las voces en serie; con las tablas en memoria la estimación quedó en 3 805 elementos lógicos, el 83 % de la EP2C5 (TAREA-021).
- **Compilado para la EP2C5 (9 de noviembre):** Quartus II 13.0 SP1 compila el diagrama de bloques sin errores ni advertencias críticas: 3 782 elementos lógicos (82 %), 63 % de la memoria y el reloj de 25 MHz con 12.3 ns de margen ([PRUEBAS.md](PRUEBAS.md#resultado-de-la-compilación)).
- **Tarjeta programada (10 de noviembre):** el USB-Blaster ya carga el diseño en la EP2C5T144 por JTAG ([logs/programacion_tarjeta.log](../logs/programacion_tarjeta.log)).
- **Sin VGA ni botones (10 de noviembre):** el equipo decidió no comprar más material. MODO, ACCIÓN, METRÓNOMO y VOLUMEN pasaron a las teclas A a D del teclado 2 (las 24 teclas de nota se quedan) y los 3 LEDs muestran el modo y, en configuración, el parámetro elegido. Se quitó la interfaz VGA, que era uno de los extras: la calificación máxima posible queda en 120 (base más polifonía y efectos).
- **Siguiente:** compilar y repetir las capturas sin VGA (TAREA-029), armar el PDF del primer avance, comprar protoboard y jumpers ([MATERIALES.md](MATERIALES.md)), cablear ([CABLEADO.md](CABLEADO.md)) y hacer las pruebas en la tarjeta ([PRUEBAS.md](PRUEBAS.md#pruebas-en-la-tarjeta)).

## Requisitos y cómo se cubren

| # | Pide la especificación | Cómo se cumple | Módulos |
|---|---|---|---|
| 1 | FPGA libre, arquitectura en VHDL | EP2C5T144 (Cyclone II); todo el diseño en VHDL-93 | todos |
| 2 | Botones físicos, al menos dos octavas cromáticas | 2 teclados 4 × 4: 24 notas cromáticas a la vez (octava base y la siguiente), octava base de 2 a 6 | `interfaz_teclados`, `teclado_scan`, `teclas_notas` |
| 3 | Notas por DDS, al menos un acumulador de fase, cambio de nota en operación | Un acumulador de fase de 24 bits por voz; la nota solo cambia el incremento | `dds`, `voz` |
| 4 | Al menos cuadrada y triangular, seleccionables en operación | Cuadrada, triangular, sierra y seno; tecla C del teclado 1 o modo configuración | `forma_onda`, `control` |
| 5 | ADSR con 4 attack, 4 decay, 4 sustain y 4 release, modificables en operación | 4 valores de cada uno en modo configuración; A, D y R son tiempos, S es nivel | `adsr`, `control` |
| 6 | Volumen digital independiente del ADSR, 4 niveles más silencio | Volumen 0 (silencio) a 4 después de la mezcla y los efectos | `volumen`, `control` |
| 7 | Modos interpretación, grabación, reproducción y configuración | La tecla MODO (A del teclado 2) los recorre; ACCIÓN (B) es la acción del modo | `control` |
| 8 | Secuenciador de al menos 64 eventos (nota o silencio con su tiempo); iniciar y finalizar grabación, iniciar y detener reproducción; regresar a espera | 256 eventos en RAM interna, con notas, acordes y silencios en ms; FSM con estado de espera | `secuenciador`, `memoria_eventos` |
| 9 | Metrónomo independiente, encender y apagar, 4 tempos, en interpretación y grabación, audible y distinto de las notas | Tecla METRÓNOMO (C del teclado 2), tempo en configuración; 60, 90, 120 y 150 BPM; clic de 2 kHz (3 kHz en el acento) que no pasa por efectos ni volumen | `metronomo`, `audio_salida` |
| 10 | Interfaz con controles e indicadores claros | Teclas de función con una sola función por modo; los 3 LEDs muestran el modo, si graba o reproduce, el metrónomo y el parámetro en configuración | `control`, `leds_estado` |
| 11 | Salida por bocina; audio generado y controlado en la FPGA | PWM de 8 bits, filtro RC, PAM8403 y bocina; todo el procesamiento es digital | `salida_pwm`, `audio_salida` |
| +10 | Polifonía de 3 voces, cada una con su DDS y su ADSR, mezcladas antes de la salida | 3 voces y gestor de voces; el metrónomo no cuenta como voz | `gestor_voces`, `voz`, `mezclador` |
| +10 | Efecto digital | Trémolo (LFO de 5 Hz) y eco (84 ms, realimentación 1/2) | `tremolo`, `eco` |

## Entregas

El curso pide dos avances y la entrega final (en Classroom el primer avance no tiene fecha límite). Se reparten siguiendo el cronograma sugerido de la especificación:

| Entrega | Contenido | Evidencia |
|---|---|---|
| Primer avance | Arquitectura (semana 1 del cronograma): diagrama de bloques en Quartus con un símbolo por módulo, jerarquía, interfaces, asignación de pines de la EP2C5, FSM y estrategia de verificación; el proyecto compila y cabe en la EP2C5 | PDF en LaTeX con capturas de Quartus, diagramas de bloques y la programación de la tarjeta (`entregas/primer_avance/`) y liga al repositorio |
| Segundo avance | Sonido funcionando en la tarjeta (semanas 2 a 4): teclados, 3 voces DDS con ADSR, formas de onda, volumen, metrónomo y efectos | video corto en la tarjeta y gráficas de simulación |
| Final | Sistema completo (semanas 5 y 6): modos, secuenciador, reporte y demostración en vivo | reporte, repositorio y demostración |

## Plan de entrega

| Paso | Quién | Se da por hecho cuando |
|---|---|---|
| Comprar material | equipo | todo lo de [MATERIALES.md](MATERIALES.md) en mano |
| Compilar en Quartus II 13.0 SP1 y programar | PC del laboratorio | `quartus/compilar.sh` sin errores, el diseño cabe en la EP2C5 y `quartus/programar.sh` carga la tarjeta |
| Cablear teclados y audio | equipo | revisión de [CABLEADO.md](CABLEADO.md) completa |
| Pruebas en la tarjeta | equipo | lista de [PRUEBAS.md](PRUEBAS.md#pruebas-en-la-tarjeta) completa |
| Reporte | equipo | capítulos que pide la especificación, con las simulaciones de `docs/img/` y la evidencia de pruebas |
| Demostración | equipo | guion de [PRUEBAS.md](PRUEBAS.md#guion-de-la-demostración) ensayado |
