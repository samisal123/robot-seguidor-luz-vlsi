# Pruebas

## Estrategia de verificación

Cada módulo se verifica solo antes de integrarlo, y luego el sistema completo:

1. **Un testbench por módulo** (GHDL) que revisa con `assert` lo que pide la especificación: tiempos exactos, valores esperados, casos límite y entradas al azar con invariantes. Si un `assert` falla, el testbench falla; no se revisan ondas a ojo.
2. **Prueba del sistema completo** desde el reloj de 50 MHz de la tarjeta (con un modelo del PLL) y modelos eléctricos de los dos teclados: mide la frecuencia en la salida de audio y revisa los modos, el secuenciador, el metrónomo y los LEDs.
3. **Pruebas de mutación**: se meten errores a propósito en copias del código y cada uno debe hacer fallar su testbench; así se comprueba que las pruebas sí detectan errores.
4. **Síntesis**: `ghdl --synth` sin latches y la estimación y compilación en Quartus (recursos, tiempos y pines de la EP2C5).
5. **Pruebas en la tarjeta** con una lista de comprobación por requisito (abajo) y el guion de la demostración.

## Simulación (GHDL)

Cada módulo de `rtl/` tiene su testbench en `sim/` y además hay una prueba del sistema completo. Todos verifican con `assert ... severity error` (no basta con ver ondas) y terminan con `report "tb_<modulo>: OK"`.

```bash
sh sim/correr.sh                  # todos los testbenches
sh sim/correr.sh secuenciador     # uno solo
```

| Testbench | Qué revisa |
|---|---|
| `tb_base_tiempo` | a 25 MHz: `tick_fs` cada 512 ciclos y `tick_1ms` cada 1 ms exactos, pulsos de un ciclo, reset a mitad de cuenta |
| `tb_reset_encendido` | `rst` en alto mientras el PLL no se engancha; baja a los 18 flancos del enganche; el botón RESET lo sube mientras está presionado; se vuelve a subir si el PLL se desengancha |
| `tb_sync_2ff` | sincronizador de 2 flip-flops: arranca en su valor inicial, un cambio asíncrono aparece en el segundo flanco (en varias fases respecto al reloj) y cada bit es independiente |
| `tb_teclado_scan` | una sola fila activa en orden; tiempo de antirrebote en las 4 fases del barrido; rebotes rechazados; las 32 teclas en su bit; varias teclas a la vez; reset |
| `tb_interfaz_teclados` | con modelos de teclado en los pines: filas solo en `'0'` o `'Z'`, las 32 teclas, dos teclas de la misma columna |
| `tb_teclas_notas` | las 24 teclas de nota en las octavas 2 a 6; pulsos de un ciclo de las 8 teclas de función; las 3 notas más graves en orden; al soltar regresa la siguiente; cambio de octava con teclas presionadas |
| `tb_dds` | fase = N · inc; no avanza sin `tick_fs`; cambio de incremento sin saltos; A4 da 440 vueltas en un segundo; afinación de las notas 24 a 95 con error menor a 0.1 % |
| `tb_forma_onda` | las 4 formas en 65 536 fases: rango, cuadrada, triangular contra la ideal (±2), sierra creciente, seno contra `sin` (±1); cambio de forma en operación (2 ciclos de latencia) |
| `tb_adsr` | los 4 tiempos de attack, de decay hasta los 4 sustain y de release (±2 %); soltar a mitad del attack; volver a presionar en el release sin caer a 0; cambio de sustain en operación |
| `tb_voz` | periodo de A4 (110.97 muestras); amplitud con sustain 255 y 128; cambio de nota y de forma sin soltar; voz inactiva da 0; la nota 0 no suena |
| `tb_gestor_voces` | reparto de notas, soltar, reuso de la voz en liberación, preferencia por voces en reposo, acorde que cambia completo y 20 000 conjuntos al azar con invariantes |
| `tb_selector_notas` | notas en vivo en espera y grabando; grabadas al reproducir |
| `tb_secuenciador` | grabación con notas, acordes y silencios con duraciones exactas; reproducción con el mismo orden y duración; posición; detener; eventos de 0 ms; memoria llena (256); nota de más de 65.5 s; cambios en el mismo ciclo que un tick |
| `tb_control` | valores iniciales; MODO (teclado 2, A) recorre los 4 modos un paso por pulsación; octava, forma, efecto y volumen directos con sus límites o vuelta; recorrido de los 7 parámetros en configuración con sus límites; METRÓNOMO; órdenes de ACCIÓN según el modo; parar al cambiar de modo; reset a interpretación |
| `tb_mezclador`, `tb_tremolo`, `tb_eco`, `tb_volumen`, `tb_metronomo`, `tb_salida_pwm`, `tb_audio_salida` | etapa de audio: mezcla y saturación exactas, LFO de 4.98 Hz, eco a 4096 muestras con mitad de amplitud, los 5 niveles de volumen, periodos de 60 a 150 BPM con acento cada 4, PWM bit a bit y la cadena completa |
| `tb_leds_estado` | D4 parpadea lento en grabación y queda fijo grabando; lo mismo D5 en reproducción; en configuración los 3 parpadean rápido con el número del parámetro (los 7); destello de 100 ms en D2 solo con el metrónomo encendido; LEDs activos en bajo |
| `tb_sinte_top` | sistema completo desde el reloj de 50 MHz (con el modelo del PLL) y dos modelos de teclado: A4 = 440 Hz medido en el PWM, acorde de 3 voces, A5 y A6 en los dos teclados, configuración con la tecla MODO (forma triangular y release, y el número del parámetro en los LEDs), grabación y reproducción con las notas en su lugar (LEDs D4 y D5 fijos), metrónomo (D2 y clic) |

