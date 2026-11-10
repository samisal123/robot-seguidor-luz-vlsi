# Módulos e interfaces

Generado con `python3 tools/genera_modulos.py` a partir de los encabezados y las entidades de `rtl/` (no se edita a mano). La arquitectura, las FSM y las decisiones de diseño están en [ARQUITECTURA.md](ARQUITECTURA.md); cómo se verifica cada módulo, en [PRUEBAS.md](PRUEBAS.md).

Convenciones: un solo reloj `clk` de 25 MHz; `rst` síncrono y activo en alto; los pulsos `tick_fs` (una vez por muestra, 48 828 Hz) y `tick_1ms` duran un ciclo; las señales activas en bajo terminan en `_n`.

Índice: [`sinte_top`](#sinte_top) · [`reset_encendido`](#reset_encendido) · [`base_tiempo`](#base_tiempo) · [`sync_2ff`](#sync_2ff) · [`debounce`](#debounce) · [`interfaz_teclados`](#interfaz_teclados) · [`teclado_scan`](#teclado_scan) · [`teclas_notas`](#teclas_notas) · [`entradas_placa`](#entradas_placa) · [`control`](#control) · [`selector_notas`](#selector_notas) · [`secuenciador`](#secuenciador) · [`memoria_eventos`](#memoria_eventos) · [`gestor_voces`](#gestor_voces) · [`voz`](#voz) · [`dds`](#dds) · [`forma_onda`](#forma_onda) · [`adsr`](#adsr) · [`audio_salida`](#audio_salida) · [`mezclador`](#mezclador) · [`tremolo`](#tremolo) · [`eco`](#eco) · [`volumen`](#volumen) · [`metronomo`](#metronomo) · [`salida_pwm`](#salida_pwm) · [`leds_estado`](#leds_estado) · [`vga_ui`](#vga_ui) · [`synth_pkg`](#synth_pkg) · [`fuente_5x7`](#fuente_5x7)

## Nivel superior

### sinte_top

```text
Sintetizador musical digital sobre la tarjeta EP2C5T144
(Cyclone II). Reloj de 50 MHz -> PLL -> 25 MHz.
ARCHIVO GENERADO por tools/genera_top.py junto con
quartus/sintetizador.bdf (el mismo circuito como diagrama de
bloques). Para cambiar conexiones, editar el script.

  teclados -> interfaz_teclados -> teclas_notas --+-> secuenciador
                                                  v       |
                  selector_notas (vivo o grabado) <-------+
                               |
                         gestor_voces -> voz 0, voz 1, voz 2
                                              |
  audio_salida: mezcla -> efectos -> volumen -> + metronomo -> PWM

  control: modos (boton MODO), teclas de funcion, botones
  ACCION y METRONOMO, parametros y ordenes al secuenciador
  vga_ui y leds_estado: interfaz de usuario
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `CLOCK_50` | in | `std_logic` | oscilador de 50 MHz de la tarjeta (pin 17) |
| `BTN_RESET` | in | `std_logic` | boton RESET de la tarjeta, 0 = presionado (pin 144) |
| `BTN` | in | `std_logic_vector(2 downto 0)` | botones METRONOMO, ACCION y MODO (2..0), 0 = presionado |
| `TEC1_COL` | in | `std_logic_vector(3 downto 0)` | columnas del teclado 1, 0 = tecla (pull-up) |
| `TEC2_COL` | in | `std_logic_vector(3 downto 0)` | columnas del teclado 2 |
| `LED` | out | `std_logic_vector(2 downto 0)` | LEDs D5, D4, D2 de la tarjeta (2..0), activos en bajo |
| `TEC1_FIL` | out | `std_logic_vector(3 downto 0)` | filas del teclado 1 (0 o alta impedancia) |
| `TEC2_FIL` | out | `std_logic_vector(3 downto 0)` | filas del teclado 2 |
| `AUDIO_PWM` | out | `std_logic` | PWM de audio de 97.7 kHz (pin 93) |
| `VGA_R` | out | `std_logic` | rojo (270 ohm al DB15) |
| `VGA_G` | out | `std_logic` | verde |
| `VGA_B` | out | `std_logic` | azul |
| `VGA_HS` | out | `std_logic` | sincronia horizontal |
| `VGA_VS` | out | `std_logic` | sincronia vertical |

Verificación: `sim/tb_sinte_top.vhd`.

## Reloj, reset y tiempos

### reset_encendido

```text
Reset del sistema: rst = '1' desde que se configura la FPGA
hasta 16 ciclos despues de que el PLL se engancha (listo = '1').
El boton RESET de la tarjeta (boton_n, activo en bajo) repite
lo mismo: rst sube mientras esta presionado y baja 16 ciclos
despues de soltarlo. Las dos entradas son asincronas y pasan
por un sincronizador de 2 flip-flops. Los registros de la
Cyclone II arrancan con su valor inicial; este reset garantiza
que todos los modulos empiecen juntos y con el reloj estable.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `listo` | in | `std_logic` | PLL enganchado |
| `boton_n` | in | `std_logic` | boton RESET, '0' = presionado |
| `rst` | out | `std_logic` |  |

Verificación: `sim/tb_reset_encendido.vhd`.

### base_tiempo

```text
Pulsos de habilitacion de un ciclo de reloj:
  tick_fs  : uno cada FS_DIV ciclos (synth_pkg), la frecuencia
             de muestreo del audio: 25 MHz / 512 = 48 828 Hz
  tick_1ms : uno cada CLK_HZ / 1000 ciclos
Todo el diseno usa estos pulsos como habilitacion en lugar de
relojes divididos, asi solo existe el dominio de 25 MHz.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `CLK_HZ` | `natural := CLK_HZ_SIS` |  |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_fs` | out | `std_logic` |  |
| `tick_1ms` | out | `std_logic` |  |

Verificación: `sim/tb_base_tiempo.vhd`.

### sync_2ff

```text
Sincronizador de 2 flip-flops para entradas asincronas
(columnas de los teclados, botones y switches). Un cambio en
d aparece en q en el segundo flanco de reloj despues del
cambio. El primer flip-flop puede quedar metaestable; el
segundo le da un ciclo completo para resolverse.
No lleva reset: arranca en INIT por valor de encendido.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `WIDTH` | `positive  := 1` |  |
| `INIT` | `std_logic := '0'` |  |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `d` | in | `std_logic_vector(WIDTH - 1 downto 0)` |  |
| `q` | out | `std_logic_vector(WIDTH - 1 downto 0)` |  |

Verificación: `sim/tb_sync_2ff.vhd`.

### debounce

```text
Filtro antirrebote para botones y switches. La salida clean
toma el valor de raw solo despues de que raw se mantuvo
distinto de clean durante N_MS ticks de 1 ms seguidos (entre
N_MS-1 y N_MS ms, segun la fase del tick). Cualquier rebote
reinicia la cuenta.
raw ya debe venir sincronizado (sync_2ff).
rise y fall son pulsos de un ciclo cuando clean sube o baja;
sirven, por ejemplo, para que un boton de una sola orden por pulsacion.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `N_MS` | `positive  := 20` |  |
| `INIT` | `std_logic := '0'` | valor de clean tras reset |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_1ms` | in | `std_logic` |  |
| `raw` | in | `std_logic` |  |
| `clean` | out | `std_logic` |  |
| `rise` | out | `std_logic` |  |
| `fall` | out | `std_logic` |  |

Verificación: `sim/tb_debounce.vhd`.

## Entradas

### interfaz_teclados

```text
Conexion de los dos teclados 4x4 con los pines del GPIO:
  - sincroniza las 8 columnas (sync_2ff)
  - barre las filas y filtra rebotes (teclado_scan)
  - maneja las filas en colector abierto: la fila activa va a
    '0' y las demas a alta impedancia, para que dos teclas de
    la misma columna nunca pongan en corto dos salidas
Las columnas necesitan pull-up (el interno de la FPGA, ver
quartus/pines.tcl).
teclas: '1' = presionada; teclado k, fila r, columna c en el
bit 16k + 4r + c.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `N_DEB` | `positive := 5` |  |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_1ms` | in | `std_logic` |  |
| `tec1_col` | in | `std_logic_vector(3 downto 0)` |  |
| `tec2_col` | in | `std_logic_vector(3 downto 0)` |  |
| `tec1_fil` | out | `std_logic_vector(3 downto 0)` | '0' o 'Z' |
| `tec2_fil` | out | `std_logic_vector(3 downto 0)` | '0' o 'Z' |
| `teclas` | out | `std_logic_vector(31 downto 0)` |  |

Verificación: `sim/tb_interfaz_teclados.vhd`.

### teclado_scan

```text
Barrido de dos teclados matriciales de 4x4 de membrana.
Cada ms activa una fila (la misma en los dos teclados): pone
esa fila en '0' y las demas quedan en alta impedancia (el top
convierte el '1' de filas en 'Z'). Las columnas tienen pull-up,
asi que una tecla presionada en la fila activa lee '0'.
Antes de cambiar de fila lee las 8 columnas; el barrido completo
tarda 4 ms.
Antirrebote: cada tecla cambia de estado solo despues de N_DEB
lecturas seguidas distintas a su estado (5 lecturas = 20 ms).
Salida teclas: '1' = presionada. Teclado k, fila r, columna c
en el bit 16k + 4r + c. Varias teclas a la vez se detectan
(polifonia); con tres teclas en esquinas de un rectangulo de la
misma matriz aparece una cuarta fantasma (el teclado no tiene
diodos).
col1 y col2 ya deben venir sincronizadas (sync_2ff).
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `N_DEB` | `positive := 5` |  |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_1ms` | in | `std_logic` |  |
| `filas` | out | `std_logic_vector(3 downto 0)` | '0' = fila activa |
| `col1` | in | `std_logic_vector(3 downto 0)` | teclado 1, '0' = tecla |
| `col2` | in | `std_logic_vector(3 downto 0)` | teclado 2 |
| `teclas` | out | `std_logic_vector(31 downto 0)` |  |

Verificación: `sim/tb_teclado_scan.vhd`.

### teclas_notas

```text
Traduce el estado de las 32 teclas a notas y funciones.
En cada teclado las tres primeras columnas son notas, en orden
de lectura (cromatico), y la cuarta columna son funciones:
     1  2  3  A        C   C#  D   | A
     4  5  6  B   ->   D#  E   F   | B
     7  8  9  C        F#  G   G#  | C
     *  0  #  D        A   A#  B   | D
El teclado 1 toca la octava base y el teclado 2 la siguiente.
Nota n = 12 * octava + semitono (synth_pkg).
Salidas:
  notas : hasta 3 notas presionadas, de la mas grave a la mas
          aguda (nota i en los bits 7i+6..7i; 0 = vacia). Con
          mas de 3 teclas se quedan las 3 mas graves.
  func  : pulso de un ciclo al presionar A, B, C, D del teclado 1
          (bits 0 a 3) y del teclado 2 (bits 4 a 7).

Las notas se buscan en serie, una tecla por ciclo, con un solo
sumador (base + j) en lugar de 24 comparaciones en paralelo:
  ciclo 24     copia las 24 teclas de nota (foto) y la octava,
               publica el resultado anterior y reinicia la busqueda
  ciclos 0-23  si la tecla j de la foto esta presionada y aun hay
               lugar, guarda base + j en el siguiente lugar
Una vuelta dura 25 ciclos (1 us a 25 MHz); las teclas cambian
cada milisegundo, asi que la latencia no se nota.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `teclas` | in | `std_logic_vector(31 downto 0)` |  |
| `octava` | in | `std_logic_vector(2 downto 0)` |  |
| `notas` | out | `std_logic_vector(20 downto 0)` |  |
| `func` | out | `std_logic_vector(7 downto 0)` |  |

Verificación: `sim/tb_teclas_notas.vhd`.

### entradas_placa

```text
Botones del panel (activos en bajo, con el pull-up interno de
la FPGA):
  btn(0) MODO      -> cada pulsacion pasa al siguiente modo:
                      interpretacion, grabacion, reproduccion,
                      configuracion y de nuevo interpretacion
  btn(1) ACCION    -> accion: pulso de un ciclo al presionar
  btn(2) METRONOMO -> metro_btn: pulso de un ciclo al presionar
Cada boton pasa por un sincronizador de 2 flip-flops y un
antirrebote de 20 ms. Despues del reset el modo es
interpretacion.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_1ms` | in | `std_logic` |  |
| `btn` | in | `std_logic_vector(2 downto 0)` | '0' = presionado |
| `accion` | out | `std_logic` |  |
| `metro_btn` | out | `std_logic` |  |
| `modo` | out | `std_logic_vector(1 downto 0)` |  |

Verificación: `sim/tb_entradas_placa.vhd`.

## Control y secuenciador

### control

```text
Unidad principal de control. Guarda los parametros del
sintetizador, interpreta las teclas de funcion segun el modo
y manda las ordenes al secuenciador.

Modo (boton MODO): 00 interpretacion, 01 grabacion,
                10 reproduccion, 11 configuracion.

Teclas de funcion (columna A-D de cada teclado):
  Interpretacion, grabacion y reproduccion:
    teclado 1: A octava -, B octava +, C forma siguiente,
               D efecto siguiente
    teclado 2: A volumen -, B volumen +, C tempo -, D tempo +
  Configuracion (cualquiera de los dos teclados):
    A valor -, B valor +, C parametro anterior,
    D parametro siguiente
  Parametros: forma, attack, decay, sustain, release, volumen,
  tempo y efecto (synth_pkg). Los valores se quedan en sus
  limites (no dan la vuelta); forma y efecto si dan la vuelta
  con sus teclas directas.

ACCION: en grabacion inicia o finaliza la grabacion; en
reproduccion inicia o detiene la reproduccion.
METRONOMO: enciende o apaga el metronomo (en cualquier modo).
metro_suena = metro_on, salvo mientras se reproduce una
secuencia (el metronomo se usa al interpretar y al grabar).
Si se cambia de modo a mitad de una grabacion o reproduccion,
esta se termina (cmd_parar).
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `modo` | in | `std_logic_vector(1 downto 0)` |  |
| `func` | in | `std_logic_vector(7 downto 0)` | pulsos A-D teclado 1 (3..0) y 2 (7..4) |
| `accion` | in | `std_logic` | pulso del boton ACCION |
| `metro_btn` | in | `std_logic` | pulso del boton METRONOMO |
| `estado_sec` | in | `std_logic_vector(1 downto 0)` |  |
| `forma` | out | `std_logic_vector(1 downto 0)` |  |
| `atk` | out | `std_logic_vector(1 downto 0)` |  |
| `dec` | out | `std_logic_vector(1 downto 0)` |  |
| `sus` | out | `std_logic_vector(1 downto 0)` |  |
| `rel` | out | `std_logic_vector(1 downto 0)` |  |
| `volumen` | out | `std_logic_vector(2 downto 0)` | 0 silencio .. 4 |
| `tempo` | out | `std_logic_vector(1 downto 0)` |  |
| `efecto` | out | `std_logic_vector(1 downto 0)` |  |
| `metro_on` | out | `std_logic` |  |
| `metro_suena` | out | `std_logic` |  |
| `octava` | out | `std_logic_vector(2 downto 0)` |  |
| `parametro` | out | `std_logic_vector(2 downto 0)` |  |
| `cmd_grabar` | out | `std_logic` |  |
| `cmd_reproducir` | out | `std_logic` |  |
| `cmd_parar` | out | `std_logic` |  |

Verificación: `sim/tb_control.vhd`.

### selector_notas

```text
Elige que notas piden las voces: mientras el secuenciador
reproduce, las grabadas; en cualquier otro momento, las del
teclado (en vivo). Asi la reproduccion no se mezcla con lo
que se toque encima.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `estado_sec` | in | `std_logic_vector(1 downto 0)` |  |
| `vivo` | in | `std_logic_vector(20 downto 0)` |  |
| `grabado` | in | `std_logic_vector(20 downto 0)` |  |
| `pedidas` | out | `std_logic_vector(20 downto 0)` |  |

Verificación: `sim/tb_selector_notas.vhd`.

### secuenciador

```text
Graba y reproduce secuencias musicales en memoria_eventos.

Un evento es un conjunto de notas que se mantuvo igual (hasta
3 notas, o silencio si no hay ninguna) y su duracion en ms.
Grabando, cada vez que cambia el conjunto pedido se guarda el
evento que termina; asi quedan las notas, los acordes, los
silencios y sus duraciones, en orden.

Base de tiempo: t_ms cuenta los ticks de 1 ms todo el tiempo.
inicio guarda el ms en que empezo el evento en curso y la
duracion es t_ms - inicio (modulo 2**17). Al reproducir, el
evento siguiente empieza en inicio + duracion; asi la
latencia de la maquina de estados no pierde ticks ni acumula
error a lo largo de la secuencia.

Maquina de estados:
  ESPERA    no hace nada; la salida es silencio.
            cmd_grabar                   -> GRABANDO (borra lo anterior)
            cmd_reproducir y hay eventos -> LEER (evento 0)
  GRABANDO  si el conjunto cambia, guarda el evento que termina
            y empieza otro. Un evento que llega a 65 535 ms se
            guarda y sigue como un evento nuevo.
            cmd_parar -> guarda el ultimo evento -> ESPERA
            al guardar el evento 256 (memoria llena) -> ESPERA
  LEER      la RAM entrega el evento p             -> CARGAR
  CARGAR    pone las notas del evento en la salida -> TOCAR
  TOCAR     al cumplirse la duracion pasa al siguiente evento
            (LEER) o, si era el ultimo, termina en silencio
            -> ESPERA. cmd_parar -> ESPERA.

Un evento con duracion 0 no se guarda.
posicion: grabando o en espera, eventos guardados;
reproduciendo, numero del evento que suena (desde 1).
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_1ms` | in | `std_logic` |  |
| `cmd_grabar` | in | `std_logic` | pulso: iniciar grabacion |
| `cmd_reproducir` | in | `std_logic` | pulso: iniciar reproduccion |
| `cmd_parar` | in | `std_logic` | finalizar grabacion o detener reproduccion |
| `conjunto` | in | `std_logic_vector(20 downto 0)` | notas en vivo |
| `salida` | out | `std_logic_vector(20 downto 0)` | notas reproducidas |
| `estado` | out | `std_logic_vector(1 downto 0)` | S_ESPERA, S_GRABANDO, S_REPRODUCE |
| `eventos` | out | `std_logic_vector(8 downto 0)` | 0 a 256 |
| `posicion` | out | `std_logic_vector(8 downto 0)` |  |
| `llena` | out | `std_logic` |  |

Verificación: `sim/tb_secuenciador.vhd`.

### memoria_eventos

```text
Memoria de eventos musicales del secuenciador: RAM de un
puerto, 2**N_DIR palabras de ANCHO bits, escritura sincrona y
lectura registrada (el dato de dir sale un ciclo despues).
Quartus la mapea en bloques M9K (256 x 37 bits = 2 bloques).
Formato de cada evento (ANCHO = 37):
  bits 36..16 : las 3 notas que sonaban (7 bits cada una,
                0 = vacia; las 3 en 0 = silencio)
  bits 15..0  : duracion en ms (1 a 65 535)
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `ANCHO` | `positive := 37` |  |
| `N_DIR` | `positive := 8` |  |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `we` | in | `std_logic` |  |
| `dir` | in | `std_logic_vector(N_DIR - 1 downto 0)` |  |
| `din` | in | `std_logic_vector(ANCHO - 1 downto 0)` |  |
| `dout` | out | `std_logic_vector(ANCHO - 1 downto 0)` |  |

Verificación: dentro del testbench del módulo que lo contiene.

## Voces

### gestor_voces

```text
Reparte hasta 3 notas pedidas entre las 3 voces (polifonia).
Entrada conjunto: notas pedidas, 7 bits cada una (0 = vacia),
del teclado o del secuenciador. Cada ciclo de reloj:
  1) Suelta (gate = '0') toda voz cuya nota ya no se pide. La
     voz conserva su nota para que la liberacion suene en la
     misma frecuencia.
  2) Busca la primera nota pedida que no tenga voz y le da una
     voz libre (gate = '0'), en este orden de preferencia:
       a) la voz que ya tenia esa nota (se volvio a presionar
          durante su liberacion; asi no se duplica la nota),
       b) una voz en reposo (activa = '0'),
       c) cualquier voz libre (corta una liberacion).
     Se asigna una nota por ciclo; un acorde de 3 notas queda
     repartido en 3 ciclos (60 ns).
