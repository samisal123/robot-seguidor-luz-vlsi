# Arquitectura del sintetizador

## Decisiones de diseño

1. **Un solo reloj de 25 MHz.** El PLL de la Cyclone II lo saca de los 50 MHz del oscilador de la tarjeta y deja margen de tiempo en la EP2C5T144C8, que es de grado de velocidad 8 (el más lento). Los tiempos lentos salen de pulsos de habilitación de un ciclo de `base_tiempo`: `tick_fs` cada 512 ciclos (la muestra de audio, Fs = 48 828.125 Hz) y `tick_1ms`. No hay relojes divididos ni cruces de dominio. El sistema arranca en reset hasta que el PLL se engancha.
2. **Toda entrada externa pasa por un sincronizador de 2 flip-flops** (columnas de los teclados y botón RESET) y las teclas pasan después por un antirrebote.
3. **Un módulo por archivo, un testbench por módulo**, más una prueba del sistema completo con modelos de los teclados (ver [PRUEBAS.md](PRUEBAS.md)).
4. **Puertos solo `std_logic` y `std_logic_vector`**, para que Quartus genere el símbolo de cada módulo y el nivel superior sea un diagrama de bloques (`quartus/sintetizador.bdf`), como en el material del curso "Creación y uso de bloques en Quartus". Los códigos de modos, estados, formas de onda y efectos tienen nombre en `rtl/synth_pkg.vhd`.
5. **Los parámetros cambian en operación** (forma de onda, envolvente, volumen, tempo, efecto, octava): son registros de `control`, no constantes; no hace falta volver a sintetizar.
6. **Cadenas largas en etapas registradas**: la multiplicación de cada voz, y la cadena de audio (9 ciclos de 512 disponibles por muestra).
7. **Ajuste a la EP2C5 (4 608 elementos lógicos, 26 bloques M4K de 4 Kbit, 13 multiplicadores de 18 × 18).** Las tablas grandes van en bloques de memoria en lugar de lógica: incrementos de las notas y seno de cada voz, línea de retardo del eco y memoria de eventos. El ADSR de cada voz usa un solo sumador/restador y un comparador. La búsqueda de las 3 notas presionadas se hace en serie, una tecla por ciclo, con un solo sumador. Los productos usan los multiplicadores embebidos.
8. **Sin material extra para el control.** La tarjeta no tiene displays, switches ni más botones que RESET: los controles (MODO, ACCIÓN, METRÓNOMO y volumen) van en las teclas A a D del teclado 2 y el modo y el estado se ven en los 3 LEDs de la tarjeta. Así se conservan las 24 teclas de nota (dos octavas cromáticas) y no hacen falta botones ni conector de video. La interfaz VGA (uno de los extras opcionales) se quitó por esa razón.

## Diagrama de bloques

![Diagrama de bloques](img/bloques.png)

El nivel superior existe en dos formas equivalentes, generadas por `tools/genera_top.py` a partir de una sola descripción de la red:

- `quartus/sintetizador.bdf`: diagrama de bloques del Block Editor, nivel superior del proyecto de Quartus.
- `rtl/sinte_top.vhd`: el mismo circuito en VHDL estructural, para simular el sistema completo con GHDL.

