# Hardware

## Supuestos

- **FPGA:** DE10-Lite (MAX 10, 10M50DAF484C7G) con reloj de 50 MHz, la misma del manual de prácticas. Sus GPIO son de 3.3 V y **no toleran 5 V**.
- Si la tarjeta resulta otra, se cambia el dispositivo en `quartus/crear_proyecto.tcl`.

## Lista de materiales propuesta

| Cant. | Parte | Uso | Nota |
|---|---|---|---|
| 1 | DE10-Lite | Control | |
| 2 | Motorreductor DC con encoder de cuadratura (tipo N20 o JGA25-370) | Tracción | El encoder habilita el extra de PI |
| 1 | Driver TB6612FNG (recomendado) o L298N | Potencia | Ver nota 3 |
| 4 | HC-SR04 | Distancia | Ver nota 1 |
| 4 | LDR (por ejemplo GL5528) | Luz | Con tubo o pared opaca para que cada una sea direccional |
| 1 o 2 | LM339 + potenciómetros de 10 kΩ + resistencias de 10 kΩ | Comparadores de luz | Ver notas 2 y 6 |
| 1 | Batería (2S Li-ion de 7.4 V o pack de 12 V) + regulador reductor a 5 V | Energía | Tierra común para todo |
| 1 | Chasis de máximo 20 × 20 × 20 cm con rueda loca | Estructura | |

## Notas eléctricas que no se pueden saltar

1. **El ECHO del HC-SR04 sale a 5 V.** Hay que bajarlo con un divisor (1 kΩ en serie y 2 kΩ a tierra, unos 3.3 V) antes de la FPGA. El TRIG sí se maneja directo con 3.3 V.
2. **El LM339 tiene salida de colector abierto.** La resistencia de pull-up de cada salida va a **3.3 V**, no a 5 V. El esquema de la guía no dibuja ese pull-up.
3. **Frecuencia del driver.** El enunciado pide PWM de 18 kHz o más, pero el datasheet del L293D (STMicroelectronics) lo declara apto para conmutar solo hasta 5 kHz, así que el L293D de la propuesta queda fuera de especificación. El TB6612FNG trabaja con lógica de 3.3 V y PWM de hasta 100 kHz; el L298N es la alternativa barata, con más caída de voltaje y más calor.
4. **Tierra común** entre batería, driver, sensores y FPGA.
5. **Encoders:** si su salida es de 5 V, mismo divisor que el ECHO, o alimentarlos a 3.3 V si lo permiten.
6. **Meta:** para distinguir "veo luz" de "estoy junto al foco" hace falta un segundo umbral por LDR (un segundo LM339) o leer las LDR con el ADC de la MAX 10.

## Ubicación de sensores (propuesta)

- **Ultrasonido:** frente, diagonal izquierda a 45°, diagonal derecha a 45° y atrás.
- **LDR:** frente, izquierda, derecha y atrás, a 90° entre sí, separadas por paredes opacas.

## Conexión a la DE10-Lite

Por el header GPIO de 2 × 20 (3.3 V). El mapa exacto de pines se genera en `quartus/pines.tcl`, verificado contra el manual de la DE10-Lite.

| Señal | Dirección | Bits |
|---|---|---|
| `US_TRIG[3:0]` | salida | 4 |
| `US_ECHO[3:0]` | entrada | 4 |
| `LDR_VE[3:0]` | entrada | 4 |
| `LDR_CERCA[3:0]` (si hay segundo umbral) | entrada | 4 |
| `MOT_PWM_L`, `MOT_PWM_R` | salida | 2 |
| `MOT_IN[3:0]` | salida | 4 |
| `MOT_STBY` (solo TB6612FNG) | salida | 1 |
| `ENC_L_A`, `ENC_L_B`, `ENC_R_A`, `ENC_R_B` | entrada | 4 |
| `UART_TX` | salida | 1 |
| **Total** | | **28 de 36** |

## Decisiones pendientes (equipo)

- [ ] Confirmar que la tarjeta es la DE10-Lite.
- [ ] Driver: TB6612FNG, L298N u otro.
- [ ] ¿Motores con encoder?
- [ ] Meta: segundo LM339 o ADC.
- [ ] Fecha real de entrega y nombres del equipo.

## Fuentes

- [L293D, STMicroelectronics: descripción del producto y datasheet](https://www.st.com/content/st_com/en/products/motor-drivers/brushed-dc-motor-drivers/l293d.html)