Como hay 3 voces y a lo mas 3 notas, siempre hay voz libre
para cada nota pedida.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `conjunto` | in | `std_logic_vector(20 downto 0)` | notas pedidas |
| `activas` | in | `std_logic_vector(2 downto 0)` | voces que aun suenan |
| `notas_v` | out | `std_logic_vector(20 downto 0)` | nota de cada voz |
| `gates` | out | `std_logic_vector(2 downto 0)` |  |

Verificación: `sim/tb_gestor_voces.vhd`.

### voz

```text
Una voz completa del sintetizador:

  nota -> ROM de incrementos -> DDS -> forma de onda --+
                                                        x -> muestra
  gate -------------------------------> ADSR ----------+

La ROM da el incremento de fase de la nota (synth_pkg) y va en
un bloque M4K (lectura registrada, 128 x 24 bits); el DDS
genera la fase, forma_onda la convierte en muestra (-127..127)
y la envolvente la escala:
    muestra = onda * nivel / 256
El producto (8 x 9 bits con signo) cabe en un multiplicador
embebido de la Cyclone II.
La nota debe quedarse fija mientras dure la liberacion; el
gestor de voces solo baja el gate al soltar la tecla.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_fs` | in | `std_logic` |  |
| `nota` | in | `std_logic_vector(6 downto 0)` |  |
| `gate` | in | `std_logic` |  |
| `forma` | in | `std_logic_vector(1 downto 0)` |  |
| `atk` | in | `std_logic_vector(1 downto 0)` |  |
| `dec` | in | `std_logic_vector(1 downto 0)` |  |
| `sus` | in | `std_logic_vector(1 downto 0)` |  |
| `rel` | in | `std_logic_vector(1 downto 0)` |  |
| `muestra` | out | `std_logic_vector(7 downto 0)` | con signo |
| `nivel` | out | `std_logic_vector(7 downto 0)` | envolvente 0..255 |
| `activa` | out | `std_logic` |  |