### Resultado de la última corrida

9 de noviembre de 2026, GHDL 4.1.0, con el diseño para la EP2C5T144: **los 26 testbenches pasan** ([logs/sim_modulos.log](../logs/sim_modulos.log) y [logs/sim_sinte_top.log](../logs/sim_sinte_top.log)).

- La prueba del sistema simula 3.39 s de operación desde el reloj de 50 MHz y mide la frecuencia en la salida de audio con tolerancia de 0.5 %: A4 = 440 Hz, A5 = 880 Hz, A6 = 1760 Hz en el teclado 2, A4 en triangular y C4 = 261.63 Hz al reproducir. La reproducción dura lo mismo que la grabación (±2 ms) y los LEDs D2, D4 y D5 se encienden solo cuando deben.
- `ghdl --synth` del diseño completo (con el modelo del PLL en lugar del `altpll`) termina sin errores y sin latches; los avisos son atributos que solo usa Quartus (`romstyle`, `altera_attribute`) y las tablas que se leen de su valor inicial ([logs/ghdl_synth.log](../logs/ghdl_synth.log)).

### Pruebas de mutación

Para saber si los testbenches de verdad detectan errores, se metieron errores a propósito en copias del código (por ejemplo: antirrebote de 4 lecturas en vez de 5, un incremento de nota equivocado, release con el paso del decay, una voz que no se suelta, eventos de 0 ms guardados, octava máxima de 7, una tecla MODO que avanza dos modos, un LED encendido en el modo equivocado, eco a 4095 muestras) y se corrió el testbench de cada módulo. Cada error tiene que hacer fallar su testbench por un `assert` o un error en tiempo de ejecución; un error que deja de compilar no cuenta.

| Grupo | Mutaciones | Detectadas |
|---|---|---|
| Núcleo: teclados, voz, gestor de voces, secuenciador, control, LEDs, reset, base de tiempo | 52 | 52 |
| Audio: mezclador, trémolo, eco, volumen, metrónomo, PWM y cadena completa | 35 | 35 |
| **Total** | **87** | **87** |

El núcleo se volvió a correr el 10 de noviembre de 2026, ya sin VGA ni botones; las de audio son del 9 de noviembre (esos módulos no cambiaron). Con la VGA había además 62 mutaciones de `vga_ui`, todas detectadas.