| Bloque | Archivo | Función |
|---|---|---|
| PLL | `quartus/ip/pll_25mhz.vhd` (simulación: `sim/modelo_pll.vhd`) | 50 MHz de la tarjeta a 25 MHz y señal de enganche |
| Reset del sistema | `reset_encendido.vhd` | `rst` hasta 16 ciclos después de que el PLL se engancha y mientras se presiona RESET |
| Base de tiempo | `base_tiempo.vhd` | `tick_fs` (48 828 Hz) y `tick_1ms` |
| Interfaz de teclados | `interfaz_teclados.vhd`, `teclado_scan.vhd` | barrido de los dos teclados 4 × 4, filas en colector abierto, antirrebote de 20 ms por tecla |
| Teclas a notas | `teclas_notas.vhd` | hasta 3 notas presionadas (búsqueda en serie) y pulsos de las teclas A-D |
| Unidad de control | `control.vhd` | modo de operación, parámetros del sonido y órdenes al secuenciador |
| Secuenciador | `secuenciador.vhd`, `memoria_eventos.vhd` | graba y reproduce hasta 256 eventos |
| Selector | `selector_notas.vhd` | notas en vivo o grabadas hacia las voces |
| Gestor de voces | `gestor_voces.vhd` | reparte hasta 3 notas entre 3 voces |
| Voz (× 3) | `voz.vhd`, `dds.vhd`, `forma_onda.vhd`, `adsr.vhd` | DDS, forma de onda, envolvente ADSR y producto |
| Salida de audio | `audio_salida.vhd`, `mezclador.vhd`, `tremolo.vhd`, `eco.vhd`, `volumen.vhd`, `metronomo.vhd`, `salida_pwm.vhd` | mezcla, efectos, volumen, metrónomo y PWM |
| LEDs | `leds_estado.vhd` | modo, estado del secuenciador, parámetro elegido y tiempo del metrónomo en los 3 LEDs de la tarjeta |

## Entradas

### Teclados

Dos teclados de membrana 4 × 4. Las tres primeras columnas tocan notas en orden cromático y la cuarta son funciones (las del teclado 2 son los controles del sintetizador):

```
 1  2  3  A        C   C#  D   | A
 4  5  6  B   ->   D#  E   F   | B
 7  8  9  C        F#  G   G#  | C
 *  0  #  D        A   A#  B   | D
```

El teclado 1 toca la octava base (2 a 6, inicia en 4) y el teclado 2 la siguiente: **dos octavas cromáticas completas** a la vez, y con las teclas de octava se recorre de C2 a B7.

`teclado_scan` activa una fila por milisegundo en los dos teclados a la vez (`'0'` en la fila activa, alta impedancia en las demás) y lee las 8 columnas, que tienen pull-up. Cada una de las 32 teclas tiene su propio antirrebote: cambia de estado tras 5 lecturas seguidas iguales (20 ms). Como el teclado no tiene diodos, tres teclas en esquinas de un rectángulo producen una cuarta fantasma; con acordes de 3 notas de teclados distintos o filas distintas no pasa.

`teclas_notas` convierte el estado de las teclas en:

- `notas`: hasta 3 notas pedidas, de grave a aguda (7 bits cada una, `n = 12 · octava + semitono`, A4 = 57, 0 = vacía). Con más de 3 teclas se quedan las 3 más graves.
- `func`: pulso de un ciclo al presionar A, B, C o D de cada teclado.

La búsqueda es en serie: cada 25 ciclos toma una foto de las 24 teclas de nota y la octava, y en los 24 ciclos siguientes revisa una tecla por ciclo, de la más grave a la más aguda, guardando `12 · octava + j` en el siguiente lugar libre. Con un solo sumador hace lo que en paralelo pedía 24 comparaciones; la vuelta dura 1 µs y las teclas cambian cada milisegundo.

### Controles

| Control | Función |
|---|---|
| Teclado 2, A: MODO | pasa al siguiente modo: interpretación → grabación → reproducción → configuración → interpretación |
| Teclado 2, B: ACCIÓN | en grabación inicia o finaliza; en reproducción inicia o detiene |
| Teclado 2, C: METRÓNOMO | enciende o apaga el metrónomo |
| Teclado 2, D: VOLUMEN | siguiente nivel de volumen: silencio, 1, 2, 3, 4 y otra vez silencio |
| RESET (pin 144, en la tarjeta) | reinicia todo el sistema |

## Unidad de control

![Modos de operación](img/modos.png)

`control` lleva el modo, guarda los parámetros y decide qué hace cada tecla de función según el modo:

| Tecla | Interpretación, grabación y reproducción | Configuración |
|---|---|---|
| Teclado 1, A / B | octava − / + (2 a 6) | valor − / + del parámetro elegido |
| Teclado 1, C | siguiente forma de onda | parámetro anterior |
| Teclado 1, D | siguiente efecto | parámetro siguiente |
| Teclado 2, A | MODO | MODO |
| Teclado 2, B | ACCIÓN | sin efecto |
| Teclado 2, C | METRÓNOMO | METRÓNOMO |
| Teclado 2, D | volumen siguiente | volumen siguiente |