Verificación: `sim/tb_voz.vhd`.

### dds

```text
Acumulador de fase de la sintesis digital directa (DDS).
En cada muestra (tick_fs) suma el incremento:
    fase = fase + inc   (modulo 2**24)
La frecuencia de salida es f = inc * Fs / 2**24, con
Fs = 48 828.125 Hz (resolucion de 0.0029 Hz). El incremento se
puede cambiar en cualquier momento: la fase sigue desde donde
iba, sin saltos (cambio de nota sin volver a programar).
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_fs` | in | `std_logic` |  |
| `inc` | in | `std_logic_vector(23 downto 0)` |  |
| `fase` | out | `std_logic_vector(23 downto 0)` |  |

Verificación: `sim/tb_dds.vhd`.

### forma_onda

```text
Convierte la fase del DDS (24 bits) en una muestra con signo
de 8 bits (-127 a 127), segun la forma elegida:
  cuadrada   : +127 en la primera mitad del periodo, -127 en la
               segunda (bit mas alto de la fase).
  triangular : sube de -127 a 127 en la primera mitad y baja en
               la segunda (bits 22 a 15 de la fase).
  sierra     : rampa de -127 a 127 (bits 23 a 16).
  seno       : tabla de 256 puntos de synth_pkg (bits 23 a 16),
               guardada en un bloque M4K.
La forma se cambia en operacion.
Tuberia de 2 etapas: en la primera se lee la ROM del seno y se
registran la fase (bits 23 a 15) y la forma; en la segunda se
elige la muestra. La salida llega 2 ciclos despues de la fase.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `forma` | in | `std_logic_vector(1 downto 0)` |  |
| `fase` | in | `std_logic_vector(23 downto 0)` |  |
| `muestra` | out | `std_logic_vector(7 downto 0)` |  |

Verificación: `sim/tb_forma_onda.vhd`.

### adsr

```text
Envolvente ADSR de una voz. Acumulador de 24 bits; el nivel
de salida son sus 8 bits altos (0 a 255). Avanza una vez por
muestra (tick_fs) con los pasos de synth_pkg, usando un solo
sumador/restador y un comparador contra la meta de la etapa:

  REPOSO  nivel 0; con gate = '1' pasa a ATAQUE.
  ATAQUE  sube con paso_attack hasta el maximo -> DECAIMIENTO.
  DECAIMIENTO baja con paso_decay hasta el nivel de sustain.
  SOSTENIDO   se queda en el sustain mientras gate = '1'; si el
              sustain cambia en operacion, va hacia el nuevo
              nivel con el paso de decay (sin saltos).
  LIBERACION  baja con paso_release hasta 0 -> REPOSO.

