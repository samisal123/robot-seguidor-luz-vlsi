# Materiales

Todo se consigue en UNIT Electronics (sucursal Copilco: Av. Copilco 357, lunes a viernes de 8:00 a 17:00) o en cualquier tienda de electrónica.

## Ya se tiene

| Cant. | Artículo | Para qué |
|---|---|---|
| 1 | Tarjeta EP2C5T144 (Cyclone II EP2C5T144C8) | el sintetizador |
| 1 | Programador USB Blaster ALTERA CPLD/FPGA | programar la tarjeta (con su cable de 10 pines) |
| 1 | Eliminador 5 V 2 A con plug | alimentar la tarjeta y el PAM8403 |
| 1 | Par conector plug jack macho hembra con bornera (5.5 × 2.1 mm) | llevar los 5 V del eliminador a la protoboard y de la protoboard al jack de la tarjeta |
| 2 | Teclado matricial de membrana 4 × 4 | teclados 1 y 2 (el 2 trae también MODO, ACCIÓN, METRÓNOMO y VOLUMEN) |
| 1 | Módulo amplificador PAM8403 (2 × 3 W, 5 V) | amplificar el audio |
| 1 | Bocina de 8 Ω | salida de audio |
| 3 | Resistencia de 1 kΩ (café, negro, rojo) | R1 y R2 del filtro (una de sobra) |
| 2 | Capacitor cerámico de 10 nF (103) | C1 y C2 del filtro |
| 1 | Capacitor electrolítico de 10 µF | C3, quita la componente de DC |
| 1 | Potenciómetro | baja el nivel antes del PAM8403 (volumen analógico) |

## Por comprar

| Cant. | Artículo | Para qué |
|---|---|---|
| 1 | Protoboard (400 u 830 puntos) | filtro, potenciómetro, PAM8403 y los 5 V |
| 25 | Jumpers macho-hembra | 16 para los teclados (de la tarjeta al conector de cada teclado), audio, GND y los 5 V |
| 15 | Jumpers macho-macho | conexiones dentro de la protoboard y a las borneras |

No hacen falta botones, monitor ni conector VGA: los controles van en el teclado 2 y el estado se ve en los LEDs de la tarjeta.

## Por qué estas piezas

- **USB Blaster**: la EP2C5T144 no trae programador integrado; se programa por su conector JTAG de 10 pines.
- **Eliminador de 5 V y conectores con bornera**: la tarjeta se alimenta por un jack de 2.1 mm con 5 V y el PAM8403 también usa 5 V; con los dos conectores sale todo de una sola fuente y la tierra es común.
- **Teclados 4 × 4**: 16 teclas con solo 8 cables cada uno; con dos se tienen 24 notas (dos octavas cromáticas) y 8 teclas de función, que alcanzan para todos los controles.
- **Filtro RC de 2 etapas**: convierte el PWM de 97.7 kHz en la señal de audio (−3 dB en unos 6 kHz).
- **Capacitor de 10 µF y potenciómetro**: quitan la DC de 1.65 V y bajan la señal a lo que acepta el PAM8403 (ganancia fija de 24 dB) sin saturarlo.
- **PAM8403**: amplificador clase D de 5 V para la bocina de 8 Ω.
