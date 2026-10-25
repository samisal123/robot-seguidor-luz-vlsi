# Cableado

Todo se conecta al header GPIO de 2 × 20 de la DE10-Lite (JP1). Sus pines son de **3.3 V y no toleran 5 V**: nada que salga a 5 V entra directo a la FPGA.

La numeración del header y su relación con los pines de la FPGA están verificadas contra el manual de usuario de la DE10-Lite. El pin 1 está marcado en la serigrafía de la tarjeta; los impares van en una fila y los pares en la otra. Los pines de la FPGA están en `quartus/pines.tcl`, que se generó del Golden Top de Terasic.

## Energía

| Fuente | Alimenta | Cómo |
|---|---|---|
| Power bank USB (5 V) | DE10-Lite | Cable USB al conector de la tarjeta (el mismo de programar) |
| Header pin 11 (5 V de la tarjeta) | 4 HC-SR04, 2 LM339 y los divisores de las LDR | Unos 70 mA en total; el header da hasta 5 W entre 5 V y 3.3 V |
| Header pin 29 (3.3 V) | VCC lógico del TB6612FNG, pull-ups de las salidas de los LM339, KY-010 | |
| Portapilas 4 AA (6 V) | VM del TB6612FNG (motores) | El switch del kit en serie con el positivo |

**Tierra común:** el negativo del portapilas, el GND del driver, el de los sensores y el del USB-TTL van a un GND del header (pin 12 o 30).

El VCC del TB6612FNG va a 3.3 V a propósito: sus entradas detectan alto a partir de 0.7 × VCC, y con VCC en 5 V las señales de 3.3 V de la FPGA no alcanzarían.

## Header GPIO

| Pin del header | GPIO | Pin FPGA | Señal | Se conecta a |
|---|---|---|---|---|
| 1 | GPIO[0] | V10 | `US_TRIG[0]` | TRIG del HC-SR04 del frente |
| 2 | GPIO[1] | W10 | `US_ECHO[0]` | ECHO del HC-SR04 del frente, por el divisor |
| 3 | GPIO[2] | V9 | `US_TRIG[1]` | TRIG del HC-SR04 diagonal izquierda |
| 4 | GPIO[3] | W9 | `US_ECHO[1]` | ECHO diagonal izquierda, por el divisor |
| 5 | GPIO[4] | V8 | `US_TRIG[2]` | TRIG del HC-SR04 diagonal derecha |
| 6 | GPIO[5] | W8 | `US_ECHO[2]` | ECHO diagonal derecha, por el divisor |
| 7 | GPIO[6] | V7 | `US_TRIG[3]` | TRIG del HC-SR04 de atrás |
| 8 | GPIO[7] | W7 | `US_ECHO[3]` | ECHO de atrás, por el divisor |
| 9 | GPIO[8] | W6 | `LDR_VE[0]` | LM339 #1 pin 2 (OUT1): LDR frente |
| 10 | GPIO[9] | V5 | `LDR_VE[1]` | LM339 #1 pin 1 (OUT2): LDR izquierda |
| 11 | | | **5 V** | VCC de los HC-SR04 y de los LM339, divisores de las LDR |
| 12 | | | **GND** | Tierra común (batería, driver, sensores, USB-TTL) |
| 13 | GPIO[10] | W5 | `LDR_VE[2]` | LM339 #1 pin 14 (OUT3): LDR derecha |
| 14 | GPIO[11] | AA15 | `LDR_VE[3]` | LM339 #1 pin 13 (OUT4): LDR atrás |
| 15 | GPIO[12] | AA14 | `LDR_CERCA` | LM339 #2 pin 2 (OUT1): luz cerca |
| 16 | GPIO[13] | | libre | |
| 17 | GPIO[14] | W12 | `MOT_PWMA` | TB6612FNG PWMA |
| 18 | GPIO[15] | AB13 | `MOT_AIN1` | TB6612FNG AIN1 |
| 19 | GPIO[16] | AB12 | `MOT_AIN2` | TB6612FNG AIN2 |
| 20 | GPIO[17] | Y11 | `MOT_STBY` | TB6612FNG STBY |
| 21 | GPIO[18] | AB11 | `MOT_BIN1` | TB6612FNG BIN1 |
| 22 | GPIO[19] | W11 | `MOT_BIN2` | TB6612FNG BIN2 |
| 23 | GPIO[20] | AB10 | `MOT_PWMB` | TB6612FNG PWMB |
| 24 | GPIO[21] | | libre | |
| 25 | GPIO[22] | AA9 | `ENC_L[0]` | KY-010 izquierdo, pin S |
| 26 | GPIO[23] | Y8 | `ENC_L[1]` | (sin conectar con KY-010; canal B si el encoder es de cuadratura) |
| 27 | GPIO[24] | AA8 | `ENC_R[0]` | KY-010 derecho, pin S |
| 28 | GPIO[25] | Y7 | `ENC_R[1]` | (sin conectar con KY-010; canal B si el encoder es de cuadratura) |
| 29 | | | **3.3 V** | VCC del TB6612FNG, pull-ups de los LM339, VCC de los KY-010 |
| 30 | | | **GND** | Tierra común (batería, driver, sensores, USB-TTL) |
| 31 | GPIO[26] | AA7 | `UART_TX` | RXD del convertidor USB-TTL |
| 32 | GPIO[27] | | libre | |
| 33 | GPIO[28] | | libre | |
| 34 | GPIO[29] | | libre | |
| 35 | GPIO[30] | | libre | |
| 36 | GPIO[31] | | libre | |
| 37 | GPIO[32] | | libre | |
| 38 | GPIO[33] | | libre | |
| 39 | GPIO[34] | | libre | |
| 40 | GPIO[35] | | libre | |