Al soltar la nota (gate = '0') en cualquier etapa pasa a
LIBERACION desde el nivel en que este; si la nota vuelve
(gate = '1') durante la liberacion, ataca desde ese nivel, sin
caer a 0 (no hay chasquido). Attack, decay y release son
tiempos (de toda la escala); sustain es un nivel.
activa = '1' mientras no este en REPOSO.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_fs` | in | `std_logic` |  |
| `gate` | in | `std_logic` |  |
| `atk` | in | `std_logic_vector(1 downto 0)` |  |
| `dec` | in | `std_logic_vector(1 downto 0)` |  |
| `sus` | in | `std_logic_vector(1 downto 0)` |  |
| `rel` | in | `std_logic_vector(1 downto 0)` |  |
| `nivel` | out | `std_logic_vector(7 downto 0)` |  |
| `etapa` | out | `std_logic_vector(2 downto 0)` | 0 reposo .. 4 liberacion |
| `activa` | out | `std_logic` |  |

Verificación: `sim/tb_adsr.vhd`.

## Audio

### audio_salida

```text
Etapa de salida de audio del sintetizador:

  voz0..2 -> mezclador -> tremolo -> eco -> volumen -> (+) -> PWM
                                                        ^
                                    metronomo (clic) ---+

Formato interno: 12 bits con signo = muestra de 8 bits con 4 bits
de fraccion (escala completa +-2032 = +-127.0).
  mezclador : (voz0 + voz1 + voz2) / 2, saturado
  efecto    : 00 ninguno, 01 tremolo, 10 eco, 11 los dos
              (tremolo primero, luego eco)
  volumen   : 0, 25, 50, 75 o 100 %
  final     : y / 16 (a 8 bits) + clic del metronomo, saturado a
              +-127; el clic no pasa por el volumen
  salida_pwm: PWM de 8 bits a 97.7 kHz con duty = muestra + 128