Parámetros (en configuración se recorren en este orden):

| LEDs | Parámetro | Valores (0 a 3, o 0 a 4) | Inicial |
|---|---|---|---|
| 1 | Forma | cuadrada, triangular, sierra, seno | cuadrada |
| 2 | Attack | 2, 50, 200, 800 ms | 2 ms |
| 3 | Decay | 50, 200, 600, 1500 ms | 200 ms |
| 4 | Sustain | 25, 50, 75, 100 % | 75 % |
| 5 | Release | 20, 150, 500, 1500 ms | 150 ms |
| 6 | Volumen | silencio, 25, 50, 75, 100 % | 75 % |
| 7 | Tempo | 60, 90, 120, 150 BPM | 120 BPM |

El efecto (ninguno, trémolo, eco o los dos; inicial: ninguno) se cambia con su tecla directa, la D del teclado 1. Attack, decay y release son tiempos de escala completa (de 0 a 255 o al revés); sustain es un nivel. En configuración los valores se quedan en sus límites; con las teclas directas, forma, efecto y volumen dan la vuelta. La columna LEDs es el número que muestran los LEDs en configuración.

Órdenes al secuenciador: ACCIÓN en grabación manda `cmd_grabar` (si está en espera) o `cmd_parar` (si graba); en reproducción, `cmd_reproducir` o `cmd_parar`. Cambiar de modo a mitad de una grabación o reproducción también manda `cmd_parar`. El metrónomo suena en interpretación y grabación y se calla mientras se reproduce una secuencia.

## Secuenciador y memoria

Un **evento** es un conjunto de notas que se mantuvo igual (hasta 3 notas, o silencio si no hay ninguna) y su duración en milisegundos. Así quedan grabadas notas, acordes y silencios con sus duraciones, en orden.

Formato de cada palabra de `memoria_eventos` (RAM de 256 × 37 bits, 3 bloques M4K en modo 256 × 18):

| Bits | Contenido |
|---|---|
| 36..30 | nota 3 (0 = vacía) |
| 29..23 | nota 2 |
| 22..16 | nota 1 |
| 15..0 | duración en ms (1 a 65 535) |

Capacidad: 256 eventos (la especificación pide 64). Un evento de más de 65.5 s se guarda como dos.

![FSM del secuenciador](img/fsm_secuenciador.png)

- **ESPERA**: salida en silencio. `cmd_grabar` borra la secuencia anterior y pasa a GRABANDO; `cmd_reproducir` con eventos guardados pasa a LEER.
- **GRABANDO**: cuando cambia el conjunto de notas, guarda el evento que termina (notas y ms) y empieza a medir el siguiente. `cmd_parar` guarda el último y vuelve a ESPERA; al guardar el evento 256 (memoria llena) también.
- **LEER → CARGAR → TOCAR**: lee el evento, pone sus notas en la salida y espera su duración; luego el siguiente. Después del último, la salida queda en silencio y regresa a ESPERA.

La base de tiempo del secuenciador es un contador libre de milisegundos (`t_ms`); `inicio` guarda el milisegundo en que empezó el evento actual y la duración es `t_ms - inicio`. Al reproducir, el evento siguiente empieza en `inicio + duración`, así la latencia de la máquina (2 ciclos por evento) no pierde ticks ni acumula error: la reproducción dura exactamente lo que la grabación (verificado en simulación).

En reproducción las voces toman las notas del secuenciador (`selector_notas`); lo que se toque encima no suena. Los parámetros del sonido sí se pueden cambiar mientras se reproduce.

## Generación de audio

### Voces

Hay **3 voces independientes** (polifonía), cada una con su DDS y su ADSR:

```
nota -> ROM de incrementos -> DDS (24 bits) -> forma_onda --+
                                                             x -> muestra (8 bits con signo)
gate ------------------------------> ADSR (24 bits) --------+
```

