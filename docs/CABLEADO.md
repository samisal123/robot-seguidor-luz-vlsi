# Cableado

Tarjeta: **EP2C5T144** (tarjeta mínima con la Cyclone II EP2C5T144C8, oscilador de 50 MHz, memoria de configuración EPCS4, 3 LEDs y un botón de reset). Los teclados y el audio se conectan a sus conectores de pines; el número de cada pin de la FPGA está impreso junto al conector.

Los pines de E/S son de **3.3 V y no toleran 5 V**. Los 5 V solo van al jack de alimentación de la tarjeta y al amplificador PAM8403.

**Pines que no se usan nunca:** 26 y 81 (unidos a 1.2 V en la tarjeta), 27 y 80 (unidos a GND), 73 (red RC de reset), 17 (reloj), 144 (botón RESET) y los de configuración y JTAG. El proyecto de Quartus deja todos los pines sin uso como entradas en alta impedancia; si alguna vez se crea un proyecto nuevo hay que hacer lo mismo (Assignments > Device > Device and Pin Options > Unused Pins > *As input tri-stated*), porque si Quartus pusiera a 0 los pines 26 y 81 haría un corto con el regulador de 1.2 V.

Las asignaciones están en `quartus/pines.tcl`.

## Resumen

| Bloque | Pines de la FPGA | Notas |
|---|---|---|
| Teclado 1 (octava base) | filas 44, 45, 42, 43; columnas 40, 41, 31, 25 | conector visto de frente, de izquierda a derecha: 25, 31, 41, 40, 43, 42, 45, 44 |
| Teclado 2 (octava base + 1) | filas 60, 76, 55, 58; columnas 51, 52, 47, 48 | conector visto de frente, de izquierda a derecha: 48, 47, 52, 51, 58, 55, 76, 60 |
| Audio (PWM) | 93 | entrada del filtro RC |
| LEDs D2, D4, D5 | 3, 7, 9 | ya están en la tarjeta |
| RESET | 144 | botón de la tarjeta |
| Reloj | 17 | oscilador de 50 MHz de la tarjeta |
| GND | pines marcados GND en los conectores | uno solo para todo: protoboard y PAM8403 |

## Alimentación

Un eliminador de 5 V 2 A alimenta la tarjeta y el amplificador:

```
eliminador 5 V --> jack hembra con bornera --> riel + (5 V) y riel - (GND) de la protoboard
                                                  |
                       plug macho con bornera <---+  --> jack de la tarjeta EP2C5T144
                       PAM8403 VCC y GND      <---+
```

- En las borneras respetar la polaridad: el centro del plug es **+**.
- El USB-Blaster **no** alimenta la tarjeta: para programarla tiene que estar encendida.
- La tarjeta saca 3.3 V y 1.2 V de sus propios reguladores.

## Teclados matriciales 4 × 4

Los teclados de membrana tienen un conector hembra de 8 pines: los pines 1 a 4 son las filas y 5 a 8 las columnas. **En los teclados del proyecto el pin 1 es el de la derecha** (viéndolos de frente con el conector abajo); se comprobó en la tarjeta el 14 de noviembre: con el orden contrario solo funcionaba la tecla A. Se usan 8 jumpers macho-hembra por teclado (macho al teclado, hembra al pin de la tarjeta). La forma fácil de conectarlos: recorrer el conector **de izquierda a derecha** y poner los jumpers en este orden:

| Posición en el conector (izquierda → derecha) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Pin del teclado | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 |
| Función | col. 4 | col. 3 | col. 2 | col. 1 | fila 4 | fila 3 | fila 2 | fila 1 |
| Teclado 1 → pin FPGA | 25 | 31 | 41 | 40 | 43 | 42 | 45 | 44 |
| Teclado 2 → pin FPGA | 48 | 47 | 52 | 51 | 58 | 55 | 76 | 60 |

Si otro teclado trae el pin 1 a la izquierda, se puede confirmar con el multímetro en continuidad (al presionar la tecla **1** se unen los pines 1 y 5, y con la **D** los pines 4 y 8) y voltear el orden en `quartus/pines.tcl`. Una prueba rápida sin multímetro: si solo funciona la A, el conector está al revés.

- Las filas se manejan en colector abierto: la FPGA pone en `'0'` solo la fila que lee y deja las otras en alta impedancia. Así, dos teclas presionadas en la misma columna nunca ponen en corto dos salidas.
- Las columnas usan el pull-up interno de la Cyclone II (`WEAK_PULL_UP_RESISTOR` en `pines.tcl`); no hacen falta resistencias externas.
- El barrido lee una fila por milisegundo y cada tecla pasa por un antirrebote de 5 lecturas (20 ms).

Mapa de teclas (igual en los dos teclados; el teclado 2 suena una octava arriba):

```
 1  2  3  A        C   C#  D   | A
 4  5  6  B   ->   D#  E   F   | B
 7  8  9  C        F#  G   G#  | C
 *  0  #  D        A   A#  B   | D
```