Todo avanza con tick_fs (una muestra cada 512 ciclos); la cadena
tarda 9 ciclos desde tick_fs hasta la muestra final y el PWM la
toma al empezar su siguiente periodo de 256 ciclos.
  clip  : '1' si hubo saturacion (mezcla, eco o suma final) en
          los ultimos ~100 ms
  nivel : |muestra final| (0..127), para medidores
  beat, acento: pulsos del metronomo
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_fs` | in | `std_logic` | pulso de 1 ciclo cada FS_DIV ciclos |
| `tick_1ms` | in | `std_logic` | pulso de 1 ciclo cada 1 ms |
| `voz0` | in | `std_logic_vector(7 downto 0)` | con signo |
| `voz1` | in | `std_logic_vector(7 downto 0)` |  |
| `voz2` | in | `std_logic_vector(7 downto 0)` |  |
| `volumen` | in | `std_logic_vector(2 downto 0)` | 0..4 |
| `efecto` | in | `std_logic_vector(1 downto 0)` | E_* |
| `metro_on` | in | `std_logic` |  |
| `tempo` | in | `std_logic_vector(1 downto 0)` | periodo_beat_ms |
| `pwm` | out | `std_logic` |  |
| `beat` | out | `std_logic` |  |
| `acento` | out | `std_logic` |  |
| `clip` | out | `std_logic` |  |
| `nivel` | out | `std_logic_vector(7 downto 0)` |  |

Verificación: `sim/tb_audio_salida.vhd`.

### mezclador

```text
Suma las 3 voces (muestras de 8 bits con signo, -127..127) y
deja el resultado en el formato interno de la etapa de audio:
12 bits con signo = muestra de 8 bits con 4 bits de fraccion,
escala completa +-2032 (= +-127.0).
  mezcla = saturar( (voz0 + voz1 + voz2) * 8 )
