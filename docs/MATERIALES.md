# Lista de materiales

Precios de UNIT Electronics (tienda en línea y sucursal Copilco), consultados el 25 de octubre de 2026, con IVA. Pueden cambiar; las existencias son las de la tienda en línea.

## Para que el robot funcione

| Cant. | Artículo | Precio unitario | Subtotal | Nota |
|---|---|---|---|---|
| 1 | [Kit carrito robot ZK-2WD](https://uelectronics.com/producto/kit-carrito-robot-seguidor-lineas-con-accesorios/): chasis de acrílico, 2 motorreductores TT 48:1, llantas, rueda loca, portapilas de 4 AA, switch y discos de encoder | $117.00 | $117.00 | Cabe en 20 × 20 × 20 cm |
| 1 | [Driver doble puente H TB6612FNG](https://uelectronics.com/producto/doble-puente-h-tb6612fng/) | $54.00 | $54.00 | PWM hasta 100 kHz con lógica de 3.3 V |
| 4 | [Sensor ultrasónico HC-SR04](https://uelectronics.com/producto/sensor-ultrasonico-hc-sr04/) | $32.00 | $128.00 | |
| 4 | [Fotorresistencia LDR 5 mm](https://uelectronics.com/producto/fotoresistencia-ldr-5537/) | $2.00 | $8.00 | UNIT vende la 5537, equivalente a la GL5528 |
| 2 | [Comparador LM339](https://uelectronics.com/producto/lm339-comparador-de-voltaje/) | $8.00 | $16.00 | Uno para "veo luz" (4 LDR) y otro para "luz cerca" (solo se usa 1 de sus 4 comparadores) |
| 5 | [Potenciómetro de precisión 10 kΩ (3362P)](https://uelectronics.com/producto/potenciometro-de-precision-3362p/) | $7.00 | $35.00 | 4 umbrales de luz y 1 de luz cerca |
| 9 | [Resistencia 10 kΩ 1/4 W](https://uelectronics.com/producto/resistencia-de-1-ohm-1m-ohms-1-4w/) | $0.50 | $4.50 | 4 divisores de LDR y 5 pull-ups de salidas del LM339 |
| 4 | Resistencia 1 kΩ 1/4 W | $0.50 | $2.00 | Divisores de ECHO |
| 4 | Resistencia 2 kΩ (o 2.2 kΩ) 1/4 W | $0.50 | $2.00 | Divisores de ECHO |
| 1 | [Protoboard de 400 puntos](https://uelectronics.com/producto/protoboard-de-400pts-y-830pts-blanco-o-transparente/) | $18.00 | $18.00 | Va arriba del chasis |
| 1 | [Cables dupont macho-hembra, 40 pzs](https://uelectronics.com/producto/cables-dupont-extra-largos-30cm-hh-mh-mm/) | $23.00 | $23.00 | Del header GPIO a la protoboard |
| 1 | [Cables dupont macho-macho, 40 pzs](https://uelectronics.com/producto/cables-dupont-cortos-10cm-hh-mh-mm/) | $20.00 | $20.00 | En la protoboard |
| 4 | Pilas AA | sin precio | | Para el portapilas del kit (6 V a los motores) |
| | **Subtotal** | | **$427.50** | más pilas |

Lo que no hay que comprar: la DE10-Lite (préstamo del profesor), su cable USB, una power bank para alimentar la tarjeta (la que ya tengan) y la lámpara para probar.

## Características extra (+10 pts cada una)

| Cant. | Artículo | Precio unitario | Subtotal | Para qué |
|---|---|---|---|---|
| 2 | [Sensor foto interruptor KY-010](https://uelectronics.com/producto/sensor-foto-interruptor-ky-010/) | $18.00 | $36.00 | Encoders con los discos que trae el kit, para el control PI |
| 1 | [Convertidor USB a TTL CH340E](https://uelectronics.com/producto/unit-ch340e-modulo-usb-a-ttl/) o [CP2102](https://uelectronics.com/producto/cp2102-convertidor-usb-a-ttl/) | $31.00 / $64.00 | $31.00 | Ver la bitácora UART en la PC. Es el mismo que pide la Práctica 5: se compra uno para los dos |
| | Cable VGA y monitor | del laboratorio | | Tablero de depuración |
| | **Subtotal extras** | | **$67.00** | |

**Total con extras: $494.50** más pilas.

## Opciones

- **Batería recargable:** [portapilas 2 × 18650](https://uelectronics.com/producto/porta-pila-para-baterias-18650/) ($11) y 2 [pilas 18650](https://uelectronics.com/producto/bateria-18650-3-7v-2200mah/) ($60 c/u). Dan 7.4 V: los motores TT son de 3 a 6 V, así que hay que bajar los duty de `drive_cmd` (por ejemplo `V_AVANCE` a 130).
- **Driver L298N** ([$59](https://uelectronics.com/producto/l298n-modulo-driver-motor-a-pasos/)) en lugar del TB6612FNG: funciona con el mismo cableado de señales (ENA = PWMA, IN1/IN2 = AIN1/AIN2, etc.), pero pierde unos 2 V y se calienta más. No tiene STBY: ese pin se queda sin conectar.
- **Encoders magnéticos:** el [GM25-370 con encoder Hall](https://uelectronics.com/producto/gm-25-370-motor-con-encoder-12v-dc-140rpm-330rpm/) cuesta $181 por motor. Da cuadratura real (canal A y B), pero sube mucho el costo; los KY-010 con los discos del kit alcanzan para el PI.

## Ferretería y papelería

Tornillos y separadores M3 para montar la DE10-Lite, cinchos, cinta doble cara, y popotes negros o termofit para hacer los tubos que vuelven direccional a cada LDR.

## Fuente

- [UNIT Electronics](https://uelectronics.com), precios del 25 de octubre de 2026.