**DDS.** Un acumulador de fase de 24 bits suma un incremento en cada muestra: `fase = fase + inc (mod 2^24)`. La frecuencia es `f = inc · Fs / 2^24`, con resolución de 0.0029 Hz. Los incrementos de las 12 notas de la octava 7 están en `synth_pkg` (`inc = f · 2^24 / Fs`, por ejemplo B7: 3951.07 Hz → 1 357 576); las octavas de abajo se obtienen dividiendo entre 2 por octava. Con eso se arma una ROM de 128 incrementos de 24 bits, que va en un bloque M4K de cada voz (lectura registrada). El error máximo contra la afinación temperada (A4 = 440 Hz) es menor a 0.01 %. Cambiar de nota solo cambia el incremento; la fase sigue sin saltos.

**Formas de onda** (de los bits altos de la fase, sin memoria salvo el seno):

| Forma | Cálculo |
|---|---|
| Cuadrada | +127 si `fase(23) = 0`, −127 si no |
| Triangular | `fase(22..15) − 128` subiendo en la primera mitad, `127 − fase(22..15)` bajando en la segunda |
| Sierra | `fase(23..16) − 128` |
| Seno | tabla de 256 puntos indexada con `fase(23..16)`, en un bloque M4K |

`forma_onda` es una tubería de 2 etapas: en la primera se lee la ROM del seno y se registran la fase y la forma; en la segunda se elige la muestra.

**Envolvente ADSR.** Acumulador de 24 bits; el nivel son sus 8 bits altos (0 a 255). Avanza una vez por muestra con un paso por etapa: para recorrer la escala completa en T ms, `paso = 2^24 / (T · Fs / 1000) = 343 597 / T`.

Cada voz tiene su propio ADSR con un solo sumador/restador: en cada muestra la etapa elige el paso, el sentido (sube en el ataque, y en el sostenido si el nivel está debajo del sustain) y la meta (el máximo, el sustain o 0). Se calcula `s = acc ± paso` con el bit de acarreo o préstamo y un comparador decide si `s` ya alcanzó la meta: si sí, el acumulador toma la meta y la FSM pasa a la siguiente etapa; si no, toma `s`.

![FSM del ADSR](img/fsm_adsr.png)

Al soltar la nota en cualquier etapa pasa a LIBERACIÓN desde el nivel actual; si se vuelve a presionar durante la liberación, ataca desde ese nivel (sin regresar a 0, sin chasquido). Si el sustain cambia mientras se sostiene una nota, el nivel va al nuevo valor con la pendiente del decay.

**Producto.** `muestra = onda · nivel / 256`, en un multiplicador embebido de 9 bits.

### Gestor de voces

Cada ciclo suelta (gate = 0) toda voz cuya nota ya no se pide, conservando la nota para que la liberación suene a la misma frecuencia, y asigna la primera nota pedida sin voz a una voz libre con esta preferencia: la que ya tenía esa nota (se volvió a presionar durante su liberación), una en reposo, o cualquiera libre. Con 3 voces y máximo 3 notas, siempre hay voz para cada nota. Un acorde completo queda repartido en 3 ciclos (120 ns).

### Cadena de salida (`audio_salida`)

```
voz0..2 -> mezclador -> trémolo -> eco -> volumen -> (+ clic del metrónomo) -> PWM
```

Formato interno de 12 bits con signo (la muestra de 8 bits con 4 bits de fracción, escala completa ±2032). Todo avanza con `tick_fs`; la muestra final está lista 9 ciclos después y el PWM la toma al empezar su siguiente periodo.

| Etapa | Funcionamiento |
|---|---|
| Mezclador | `(voz0 + voz1 + voz2) / 2` con saturación; una voz a escala completa da media escala y solo un acorde de 3 voces en fase llega a saturar |
| Trémolo | LFO triangular de 4.98 Hz; la ganancia va de 1.0 a 0.5 |
| Eco | `y[n] = x[n] + y[n − 4096] / 2` con saturación: el eco llega 84 ms después y cada repetición vale la mitad. RAM de 4096 × 12 bits en 12 bloques M4K |
| Volumen | `y = x · vol / 4`, vol de 0 (silencio) a 4 (100 %), con corrimientos y sumas |
| Metrónomo | clic cuadrado de 2 kHz (3 kHz en el acento) de 24.7 ms con caída lineal; no pasa por el volumen ni por los efectos, para que se distinga de las notas |
| PWM | 8 bits a 97.7 kHz (`25 MHz / 256`, dos periodos por muestra), ciclo de trabajo = muestra + 128 |