Equivale a sumar las voces y dividir entre 2: una voz sola a
escala completa queda en la mitad de la escala (63.5 de 127);
dos voces nunca saturan y tres solo cuando sus picos coinciden
(|suma| > 254). Si satura, satura = '1' junto con sal_valida.
Con ent_valida = '1' captura las voces; la mezcla sale un ciclo
despues con un pulso en sal_valida.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `ent_valida` | in | `std_logic` |  |
| `voz0` | in | `std_logic_vector(7 downto 0)` |  |
| `voz1` | in | `std_logic_vector(7 downto 0)` |  |
| `voz2` | in | `std_logic_vector(7 downto 0)` |  |
| `mezcla` | out | `std_logic_vector(11 downto 0)` |  |
| `sal_valida` | out | `std_logic` |  |
| `satura` | out | `std_logic` |  |

Verificación: `sim/tb_mezclador.vhd`.

### tremolo

```text
Efecto de tremolo: modula la amplitud con un LFO triangular de
unos 5 Hz y profundidad de 50 %.
  LFO: acumulador de fase de 20 bits que avanza INC_LFO por
       muestra; f = INC_LFO * Fs / 2**20 (107 -> 4.98 Hz).
       tri sube de 0 a 255 en medio periodo y baja en el otro.
  ganancia g = 256 - tri / 2   (de 256 = 1.0 a 129 = 0.504)
  y = x * g / 256              (corrimiento aritmetico)
Con activo = '0' la muestra pasa sin cambio (el LFO sigue).
Muestras de 12 bits con signo; |y| <= |x|, nunca satura.
Tres etapas registradas (LFO, producto, escala): sal_valida
llega 3 ciclos despues de ent_valida. Acepta una muestra por
ciclo.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `activo` | in | `std_logic` |  |
| `ent_valida` | in | `std_logic` |  |
| `x` | in | `std_logic_vector(11 downto 0)` |  |
| `y` | out | `std_logic_vector(11 downto 0)` |  |
| `sal_valida` | out | `std_logic` |  |

Verificación: `sim/tb_tremolo.vhd`.

### eco

```text
Efecto de eco (retardo con realimentacion):
  y[n] = saturar( x[n] + y[n - RETARDO] / 2 )
Con RETARDO = 4096 muestras el eco llega 84 ms despues y cada
repeticion vale la mitad de la anterior.
La linea de retardo es una RAM de RETARDO x 12 bits con
escritura sincrona y lectura registrada (plantilla de RAM de un
puerto de Quartus, se mapea en bloques M4K: 4096 x 12 bits son
12 de los 26 bloques de la EP2C5). Por cada muestra se
lee la posicion ptr (lo que se escribio hace RETARDO muestras),
se calcula y, se escribe y en esa misma posicion y ptr avanza.
La RAM no necesita valores iniciales: hasta que ptr da la
primera vuelta despues del reset (lleno = '0') el retardo se
toma como 0, asi nunca se oye basura.
Con activo = '0' la muestra pasa sin cambio y en la RAM se
escribe x, asi al activarlo el eco empieza con lo reciente.
sal_valida llega 3 ciclos despues de ent_valida; acepta una
muestra cada 3 ciclos o mas. satura = '1' junto con sal_valida
si la suma se tuvo que saturar.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `RETARDO` | `positive := 4096` | muestras |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `activo` | in | `std_logic` |  |
| `ent_valida` | in | `std_logic` |  |
| `x` | in | `std_logic_vector(11 downto 0)` |  |
| `y` | out | `std_logic_vector(11 downto 0)` |  |
| `sal_valida` | out | `std_logic` |  |
| `satura` | out | `std_logic` |  |

Verificación: `sim/tb_eco.vhd`.

### volumen

```text
Control digital de volumen, independiente de la envolvente:
  vol = 0 silencio, 1 = 25 %, 2 = 50 %, 3 = 75 %, 4 = 100 %
  y = (x * vol) / 4  (corrimiento aritmetico, redondeo hacia
  abajo); vol de 5 a 7 se toma como 4.
x * vol se arma con corrimientos y una suma (sin multiplicador).
Muestras de 12 bits con signo; |y| <= |x|.
sal_valida llega 1 ciclo despues de ent_valida.
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `ent_valida` | in | `std_logic` |  |
| `x` | in | `std_logic_vector(11 downto 0)` |  |
| `vol` | in | `std_logic_vector(2 downto 0)` |  |
| `y` | out | `std_logic_vector(11 downto 0)` |  |
| `sal_valida` | out | `std_logic` |  |

Verificación: `sim/tb_volumen.vhd`.

### metronomo

```text
Metronomo de 60, 90, 120 o 150 BPM con clic audible.
Tiempos: cuenta milisegundos con tick_1ms y marca un tiempo cada
periodo_beat_ms(tempo) ms (1000, 667, 500, 400; synth_pkg).
Al encender metro_on el primer tiempo es inmediato y lleva
acento; despues hay acento en 1 de cada 4 tiempos (compas de 4).
Si tempo cambia a uno mas rapido, el siguiente tiempo cae en el
siguiente milisegundo si la cuenta ya paso el nuevo periodo.
  beat   : pulso de 1 ciclo por tiempo
  acento : '1' junto con beat en el primer tiempo del compas