## Sensores ultrasónicos (×4)

```
HC-SR04          protoboard                     DE10-Lite
VCC  ----------------------------------------- header 11 (5 V)
TRIG ----------------------------------------- US_TRIG[i]
ECHO ----[ 1 kΩ ]----+------------------------ US_ECHO[i]
                     |
                  [ 2 kΩ ]
                     |
GND  ----------------+------------------------ GND
```

El divisor baja el ECHO de 5 V a 3.3 V (5 × 2 / 3). Con 2.2 kΩ quedan 3.4 V, también aceptable. El TRIG se maneja directo: el HC-SR04 reconoce 3.3 V como alto.

Ubicación: `[0]` al frente, `[1]` diagonal izquierda a 45°, `[2]` diagonal derecha a 45°, `[3]` atrás. Si las diagonales quedan al revés, los LEDs LEDR5 y LEDR6 se cruzan y el robot esquiva hacia el lado equivocado.

## LDR y comparadores LM339

Pines del LM339 (DIP-14): 1 OUT2, 2 OUT1, 3 VCC, 4 IN1−, 5 IN1+, 6 IN2−, 7 IN2+, 8 IN3−, 9 IN3+, 10 IN4−, 11 IN4+, 12 GND, 13 OUT4, 14 OUT3.

Por cada LDR (frente, izquierda, derecha, atrás), con el comparador 1, 2, 3 y 4 del LM339 #1:

```
5 V --[ 10 kΩ ]--+-- nodo --> IN− (pin 4, 6, 8 o 10)
                 |
               [LDR]
                 |
GND -------------+

5 V --[ pot 10 kΩ ]-- GND,  cursor --> IN+ (pin 5, 7, 9 u 11)

OUT (pin 2, 1, 14 o 13) --+--> LDR_VE[i]
                          |
3.3 V --[ 10 kΩ ]---------+          (pull-up a 3.3 V, NO a 5 V)
```

- Con más luz la LDR baja su resistencia, el nodo baja de voltaje y, cuando queda abajo del cursor, la salida del LM339 se libera y el pull-up la sube a 3.3 V. Así **alto = hay luz**, que es lo que espera `ldr_dir` (`LUZ_ACTIVA = '1'`).
- Si se arma al revés (LDR arriba y resistencia abajo), la lógica se invierte: se corrige cambiando `LUZ_ACTIVA` a `'0'` en `ldr_dir`, sin tocar el cableado.
- La salida del LM339 es de colector abierto: sin el pull-up no hay alto. La FPGA tiene además un pull-up débil interno en esas entradas, pero no sustituye al de 10 kΩ.
- **El cursor de cada potenciómetro debe quedar abajo de 3.5 V.** Con VCC de 5 V, el LM339 solo compara bien si al menos una de sus entradas está entre 0 y VCC − 1.5 V. El nodo de la LDR sí puede subir casi a 5 V en la oscuridad; mientras el umbral esté abajo de 3.5 V la salida es correcta.
- Cada LDR va dentro de un tubo opaco (popote negro o termofit) para que vea solo su dirección.

