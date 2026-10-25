# Hardware

## Decisiones

| Decisión | Elegido | Por qué |
|---|---|---|
| FPGA | DE10-Lite (MAX 10, 10M50DAF484C7G), préstamo del profesor | Es la de las prácticas; reloj de 50 MHz |
| Driver | TB6612FNG | Acepta lógica de 3.3 V y PWM hasta 100 kHz. El L293D de la propuesta del enunciado solo está especificado para conmutar hasta 5 kHz y el proyecto pide 18 kHz o más. El L298N funciona con el mismo cableado como respaldo |
| Motores | 2 motorreductores TT 48:1 del kit ZK-2WD | Baratos, ya vienen con chasis y discos de encoder |
| Encoders (extra) | 2 sensores de ranura KY-010 con los discos del kit, un canal | Lo más barato para el PI; `encoder_vel` también acepta cuadratura |
| Luz | 4 LDR con LM339, más un segundo comparador para "luz cerca" | El enunciado pide 4 LDR; el segundo umbral distingue "veo el foco" de "llegué" |
| Distancia | 4 HC-SR04: frente, diagonales a 45° y atrás | Turnados cada 30 ms para que no se escuchen entre sí |
| Energía | Power bank USB para la tarjeta y 4 AA (6 V) para los motores | Sin regulador extra; los sensores toman 5 V del header de la tarjeta |

## Notas eléctricas que no se pueden saltar

1. **Los GPIO de la DE10-Lite son de 3.3 V.** El ECHO de cada HC-SR04 sale a 5 V y entra por un divisor de 1 kΩ y 2 kΩ.
2. **Las salidas del LM339 son de colector abierto.** Cada una lleva su pull-up de 10 kΩ a **3.3 V**, no a 5 V. El esquema de la guía del proyecto no lo dibuja.
3. **El VCC lógico del TB6612FNG va a 3.3 V**, para que las señales de la FPGA cuenten como alto.
4. **Tierra común** entre pilas, driver, sensores, USB-TTL y la tarjeta.
5. **Polaridad de las LDR:** con la LDR del nodo a GND y la resistencia fija a 5 V, más luz da alto a la salida del comparador. Si se arma al revés, se cambia `LUZ_ACTIVA` en `ldr_dir`.
6. **Umbrales del LM339 abajo de 3.5 V:** con VCC de 5 V solo compara bien si al menos una entrada está entre 0 y VCC − 1.5 V; por eso el cursor de cada potenciómetro se calibra abajo de 3.5 V.

El cableado completo, pin por pin, está en [CABLEADO.md](CABLEADO.md) y la lista de compras con precios en [MATERIALES.md](MATERIALES.md).

## Señales en el header GPIO

| Señal | Dirección | Bits |
|---|---|---|
| `US_TRIG[3:0]` | salida | 4 |
| `US_ECHO[3:0]` | entrada | 4 |
| `LDR_VE[3:0]` | entrada | 4 |
| `LDR_CERCA` | entrada | 1 |
| `MOT_PWMA`, `MOT_AIN1`, `MOT_AIN2`, `MOT_STBY`, `MOT_BIN1`, `MOT_BIN2`, `MOT_PWMB` | salida | 7 |
| `ENC_L[1:0]`, `ENC_R[1:0]` | entrada | 4 |
| `UART_TX` | salida | 1 |
| **Total** | | **25 de 36** |

## Pendiente del equipo

- [ ] Fecha real de entrega y nombres del equipo (para el README y el reporte).

## Fuentes

- [L293D, STMicroelectronics: descripción del producto y datasheet](https://www.st.com/content/st_com/en/products/motor-drivers/brushed-dc-motor-drivers/l293d.html)
- [Manual de usuario de la DE10-Lite (Terasic)](https://cw.fel.cvut.cz/wiki/_media/courses/b2m37mam/tutorials/dev_kits/de10-lite_user_manual.pdf): header GPIO, voltajes y alimentación
- [Golden Top de la DE10-Lite](https://github.com/janaite/fpga-de10lite-golden-top): asignación de pines de la FPGA
- [LM339, Texas Instruments](https://www.ti.com/document-viewer/LM339/datasheet/GUID-7CC8453B-302C-468D-AF47-4D3DA618CCA4): rango de modo común de 0 a VCC − 1.5 V