Clic: tono cuadrado de 2 kHz (3 kHz en el acento) de unos 25 ms
cuya amplitud baja en linea recta de CLIC_AMP a 0. Se calcula una
muestra por tick_fs:
  fase : acumulador de 16 bits, f = inc * Fs / 2**16
         (2684 -> 1999.7 Hz, 4027 -> 3000.2 Hz)
  env  : envolvente de 16 bits; arranca en CLIC_AMP * 1024 y baja
         DEC_ENV por muestra; amplitud = env / 1024
         (48 -> 0 en 1204 muestras = 24.7 ms)
  clic = +amplitud o -amplitud segun el bit alto de la fase
Al apagar metro_on ya no hay tiempos nuevos; el clic que sonaba
termina solo.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `CLK_HZ` | `natural := CLK_HZ_SIS` |  |
| `CLIC_AMP` | `natural := 48` | amplitud inicial del clic, de 127 |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_fs` | in | `std_logic` |  |
| `tick_1ms` | in | `std_logic` |  |
| `metro_on` | in | `std_logic` |  |
| `tempo` | in | `std_logic_vector(1 downto 0)` |  |
| `beat` | out | `std_logic` |  |
| `acento` | out | `std_logic` |  |
| `clic` | out | `std_logic_vector(7 downto 0)` | con signo, cambia con tick_fs |

Verificación: `sim/tb_metronomo.vhd`.

### salida_pwm

```text
DAC de 1 bit: PWM de 8 bits a 25 MHz / 256 = 97.7 kHz.
El filtro RC de la tarjeta de audio quita la portadora y deja la
senal de audio (Fs = 48.8 kHz, 2 periodos de PWM por muestra).
  duty = muestra + 128   (muestra con signo -128..127 -> 0..255)
  pwm = '1' los primeros duty ciclos de cada periodo de 256
El duty nuevo se toma solo al final de cada periodo (cuenta =
255), para que ningun periodo quede con un ancho intermedio.
La salida sale de un registro (sin glitches). Despues del
reset el duty es 128 (silencio).
```

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `muestra` | in | `std_logic_vector(7 downto 0)` | con signo |
| `pwm` | out | `std_logic` |  |

Verificación: `sim/tb_salida_pwm.vhd`.

## Indicadores

### leds_estado

```text
Los 3 LEDs de la tarjeta EP2C5T144 (se encienden con '0'):
  led_n(0)  D2  tiempo del metronomo: destello de 100 ms en cada
                tiempo, solo con el metronomo encendido
  led_n(1)  D4  grabando
  led_n(2)  D5  reproduciendo
El resto del estado se ve en la pantalla VGA.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `BEAT_MS` | `positive := 100` |  |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `tick_1ms` | in | `std_logic` |  |
| `metro_on` | in | `std_logic` |  |
| `beat` | in | `std_logic` |  |
| `estado_sec` | in | `std_logic_vector(1 downto 0)` |  |
| `led_n` | out | `std_logic_vector(2 downto 0)` | '0' = encendido |

Verificación: `sim/tb_leds_estado.vhd`.

### vga_ui

```text
Interfaz grafica VGA del sintetizador: 640x480 a 60 Hz con
1 bit por color (8 colores; una resistencia de 270 ohm por color
entre la FPGA y el conector VGA). En la tarjeta EP2C5T144 es la
interfaz principal: muestra el modo, los parametros, las notas
de cada voz y el estado del secuenciador.

Pantalla (x, y en pixeles; el texto va en una cuadricula de
celdas de 12x16 con letras 5x7 al doble de tamano):
  y   0- 63  Banda del modo, de color segun el modo (azul
             INTERPRETACION, rojo GRABACION, verde REPRODUCCION,
             magenta CONFIGURACION), con el nombre del modo en
             letras x4. A la derecha: METRONOMO ON/OFF, el tempo
             en BPM y un foco que se enciende DESTELLO ciclos en
             cada tiempo (verde; rojo en el tiempo con acento;
             blanco entre tiempos y azul con el metronomo apagado).
  y  80- 95  TECLADO 1 y TECLADO 2 sobre su octava.
  y  96-229  Piano de dos octavas (14 blancas, 10 negras) desde
             la nota octava*12. La tecla de cada nota que suena
             (gate en 1) se pinta del color de su voz (V1
             rojo, V2 verde, V3 cian). Las teclas C llevan
             C<octava> y C<octava+1>.
  y 234-387  Tres paneles:
             PARAMETROS: forma, attack, decay, sustain, release,
               volumen (con medidor de 4 segmentos), tempo y
               efecto. En CONFIGURACION el renglon del parametro
               elegido se resalta en amarillo con una flecha.
             FORMA DE ONDA: un periodo de la forma elegida
               (calculado igual que forma_onda) y su nombre.
             VOCES: nota de cada voz (cian si no tiene gate) y
               barra de su nivel de envolvente; octava base.
  y 392-455  SECUENCIADOR: estado (EN ESPERA, GRABANDO con punto
             rojo que parpadea, REPRODUCIENDO), EVENTOS n/256,
             barra (AVANCE posicion/eventos al reproducir;
             MEMORIA eventos/256 si no) y POS n.
  y 464-477  Pie de pagina.

Tiempos: el reloj del sistema es de 25 MHz, un pixel por ciclo.
Horizontal 640 + 16 + 96 + 48 = 800 pixeles,
vertical 480 + 10 + 2 + 33 = 525 lineas, sincronias en bajo.
Fuera de la zona visible el color es 0.

Las entradas se copian una vez por cuadro (al inicio de la
ultima linea, antes de la zona visible), asi el cuadro sale
completo con los mismos datos. En esa copia se decodifican las
notas, se calcula el umbral de la barra y arranca la conversion
a BCD de eventos y posicion (doble-dabble, un bit por ciclo).
El pulso beat se atiende en cada ciclo: arranca la cuenta del
foco, que el cuadro siguiente muestra encendido.

Tuberia de 5 etapas (los registros cambian cada 40 ns; la
logica se reparte para que cada etapa sea corta):
  1 coordenadas y geometria: zona de la pantalla, celda de texto,
    celda del titulo, tecla blanca (con contadores que avanzan
    junto con hc, sin divisiones), banderas de los graficos
    (foco, caja de la onda, barras), producto de la barra y
    lectura de la ROM de la onda (bloque M4K).
  2 contenido: codigo del caracter de la cuadricula, tecla negra
    o blanca y voz que la toca, linea de la onda, rellenos; un
    color por zona.
  3 color de fondo segun la zona y letra que toca (titulo,
    etiqueta del piano o cuadricula).
  4 fuente: lee la fila del caracter de la ROM de la fuente
    (otro bloque M4K).
  5 color final.
HSYNC y VSYNC pasan por las mismas 5 etapas, asi que siguen
alineadas con el color.
```

