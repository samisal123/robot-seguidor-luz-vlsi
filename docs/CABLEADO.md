# Cableado

Todo lo externo se conecta al header GPIO de 2 × 20 de la DE10-Lite (JP1). Sus pines son de **3.3 V y no toleran 5 V**: el único pin de 5 V que se usa es el 11, y solo alimenta al amplificador.

La numeración del header y su relación con los pines de la FPGA están verificadas contra el manual de usuario de la DE10-Lite y el Golden Top de Terasic (`quartus/pines.tcl`). El pin 1 está marcado en la serigrafía de la tarjeta; los impares van en una fila y los pares en la otra.

## Resumen

| Bloque | Pines del header | Notas |
|---|---|---|
| Teclado 1 (octava base) | 1 a 8 | pin *k* del teclado al pin *k* del header |
| 5 V | 11 | solo VCC del PAM8403 |
| GND | 12 y 30 | GND del PAM8403 y del filtro |
| Teclado 2 (octava base + 1) | 13 a 20 | pin *k* del teclado al pin 12 + *k* del header |
| Audio PWM | 31 | entrada del filtro RC |
| Monitor | conector VGA de la tarjeta | cable VGA directo |

## Header GPIO

| Pin del header | GPIO | Pin FPGA | Señal | Se conecta a |
|---|---|---|---|---|
| 1 | GPIO[0] | V10 | `TEC1_FIL[0]` | teclado 1, pin 1 (fila 1: 1 2 3 A) |
| 2 | GPIO[1] | W10 | `TEC1_FIL[1]` | teclado 1, pin 2 (fila 2: 4 5 6 B) |
| 3 | GPIO[2] | V9 | `TEC1_FIL[2]` | teclado 1, pin 3 (fila 3: 7 8 9 C) |
| 4 | GPIO[3] | W9 | `TEC1_FIL[3]` | teclado 1, pin 4 (fila 4: * 0 # D) |
| 5 | GPIO[4] | V8 | `TEC1_COL[0]` | teclado 1, pin 5 (columna 1: 1 4 7 *) |
| 6 | GPIO[5] | W8 | `TEC1_COL[1]` | teclado 1, pin 6 (columna 2: 2 5 8 0) |
| 7 | GPIO[6] | V7 | `TEC1_COL[2]` | teclado 1, pin 7 (columna 3: 3 6 9 #) |
| 8 | GPIO[7] | W7 | `TEC1_COL[3]` | teclado 1, pin 8 (columna 4: A B C D) |
| 9, 10 | GPIO[8], GPIO[9] | | libres | |
| 11 | | | **5 V** | VCC del PAM8403 |
| 12 | | | **GND** | GND del PAM8403 |
| 13 | GPIO[10] | W5 | `TEC2_FIL[0]` | teclado 2, pin 1 |
| 14 | GPIO[11] | AA15 | `TEC2_FIL[1]` | teclado 2, pin 2 |
| 15 | GPIO[12] | AA14 | `TEC2_FIL[2]` | teclado 2, pin 3 |
| 16 | GPIO[13] | W13 | `TEC2_FIL[3]` | teclado 2, pin 4 |
| 17 | GPIO[14] | W12 | `TEC2_COL[0]` | teclado 2, pin 5 |
| 18 | GPIO[15] | AB13 | `TEC2_COL[1]` | teclado 2, pin 6 |
| 19 | GPIO[16] | AB12 | `TEC2_COL[2]` | teclado 2, pin 7 |
| 20 | GPIO[17] | Y11 | `TEC2_COL[3]` | teclado 2, pin 8 |
| 21 a 28 | GPIO[18] a GPIO[25] | | libres | |
| 29 | | | 3.3 V | sin usar |
| 30 | | | **GND** | GND del filtro (capacitores y divisor) |
| 31 | GPIO[26] | AA7 | `AUDIO_PWM` | R1 del filtro RC |
| 32 a 40 | GPIO[27] a GPIO[35] | | libres | |

## Teclados matriciales 4 × 4

Los teclados de membrana tienen un conector hembra de 8 pines: los pines 1 a 4 son las filas y 5 a 8 las columnas. Viendo el teclado de frente con el conector abajo, el pin 1 suele ser el de la izquierda; como cambia entre fabricantes, conviene confirmarlo con el multímetro en continuidad: al presionar la tecla **1** deben unirse los pines 1 y 5, y al presionar la **D**, los pines 4 y 8. Se usan 8 jumpers macho-hembra por teclado (macho al teclado, hembra al header).

```
Teclado 1                         Teclado 2
pin 1 2 3 4 5 6 7 8               pin 1  2  3  4  5  6  7  8
    | | | | | | | |                   |  |  |  |  |  |  |  |
hdr 1 2 3 4 5 6 7 8               hdr 13 14 15 16 17 18 19 20
```

- Las filas se manejan en colector abierto: la FPGA pone en `'0'` solo la fila que lee y deja las otras en alta impedancia. Así, dos teclas presionadas en la misma columna nunca ponen en corto dos salidas.
- Las columnas usan el pull-up interno de la MAX 10 (`WEAK_PULL_UP_RESISTOR` en `pines.tcl`); no hacen falta resistencias externas.
- El barrido lee una fila por milisegundo y cada tecla pasa por un antirrebote de 5 lecturas (20 ms).

Mapa de teclas (igual en los dos teclados; el teclado 2 suena una octava arriba):

```
 1  2  3  A        C   C#  D   | A
 4  5  6  B   ->   D#  E   F   | B
 7  8  9  C        F#  G   G#  | C
 *  0  #  D        A   A#  B   | D
```

Si al probar una tecla aparece otra nota en los displays, el conector quedó volteado o recorrido: revisar que el pin 1 del teclado esté en el pin 1 (o 13) del header.

## Salida de audio

```
header 31 (AUDIO_PWM)
    |
   [R1 1 kΩ]
    |
    +--------+
    |        |
   [R2 1 kΩ] = C1 10 nF
    |        |
    +---+   GND
    |   |
    |   = C2 10 nF
    |   |
    |  GND
    |
  (+) C3 10 µF electrolítico
  (-)
    |
   [R3 10 kΩ]
    |
    +------------------- L (IN) del PAM8403
    |
   [R4 1 kΩ]                 PAM8403
    |                        VCC (+5V) <- header 11
   GND                       GND       <- header 12
                             G de la entrada <- GND
                             R de la entrada: sin conectar
GND = header 30              L+ / L-   -> bocina 8 Ω
```

- **Filtro RC de 2 etapas** (R1-C1, R2-C2): el PWM de 195.3 kHz se convierte en la señal de audio. Corte a −3 dB en unos 6 kHz y −44 dB a 195 kHz.
- **C3** quita la componente de DC (1.65 V, la mitad del PWM). Su lado **+** va hacia el filtro.
- **R3 y R4** forman un divisor de 1/11: el PWM llega a ±1.65 V y el PAM8403 tiene ganancia fija de 24 dB, así que sin divisor se saturaría. Si el módulo trae potenciómetro de volumen, el divisor puede quedarse; el potenciómetro solo baja más.
- **Bocina**: va entre L+ y L−. Ninguna de las dos salidas del PAM8403 es tierra (es puente BTL): **nunca conectar la bocina ni L− a GND**.
- Todas las tierras (filtro, divisor, PAM8403) van al GND del header.

El volumen digital (0 a 4) se cambia con las teclas A y B del teclado 2 o en el modo configuración.

### Energía

La DE10-Lite se alimenta por su cable USB. El PAM8403 toma 5 V del pin 11 del header, que viene del mismo USB (500 mA en total). A volumen moderado alcanza; si la tarjeta se reinicia en los golpes fuertes de volumen, alimentar el PAM8403 con un cargador USB aparte y unir su GND con el del header.

## Monitor VGA

Cable VGA del conector de la tarjeta al monitor (640 × 480 a 60 Hz). Si el monitor solo tiene HDMI, hace falta un convertidor VGA a HDMI activo (con su propia alimentación USB).

## Lista de conexiones para revisar antes de encender

1. Teclado 1: pines 1 a 8 del teclado en los pines 1 a 8 del header.
2. Teclado 2: pines 1 a 8 del teclado en los pines 13 a 20 del header.
3. Header 31 a R1; R1-R2-C3-R3 en serie; C1 y C2 a GND; C3 con el + hacia R2.
4. R3 a la entrada L del PAM8403; R4 de esa entrada a GND.
5. PAM8403: VCC al header 11, GND al header 12 o 30.
6. Bocina entre L+ y L−, sin tocar GND.
7. Ningún cable del header 11 (5 V) va a otro pin del header.
