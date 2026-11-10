# Materiales

Todo se consigue en UNIT Electronics (sucursal Copilco: Av. Copilco 357, lunes a viernes de 8:00 a 17:00) o en cualquier tienda de electrónica.

## Ya se tiene

- Tarjeta EP2C5T144 (Cyclone II EP2C5T144C8).
- 2 teclados matriciales 4 × 4, PAM8403, bocina de 8 Ω, resistencias, capacitores, protoboard y jumpers (ver la tabla de abajo).
- PC del laboratorio (se le instala Quartus II 13.0 SP1, ver TAREA-018 en `COORDINACION.md`).

## Por comprar para la EP2C5T144

| Cant. | Artículo | Para qué | Precio en UNIT |
|---|---|---|---|
| 1 | Programador USB Blaster ALTERA CPLD/FPGA | programar la tarjeta (trae su cable de 10 pines) | $84 |
| 1 | Eliminador 5 V 2 A con plug | alimentar la tarjeta y el PAM8403 | $70 |
| 1 | Par conector plug jack macho hembra (con bornera) | llevar los 5 V del eliminador a la protoboard y de la protoboard al jack de la tarjeta | $14 |
| 1 | DB15 adaptador hembra con terminales clemas (variante hembra) | conector VGA para el monitor | $68 a $79 |
| 3 | Resistencia de 270 Ω, 1/4 W | rojo, verde y azul del VGA | rojo, violeta, café |
| 3 | Botón táctil de 6 × 6 mm (4 patas) | MODO, ACCIÓN y METRÓNOMO | |
| | Jumpers macho-hembra adicionales | 16 para los teclados, 8 para botones, audio y VGA | |

También se necesita un monitor con entrada VGA y un cable VGA macho-macho (o un convertidor VGA a HDMI activo).

## Ya comprado

| Cant. | Artículo | Para qué |
|---|---|---|
| 2 | Teclado matricial de membrana 4 × 4 | teclados 1 y 2 |
| 1 | Módulo amplificador PAM8403 (2 × 3 W, 5 V) | amplificar el audio |
| 1 | Bocina de 8 Ω, de 0.5 a 3 W | salida de audio |
| 3 | Resistencia de 1 kΩ | R1 y R2 del filtro, R4 del divisor |
| 1 | Resistencia de 10 kΩ | R3 del divisor |
| 2 | Capacitor cerámico de 10 nF (103) | C1 y C2 del filtro |
| 1 | Capacitor electrolítico de 10 µF, 16 V o más | C3, quita la componente de DC |
| 1 | Protoboard | filtro, divisor, botones y VGA |
| | Jumpers macho-hembra y macho-macho | conexiones |

## Por qué estas piezas

- **USB Blaster**: la EP2C5T144 no trae programador integrado; se programa por su conector JTAG de 10 pines.
- **Eliminador de 5 V y conectores con bornera**: la tarjeta se alimenta por un jack de 2.1 mm con 5 V y el PAM8403 también usa 5 V; con los dos conectores sale todo de una sola fuente y la tierra es común.
- **VGA con 3 resistencias**: la tarjeta no tiene salida de video. Un bit por color da 8 colores; 270 Ω en serie con los 75 Ω del monitor bajan los 3.3 V de la FPGA a unos 0.7 V.
- **Botones**: la tarjeta solo tiene un botón (RESET) y no tiene switches; los modos, la acción y el metrónomo van en tres botones con el pull-up interno de la FPGA.
- **Teclados 4 × 4**: 16 teclas con solo 8 cables cada uno; con dos se tienen 24 notas (dos octavas cromáticas) y 8 teclas de función.
- **Filtro RC de 2 etapas**: convierte el PWM de 97.7 kHz en la señal de audio (−3 dB en unos 6 kHz).
- **Capacitor de 10 µF y divisor 10 kΩ / 1 kΩ**: quitan la DC de 1.65 V y bajan la señal a lo que acepta el PAM8403 (ganancia fija de 24 dB) sin saturarlo.
- **PAM8403**: amplificador clase D de 5 V para la bocina de 8 Ω.