| Genérico | Tipo y valor | Comentario |
|---|---|---|
| `DESTELLO` | `natural := 2_500_000` | ciclos encendido del foco (100 ms a 25 MHz) |
| `PARPADEO` | `natural := 4` | bit del contador de cuadros del parpadeo (4: ~0.5 s) |

| Puerto | Dir. | Tipo | Comentario |
|---|---|---|---|
| `clk` | in | `std_logic` |  |
| `rst` | in | `std_logic` | sincrono, activo en alto |
| `modo` | in | `std_logic_vector(1 downto 0)` |  |
| `estado_sec` | in | `std_logic_vector(1 downto 0)` |  |
| `forma` | in | `std_logic_vector(1 downto 0)` |  |
| `atk` | in | `std_logic_vector(1 downto 0)` |  |
| `dec` | in | `std_logic_vector(1 downto 0)` |  |
| `sus` | in | `std_logic_vector(1 downto 0)` |  |
| `rel` | in | `std_logic_vector(1 downto 0)` |  |
| `volumen` | in | `std_logic_vector(2 downto 0)` | 0 a 4 |
| `tempo` | in | `std_logic_vector(1 downto 0)` |  |
| `efecto` | in | `std_logic_vector(1 downto 0)` |  |
| `metro_on` | in | `std_logic` |  |
| `beat` | in | `std_logic` | pulso de un ciclo por tiempo |
| `acento` | in | `std_logic` | junto con beat en el tiempo fuerte |
| `octava` | in | `std_logic_vector(2 downto 0)` |  |
| `notas` | in | `std_logic_vector(20 downto 0)` | voz i en 7i+6..7i |
| `gates` | in | `std_logic_vector(2 downto 0)` |  |
| `niveles` | in | `std_logic_vector(23 downto 0)` | voz i en 8i+7..8i |
| `parametro` | in | `std_logic_vector(2 downto 0)` |  |
| `eventos` | in | `std_logic_vector(8 downto 0)` |  |
| `posicion` | in | `std_logic_vector(8 downto 0)` |  |
| `vga_r` | out | `std_logic` |  |
| `vga_g` | out | `std_logic` |  |
| `vga_b` | out | `std_logic` |  |
| `vga_hs` | out | `std_logic` |  |
| `vga_vs` | out | `std_logic` |  |

Verificación: `sim/tb_vga_ui.vhd`.

## Paquetes

### synth_pkg

```text
Constantes y tablas compartidas del sintetizador. Los puertos
de todas las entidades usan solo std_logic y std_logic_vector
(para que el Block Editor de Quartus genere sus simbolos);
este paquete solo da nombre a los codigos y guarda las tablas.

Reloj: 25 MHz (el PLL de la Cyclone II lo saca de los 50 MHz
       del oscilador de la tarjeta).
Audio: una muestra cada FS_DIV ciclos de 25 MHz
       (25e6 / 512 = 48 828.125 muestras por segundo).
Notas: n = 12 * octava + semitono (C = 0 ... B = 11); A4 = 57.
       n = 0 significa "sin nota".
DDS:   acumulador de fase de 24 bits; f = inc * Fs / 2**24.
```

Paquete: lo usan los módulos que lo importan; sus tablas se revisan en los testbenches de esos módulos.

### fuente_5x7

```text
Fuente de 5x7 pixeles de la interfaz VGA (vga_ui).

Cada caracter tiene un codigo de 6 bits:
  0      espacio
  1-26   A-Z
  27-36  0-9
  37-53  % : - / # + . > < ( ) [ ] = ! * ,
  63     bloque lleno
Un caracter son 7 filas de 5 bits; el bit 4 es la columna de la
izquierda. La fila 7 (y cualquier codigo sin dibujo) sale vacia.

txt() y cod_car() convierten texto a codigos. vga_ui solo las
usa con constantes, asi que se evaluan al elaborar y en hardware
solo queda la ROM de la fuente (fila_fuente). El testbench usa
las mismas funciones para revisar lo que sale en pantalla.
```

Paquete: lo usan los módulos que lo importan; sus tablas se revisan en los testbenches de esos módulos.
