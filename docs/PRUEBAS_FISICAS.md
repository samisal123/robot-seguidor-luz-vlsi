# Pruebas físicas y calibración

Lo que falta después de que el diseño compila: armar, calibrar y probar en la arena. Cada paso dice qué debe pasar; si no pasa, la columna de la derecha dice dónde buscar.

Los valores que se calibran son generics con valor por defecto en el VHDL. Para cambiarlos se edita el valor por defecto, se corre `quartus/compilar.sh` y luego `quartus/programar.sh`.

## 1. Banco (robot armado, ruedas al aire, SW8 en 0)

| Prueba | Qué debe pasar | Si no pasa |
|---|---|---|
| Cargar el diseño | HEX5 en 0, LEDR9 parpadea cada segundo | Revisar que el `.sof` sea el de `robot_top` |
| Tapar y destapar cada LDR con el foco encendido | LEDR0 a LEDR3 siguen a frente, izquierda, derecha y atrás | Calibrar su potenciómetro; si va al revés, `LUZ_ACTIVA` en `ldr_dir` |
| SW9 arriba, SW1-SW0 en 00, 01, 10, 11 | HEX2-HEX0 muestran la distancia de cada sensor; una mano a 10 cm da unos 10 | `---` fijo: falta eco (cable de ECHO o divisor); distancias cruzadas: sensores en el header equivocado |
| Mano a menos de 25 cm del frente | LEDR4 enciende; al retirarla se apaga después de 30 cm | |
| Terminal serial: `python3 -m serial.tools.miniterm /dev/ttyUSB0 115200` | Una línea cada 200 ms, por ejemplo `E0 V0 F120 I--- ...` | Cruzados RX y TX, o falta GND común |
| Monitor VGA | Banda gris (INICIO), barras de distancia y cruz de LDR | Cable o entrada del monitor |

## 2. Motores (ruedas al aire)

| Prueba | Qué debe pasar | Si no pasa |
|---|---|---|
| SW8 y SW7 arriba | Ambas ruedas hacia adelante, HEX3-HEX0 en 66 66 | Una rueda al revés: intercambiar sus dos cables de motor |
| Osciloscopio en PWMA (header 17) | 19.5 kHz, ciclo de trabajo de 66 % | |
| Bajar SW7 y presionar KEY0 | HEX5 en 1, gira despacio en su lugar (izquierda atrás, derecha adelante) | |
| Presionar KEY0 otra vez | Se detiene, HEX5 en 0 | |

## 3. Calibración en el piso

| Generic | Archivo | Cómo se calibra |
|---|---|---|
| `V_AVANCE`, `V_GIRO`, `V_BUSCA`, `V_REVERSA`, `V_CURVA` | `drive_cmd.vhd` (y `V_AVANCE` en `robot_top`) | Que avance recto a una velocidad que alcance a frenar antes de un obstáculo a 25 cm. Si no arranca en el piso, subir los valores |
| `T_GIRO_ESQ_MS` | `fsm_nav.vhd` | Medir cuánto tarda en girar 135° con `V_GIRO` y poner ese tiempo |
| `T_BUSCA_MS` | `fsm_nav.vhd` | Un poco más que una vuelta completa con `V_BUSCA` |
| `UMBRAL_F_CM`, `UMBRAL_D_CM` | `obst_eval.vhd` | Si choca, subirlos; si esquiva de más en pasillos, bajarlos |
| `VMAX_ENC` (extra PI) | `robot_top.vhd` | Con SW2 en 0, SW7 arriba y `V_AVANCE` temporalmente en 255, leer el campo `S` de la bitácora: ese número es VMAX |
| `T_META_MS` | `fsm_nav.vhd` | Si declara meta antes de llegar, subirlo |

## 4. Arena (1 m × 1.7 m)

Registrar cada corrida en la tabla. Las 5 corridas finales van al reporte y al video.

| Prueba | Qué debe pasar |
|---|---|
| Foco al frente sin obstáculos | BUSCAR (1) → SEGUIR (2) → META (6) |
| Foco detrás del robot | Gira hasta verlo y lo sigue |
| Un obstáculo entre el robot y el foco | ESQUIVA (3), lo rodea y vuelve a SEGUIR |
| Robot metido en una esquina | ESQUINA (4): reversa y giro de unos 135° |
| Atasco forzado (sostener el robot) | A los 3 s, ESCAPE (5) y LEDR8 encendido |
| Foco tapado a medio recorrido | A los 1.5 s, de vuelta a BUSCAR (evento 2) |
| SW2 arriba (PI) | Mismo comportamiento; con una rueda frenada a mano, su duty sube |

| Corrida | Posición inicial | Obstáculos | Tiempo a la meta | Choques | Llegó |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |

## 5. Para el reporte y el video

- Guardar la bitácora UART de cada corrida (`miniterm` con `--raw` y redirección a un archivo, o copiar de la terminal).
- Capturas: resumen de recursos de Quartus (`quartus/output_files/robot.fit.summary`), Fmax, diagrama de bloques del Block Editor y la FSM.
- Video de 5 minutos o menos: búsqueda, evasión y llegada a la meta (se graba en la entrega presencial).