Si al tocar una tecla suena otra nota, el conector quedó volteado o recorrido: revisar el orden de la tabla.

## Controles

No hay botones externos: los controles son las teclas de la columna derecha del **teclado 2**.

| Tecla del teclado 2 | Función |
|---|---|
| A | MODO: pasa al siguiente modo (interpretación, grabación, reproducción, configuración) |
| B | ACCIÓN: en grabación inicia o finaliza; en reproducción inicia o detiene |
| C | METRÓNOMO: lo enciende o lo apaga |
| D | VOLUMEN: siguiente nivel (silencio, 1, 2, 3, 4 y otra vez silencio) |

El botón RESET de la tarjeta reinicia el sintetizador (regresa a interpretación con los parámetros de fábrica; la secuencia grabada se pierde). Lo que muestran los LEDs D2, D4 y D5 en cada modo está en [ARQUITECTURA.md](ARQUITECTURA.md#interfaz-de-usuario).

## Salida de audio

```
pin 93 (AUDIO_PWM)
    |
   [R1 1 kΩ]
    |
    +--------+
    |        |
   [R2 1 kΩ] = C1 10 nF (103)
    |        |
    +---+   GND
    |   |
    |   = C2 10 nF (103)
    |   |
    |  GND
    |
  (+) C3 10 µF electrolítico
  (-)
    |
    +---------------------------- L de la entrada (input) del módulo

                             Módulo PAM8403 (HW-012, con perilla)
                             power +    <- riel + de la protoboard
                             power -    <- riel - de la protoboard
                             G de la entrada <- GND
                             R de la entrada: sin conectar
                             Lout + / Lout -  -> bocina 8 Ω
```

- **Filtro RC de 2 etapas** (R1-C1, R2-C2): convierte el PWM de 97.7 kHz en la señal de audio. Corte a −3 dB en unos 6 kHz y unos −32 dB a 97.7 kHz. Las resistencias de 1 kΩ son café, negro, rojo; los capacitores de 10 nF traen grabado 103.
- **C3** quita la componente de DC (1.65 V, la mitad del PWM). Su lado **+** (la pata larga) va hacia el filtro.
- **Perilla del módulo**: el módulo HW-012 trae un potenciómetro doble con interruptor entre la entrada y el amplificador; baja el nivel para que el PAM8403 (ganancia fija de 24 dB) no se sature con la señal completa (±1.65 V). Es el volumen analógico: **empezar al mínimo** (girada hasta el clic, que además apaga el módulo) e ir subiendo.
- **Pines del módulo**: sus agujeros (R, G, L de la entrada; power + y −; Lout y Rout) no traen pines; hay que soldarle una tira de pines o cables.
- **Bocina**: va entre Lout + y Lout −. Ninguna de las dos salidas del PAM8403 es tierra (es puente BTL): **nunca conectar la bocina ni L− a GND**.
- Todas las tierras (filtro y PAM8403) van al mismo GND que la tarjeta.

El volumen digital (0 a 4) se cambia con la tecla D del teclado 2 o en el modo configuración.

## Programación

El USB-Blaster va al conector **JTAG** de 10 pines de la tarjeta (la marca de la pata 1 del cable, normalmente el hilo rojo, hacia la marca de la pata 1 del conector). Con la tarjeta encendida:

- `sh quartus/programar.sh` carga el diseño por JTAG; se pierde al apagar.
- En Linux, si `jtagconfig` dice `Insufficient port permissions`, falta una regla de udev (una sola vez, con sudo):
  `echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"' | sudo tee /etc/udev/rules.d/51-usbblaster.rules`, luego `sudo udevadm control --reload-rules && sudo udevadm trigger`, `killall jtagd` y reconectar el USB-Blaster. `jtagconfig` debe mostrar `020B10DD EP2C5`.
- `sh quartus/grabar_flash.sh` lo graba en la EPCS4 por el conector **AS** (mover el cable a ese conector); así la tarjeta arranca con el sintetizador cada vez que se enciende.

## Lista de conexiones para revisar antes de encender

1. Eliminador al jack hembra con bornera; + y − a los rieles de la protoboard; del riel al plug macho y de ahí al jack de la tarjeta, con el + al centro.
2. GND de la tarjeta unido al riel − de la protoboard.
3. Teclado 1 y teclado 2 en los pines de la tabla, en el orden de la tabla.
4. Pin 93 a R1; R1-R2-C3 en serie; C1 y C2 a GND; C3 con el + hacia R2.
5. C3 (−) a la entrada L del módulo; G de la entrada a GND; perilla al mínimo.
6. PAM8403: VCC al riel de 5 V, GND al riel de GND.
7. Bocina entre L+ y L−, sin tocar GND.
8. Ningún cable de 5 V va a un pin de la FPGA, y nada se conecta a los pines 26, 27, 73, 80 y 81.
