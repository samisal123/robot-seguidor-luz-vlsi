# Materiales

Todo se consigue en una tienda de electrónica (UNIT Electronics, Steren, AG Electrónica). La DE10-Lite y su cable USB los presta el laboratorio.

## Por comprar

| Cant. | Artículo | Para qué | Notas |
|---|---|---|---|
| 2 | Teclado matricial de membrana 4 × 4 (16 teclas, conector de 8 pines) | teclados 1 y 2 | el de 1 2 3 A / 4 5 6 B / 7 8 9 C / * 0 # D |
| 1 | Módulo amplificador PAM8403 (2 × 3 W, 5 V) | amplificar el audio | de preferencia con pines o terminales ya soldados; la versión con potenciómetro de volumen también sirve |
| 1 | Bocina de 8 Ω, de 0.5 a 3 W (5 a 8 cm) | salida de audio | con cables o terminales para conectarla al PAM8403 |
| 3 | Resistencia de 1 kΩ, 1/4 W | R1 y R2 del filtro, R4 del divisor | café, negro, rojo |
| 1 | Resistencia de 10 kΩ, 1/4 W | R3 del divisor | café, negro, naranja |
| 2 | Capacitor cerámico de 10 nF (código 103) | C1 y C2 del filtro | |
| 1 | Capacitor electrolítico de 10 µF, 16 V o más | C3, quita la componente de DC | tiene polaridad: la pata larga es + |
| 1 | Protoboard de 400 puntos (o la que ya tengan) | filtro y divisor | |
| 1 | Paquete de jumpers dupont macho-hembra (40) | 16 para los teclados, 4 para el audio | macho al teclado y a la protoboard, hembra al header |
| 1 | Paquete de jumpers macho-macho | conexiones en la protoboard y al PAM8403 | |

Opcional: tira de pines macho y cautín si el PAM8403 viene sin pines; un convertidor VGA a HDMI activo si el monitor del laboratorio no tiene entrada VGA.

## Ya se tiene

- Tarjeta DE10-Lite (MAX 10, 10M50DAF484C7G) con su cable USB.
- PC con Quartus Prime Lite (25.1std).
- Monitor con entrada VGA y cable VGA.

## Por qué estas piezas

- **Teclados 4 × 4**: 16 teclas con solo 8 cables cada uno; con dos se tienen 24 notas (dos octavas cromáticas) y 8 teclas de función. Las columnas usan el pull-up interno de la FPGA, así que no llevan resistencias.
- **Filtro RC de 2 etapas**: convierte el PWM de 195.3 kHz en la señal de audio (−3 dB en unos 6 kHz).
- **Capacitor de 10 µF y divisor 10 kΩ / 1 kΩ**: quitan la DC de 1.65 V y bajan la señal a lo que acepta el PAM8403 (ganancia fija de 24 dB) sin saturarlo.
- **PAM8403**: amplificador clase D de 5 V que se alimenta del header de la tarjeta (pin 11).