**Luz cerca (meta):** el nodo de la LDR del frente también va a IN− del comparador 1 del LM339 #2 (pin 4), con un quinto potenciómetro en IN+ (pin 5) calibrado más bajo. Su salida (pin 2), con su pull-up de 10 kΩ a 3.3 V, va a `LDR_CERCA`. Los otros 3 comparadores del LM339 #2 se quedan sin usar (entradas a GND).

**Calibración** (con SW8 en 0 para que los motores no se muevan):
1. Con el foco encendido a 1 m, girar el potenciómetro de cada LDR hasta que su LED (LEDR0 frente, LEDR1 izquierda, LEDR2 derecha, LEDR3 atrás) encienda cuando la LDR apunta al foco y se apague cuando no.
2. Con el foco a unos 10 cm del frente del robot, ajustar el quinto potenciómetro para que `C1` aparezca en la bitácora UART (o HEX4 muestre 6 al llegar). Lejos del foco debe quedar en `C0`.

## Driver TB6612FNG

| Pin del módulo | Va a |
|---|---|
| VM | + del portapilas (después del switch) |
| VCC | Header pin 29 (3.3 V) |
| GND (los dos) | GND común |
| AO1, AO2 | Motor izquierdo |
| BO1, BO2 | Motor derecho |
| PWMA, AIN1, AIN2 | `MOT_PWMA`, `MOT_AIN1`, `MOT_AIN2` (header 17, 18, 19) |
| STBY | `MOT_STBY` (header 20) |
| BIN1, BIN2, PWMB | `MOT_BIN1`, `MOT_BIN2`, `MOT_PWMB` (header 21, 22, 23) |

Con SW7 y SW8 arriba ambas ruedas deben girar hacia adelante. Si una gira al revés, se intercambian sus dos cables de motor (AO1 con AO2, o BO1 con BO2).

## Encoders (extra)

Cada KY-010 se monta de modo que el disco de ranuras del kit pase por su ranura.

| Pin del KY-010 | Va a |
|---|---|
| `-` | GND |
| centro (+) | Header pin 29 (3.3 V); así su salida no pasa de 3.3 V |
| S | `ENC_L[0]` (header 25) o `ENC_R[0]` (header 27) |

El top viene configurado para sensores de un canal (`UN_CANAL = true` en `robot_top`). Con encoders de cuadratura se conecta también el canal B (`ENC_L[1]`, `ENC_R[1]`) y se cambia ese generic a `false`. Si un encoder sale a 5 V, lleva el mismo divisor que el ECHO.

## UART (extra)

| Convertidor USB-TTL | Va a |
|---|---|
| RXD | `UART_TX` (header 31) |
| GND | Header 30 (GND) |
| TXD, VCC | Sin conectar |

Si el módulo tiene selector de voltaje, ponerlo en 3.3 V. En la PC: `python3 -m serial.tools.miniterm /dev/ttyUSB0 115200` (salir con Ctrl+]).

## VGA (extra)

Monitor al conector VGA de la tarjeta; no lleva cableado extra.

## Antes de conectar las pilas

1. Con la tarjeta desconectada, medir con el multímetro que no haya corto entre 5 V, 3.3 V y GND en la protoboard.
2. Confirmar que **ningún ECHO** llega a la FPGA sin su divisor y que los pull-ups de los LM339 van a 3.3 V.
3. Cargar el diseño con SW8 en 0 (motores deshabilitados) y revisar LEDs y displays: cada LDR enciende su LED, y con SW9 cada sensor marca una distancia razonable.
4. Levantar el robot (ruedas al aire), subir SW8 y SW7: ambas ruedas adelante. Bajar SW7 y presionar KEY0: debe girar despacio buscando la luz.