Cada mutación con el mensaje con el que falló su testbench: [logs/mutacion.log](../logs/mutacion.log).

### Gráficas de simulación

`sh sim/graficas/genera.sh` corre las simulaciones de `sim/graficas/` y dibuja estas gráficas (las usa el reporte):

| Gráfica | Contenido |
|---|---|
| ![](img/sim_teclado.png) | barrido de filas, columna con rebotes y tecla filtrada |
| ![](img/sim_formas.png) | las 4 formas de onda generadas desde la fase del DDS |
| ![](img/sim_voz.png) | envolvente ADSR completa y salida de la voz en el attack y el release |
| ![](img/sim_secuenciador.png) | una melodía con acorde grabada y reproducida |
| ![](img/sim_efectos.png) | trémolo y eco |
| ![](img/sim_metronomo.png) | tiempos a 120 BPM con acento y forma del clic |
| ![](img/sim_pwm.png) | PWM y señal después del filtro RC |

## Compilación en Quartus

```bash
sh quartus/compilar.sh
```

Con Quartus II 13.0 SP1 (la última versión que soporta Cyclone II). Crea el proyecto para la EP2C5T144C8 (`crear_proyecto.tcl`), compila y muestra el resumen de recursos y la Fmax del reloj de 25 MHz. Si el diagrama de bloques diera problemas, `sh quartus/compilar.sh sinte_top` compila el mismo circuito con el nivel superior en VHDL (`rtl/sinte_top.vhd`).

`sh quartus/estimar_recursos.sh` estima los elementos lógicos con un Quartus Prime Lite más nuevo (necesita la familia MAX 10): compila para una MAX 10, que usa el mismo elemento lógico de 4 entradas, en modo de imagen única con memoria inicializada para que las tablas vayan a bloques de memoria como en la Cyclone II. Se usó mientras no se tenía la 13.0 SP1; en la PC del laboratorio ese Quartus se quitó para hacer espacio.

### Resultado de la compilación

9 de noviembre de 2026, Quartus II 13.0 SP1 Web Edition, EP2C5T144C8, nivel superior `sintetizador.bdf` ([resultados/TAREA-025.md](../resultados/TAREA-025.md), log completo en [logs/TAREA-025.log](../logs/TAREA-025.log) y reportes de Quartus en [quartus/reportes/](../quartus/reportes/)): síntesis, Fitter, ensamblador y TimeQuest terminan sin errores y sin advertencias críticas.

| Recurso | Usado | Disponible | % |
|---|---|---|---|
| Elementos lógicos | 3 782 | 4 608 | 82 % |
| Registros | 1 403 | 4 608 | 30 % |
| Bits de memoria (M4K) | 76 032 | 119 808 | 63 % |
| Multiplicadores de 9 bits | 6 | 26 | 23 % |
| PLL | 1 | 2 | 50 % |
| Pines | 30 | 89 | 34 % |

Tiempos del reloj de 25 MHz del PLL (periodo de 40 ns): Fmax de 36.05 MHz en el modelo lento, margen de setup de 12.26 ns y de hold de 0.50 ns; en el modelo rápido, 31.61 ns y 0.22 ns. Las advertencias que quedan son de la licencia gratuita (compilación paralela, LogicLock), de análisis de jitter que la familia no soporta y de capacitancia de carga en las salidas (sin efecto: las salidas tienen `set_false_path`).

Para que compilara en la 13.0 SP1 hubo dos ajustes: el PLL declara el componente `altpll` con solo los genéricos que usa, como lo escribe el MegaWizard (con la declaración de `altera_mf_components` Quartus fallaba con el error 14157), y el pin 76, que es nCEO en la Cyclone II, se libera como E/S normal (`CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION`) porque lo usa el teclado 2.

Antes de tener la 13.0 SP1, la estimación con MAX 10 dio 3 805 elementos lógicos (TAREA-021). La compilación anterior para la DE10-Lite está en `resultados/TAREA-013.md`.