`audio_salida` también tiene una salida `clip` (saturación en los últimos 100 ms) que se usa en las pruebas; en la EP2C5 no va a ningún LED.

### Metrónomo

Cuenta milisegundos y marca un tiempo cada 1000, 667, 500 o 400 ms (60, 90, 120, 150 BPM), con acento en el primero de cada 4. Al encenderlo, el primer tiempo es inmediato. Es independiente de las voces: tiene su propio generador del clic y se suma al final de la cadena. El tiempo se ve en el LED D2.

### Etapa analógica

El PWM sale por el pin 93 de la FPGA a un filtro RC de dos etapas (1 kΩ y 10 nF cada una, −3 dB en unos 6 kHz y unos −32 dB a 97.7 kHz), un capacitor de 10 µF que quita la DC, un potenciómetro que baja el nivel (volumen analógico) y el amplificador PAM8403, que mueve una bocina de 8 Ω. Detalle en [CABLEADO.md](CABLEADO.md).

## Interfaz de usuario

Los 3 LEDs de la tarjeta (se encienden con `'0'`) muestran el modo y el estado:

| Modo | D2 (pin 3) | D4 (pin 7) | D5 (pin 9) |
|---|---|---|---|
| Interpretación | destello de 100 ms en cada tiempo del metrónomo | apagado | apagado |
| Grabación | metrónomo | parpadeo lento (1 Hz) en espera, fijo mientras graba | apagado |
| Reproducción | metrónomo | apagado | parpadeo lento en espera, fijo mientras reproduce |
| Configuración | los 3 parpadean rápido (4 Hz) con el número del parámetro en binario: D2 = 1, D4 = 2, D5 = 4 | | |

Por ejemplo, en configuración con D2 y D5 parpadeando (1 + 4 = 5) se está cambiando el release. Los valores no se ven: se oyen al tocar (forma, envolvente, volumen) o con el metrónomo (tempo).

## Recursos y tiempos

Memoria en la EP2C5 (26 bloques M4K de 4 096 bits):

| Uso | Tamaño | Bloques M4K |
|---|---|---|
| Línea de retardo del eco | 4 096 × 12 | 12 |
| Memoria de eventos | 256 × 37 | 3 |
| Incrementos de las notas (una por voz) | 128 × 24 | 3 |
| Seno (uno por voz) | 256 × 8 | 3 |
| **Total** | | **21 de 26** |

Compilación en Quartus II 13.0 SP1 para la EP2C5T144C8 con la VGA y los botones (TAREA-025 y TAREA-027): 3 782 elementos lógicos de 4 608 (82 %), 1 403 registros, 76 032 bits de memoria (63 %), 6 de 26 multiplicadores de 9 bits y 1 PLL; el reloj de 25 MHz cerró con 12.3 ns de margen (Fmax de 36 MHz). La VGA sola usaba 1 523 elementos lógicos. Los números de la versión sin VGA salen de la TAREA-029.

## Limitaciones conocidas

- Polifonía de 3 notas: con más teclas presionadas se quedan las 3 más graves.
- Teclado sin diodos: tres teclas en esquinas de un rectángulo del mismo teclado agregan una cuarta fantasma.
- El secuenciador guarda las notas, no los cambios de parámetros: la reproducción usa la forma, envolvente, volumen y efecto que estén en ese momento.
- La reproducción no se mezcla con lo que se toque en vivo.
- PWM de 8 bits: el ruido de cuantización es audible a volumen muy bajo; el filtro RC de 2 etapas deja pasar algo de la portadora de 97.7 kHz, que la bocina no reproduce.
- El eco es de 84 ms (la memoria de la EP2C5 no alcanza para uno más largo con 12 bits por muestra).
- Los modos se recorren en orden con la tecla MODO; para ir de interpretación a configuración hay que presionarla 3 veces.
- Sin pantalla, en configuración los LEDs muestran qué parámetro se cambia pero no su valor.
- En reproducción el volumen y el metrónomo siguen en las teclas del teclado 2; las notas que se toquen encima no suenan.