## Pruebas en la tarjeta

Con la tarjeta programada (`sh quartus/programar.sh`) y todo armado según [CABLEADO.md](CABLEADO.md). Los controles son las teclas A a D del teclado 2 (MODO, ACCIÓN, METRÓNOMO, VOLUMEN). En cada paso, lo que se debe ver u oír:

| # | Acción | Resultado esperado |
|---|---|---|
| 1 | Encender la tarjeta (o presionar RESET) | LEDs D2, D4 y D5 apagados (interpretación), silencio |
| 2 | Presionar cada tecla de nota del teclado 1 | suena de C4 a B4, en orden cromático |
| 3 | Lo mismo en el teclado 2 (las 12 teclas de nota) | una octava arriba (C5 a B5) |
| 4 | Acorde de 3 teclas | suenan las 3 notas a la vez |
| 5 | A y B del teclado 1 | la octava baja y sube entre 2 y 6 |
| 6 | C del teclado 1 con una nota sostenida | cambia la forma de onda (cuadrada, triangular, sierra, seno); se oye distinto |
| 7 | D del teclado 2 varias veces | volumen 4, silencio, 1, 2, 3, 4 |
| 8 | C del teclado 2 (METRÓNOMO) | D2 destella en cada tiempo y se oye el clic (más agudo cada 4 tiempos); otra vez y se apaga |
| 9 | D del teclado 1 | efecto: trémolo (el volumen ondula), eco (repeticiones cada 84 ms), los dos, ninguno |
| 10 | A del teclado 2 tres veces (configuración) | los 3 LEDs parpadean rápido mostrando 1 (D2, forma); C y D del teclado 1 cambian el número (1 a 7); A y B cambian el valor; probar attack de 800 ms (2), release de 1.5 s (5) y tempo (7) |
| 11 | A del teclado 2 (interpretación) y otra vez (grabación) | D4 parpadea lento |
| 12 | B del teclado 2, tocar una melodía con un silencio y un acorde, B otra vez | D4 fijo mientras graba; al terminar vuelve a parpadear |
| 13 | A del teclado 2 (reproducción), B | D5 fijo; suena la melodía igual; al terminar D5 vuelve a parpadear |
| 14 | B a mitad de una reproducción | se detiene en silencio |
| 15 | Grabar más de 256 eventos (presionar y soltar muchas veces) | la grabación se detiene sola (D4 vuelve a parpadear) |
| 16 | RESET de la tarjeta | regresa al paso 1 |

## Guion de la demostración

1. Arquitectura en dos minutos: diagrama de bloques (`quartus/sintetizador.bdf` en Quartus o [ARQUITECTURA.md](ARQUITECTURA.md)), un solo reloj de 25 MHz del PLL con pulsos de habilitación, DDS + ADSR por voz, y cómo se ajustó a la EP2C5 (tablas en memoria M4K, búsqueda de notas en serie).
2. Interpretación: escala cromática en los dos teclados (dos octavas), cambio de octava, acorde de 3 notas (polifonía).
3. Formas de onda: la misma nota en cuadrada y triangular (y sierra y seno).
4. ADSR: en configuración, attack largo y release largo; luego sustain bajo.
5. Volumen: de 4 a 0 (silencio) y de regreso.
6. Metrónomo: encenderlo, cambiar tempo, notar el acento cada 4.
7. Grabación y reproducción: una melodía corta con un silencio y un acorde; reproducirla; detenerla a la mitad; reproducirla completa y ver que regresa a espera.
8. Efectos: trémolo y eco sobre notas sostenidas.
9. LEDs: cómo muestran el modo, la grabación, la reproducción y el parámetro en configuración.
10. Preguntas: tener a la mano [ARQUITECTURA.md](ARQUITECTURA.md) (FSM del ADSR y del secuenciador, organización de la memoria, cálculo de los incrementos y de los pasos del ADSR).
