# TAREA-008
Estado: OK (verificación en simulación; la compilación en Quartus es TAREA-009)
Fecha: 2026-10-25
Equipo: Claude en la nube (GHDL 4.1.0, sin Quartus)

## Qué se hizo

Módulos nuevos en `rtl/`: `robot_pkg`, `ultra_sched`, `ldr_dir`, `obst_eval`, `stall_detect`, `fsm_nav`, `drive_cmd`, `encoder_vel`, `pi_ctrl`, `uart_tx`, `telemetria`, `vga_debug` y `robot_top` completo. Pines en `quartus/pines.tcl` (110 asignaciones, sin pines repetidos), generados del `DE10_LITE_Golden_Top.qsf` de Terasic y con la numeración del header verificada contra el manual de usuario de la DE10-Lite. Scripts `quartus/compilar.sh` y `quartus/programar.sh`.

## Regresión completa (`sim/correr.sh`)

Log completo: `logs/sim_todos.log`.

```
sim/tb_debounce.vhd:128:9:@269011750ns:(report note): tb_debounce: OK
== tb_debounce: PASA
sim/tb_drive_cmd.vhd:105:9:@16235ns:(report note): tb_drive_cmd: OK
== tb_drive_cmd: PASA
sim/tb_encoder_vel.vhd:105:9:@1625ns:(report note): tb_encoder_vel: OK
== tb_encoder_vel: PASA
sim/tb_fsm_nav.vhd:226:9:@312325ns:(report note): tb_fsm_nav: OK
== tb_fsm_nav: PASA
sim/tb_hcsr04.vhd:174:9:@151346030ns:(report note): tb_hcsr04: OK
== tb_hcsr04: PASA
sim/tb_ldr_dir.vhd:132:9:@6870ns:(report note): tb_ldr_dir: OK
== tb_ldr_dir: PASA
sim/tb_motor_if.vhd:134:9:@132012750ns:(report note): tb_motor_if: OK
== tb_motor_if: PASA
sim/tb_obst_eval.vhd:67:9:@1080ns:(report note): tb_obst_eval: OK
== tb_obst_eval: PASA
sim/tb_pi_ctrl.vhd:97:9:@18115ns:(report note): tb_pi_ctrl: OK
== tb_pi_ctrl: PASA
sim/tb_pwm_8b.vhd:103:9:@1177790ns:(report note): tb_pwm_8b: OK
== tb_pwm_8b: PASA
sim/tb_robot_top.vhd:224:9:@2425399750ns:(report note): tb_robot_top: OK
== tb_robot_top: PASA
sim/tb_seg7_disp.vhd:168:9:@62711ns:(report note): tb_seg7_disp: OK
== tb_seg7_disp: PASA
sim/tb_stall_detect.vhd:156:9:@17075ns:(report note): tb_stall_detect: OK
== tb_stall_detect: PASA
sim/tb_sync_2ff.vhd:60:9:@711ns:(report note): tb_sync_2ff: OK
== tb_sync_2ff: PASA
sim/tb_telemetria.vhd:136:9:@22706500ns:(report note): tb_telemetria: OK
== tb_telemetria: PASA
sim/tb_tick_gen.vhd:87:9:@4009070ns:(report note): tb_tick_gen: OK
== tb_tick_gen: PASA
sim/tb_uart_tx.vhd:91:9:@247500ns:(report note): tb_uart_tx: OK
== tb_uart_tx: PASA
sim/tb_ultra_sched.vhd:126:9:@152012750ns:(report note): tb_ultra_sched: OK
== tb_ultra_sched: PASA
sim/tb_vga_debug.vhd:100:9:@104025930ns:(report note): tb_vga_debug: OK
== tb_vga_debug: PASA
```

Sola, la regresión tarda unos 2 minutos; esta última corrida tardó más porque corría junto con las pruebas de mutación.

`tb_robot_top` simula el robot completo a 2 MHz durante 2.4 s de tiempo del robot: modelos de los 4 HC-SR04 que responden a su TRIG, LDR y comparador de cerca manejados por el testbench. Revisa el estado en HEX5, el evento en HEX4, el sentido en AIN/BIN, el duty medido en PWMA y PWMB durante un periodo completo, los LEDs y la última línea de la bitácora UART decodificada.

## Los testbenches detectan errores

Cada testbench se corrió contra una copia del módulo con un error metido a propósito. Las 30 mutaciones hicieron fallar su testbench:

| Módulo | Error metido |
|---|---|
| `fsm_nav` | esquiva hacia el lado contrario; sin prioridad de la meta sobre la evasión; reversa en esquina con atrás ocupado; luz perdida a la mitad del tiempo |
| `obst_eval` | histéresis con `>` en vez de `>=`; el empate elige la derecha |
| `stall_detect` | eco intermitente cuenta como avance; cambio de exactamente DELTA_CM cuenta (acercándose y alejándose); el avance no reinicia el tiempo |
| `ldr_dir` | frente-izquierda sale como frente-derecha; izquierda y derecha sin frente sale como izquierda |
| `drive_cmd` | giro a la izquierda con la rueda equivocada; invierte el sentido sin frenar |
| `ultra_sched` | se salta el sensor 3; dispara dos sensores a la vez |
| `pi_ctrl` | signo del error invertido; sin saturación (las dos, antes y después de dividirlo en etapas) |
| `encoder_vel` | cuenta cambios simultáneos de A y B |
| `uart_tx` | manda el MSB primero; baudios incorrectos |
| `telemetria` | etiqueta I cambiada; sin eco no muestra guiones; velocidad derecha tomada de la izquierda; distancia del frente tomada de la diagonal |
| `seg7_disp` | % izquierdo tomado del derecho; sin eco no muestra guiones |
| `vga_debug` | HSYNC de 95 pixeles; color de estado cambiado; sincronías cruzadas en la etapa B |

Las primeras dos mutaciones de DELTA_CM no se detectaban con la primera versión de `tb_stall_detect`; se reforzó el caso 3 (lecturas a +-DELTA_CM de la referencia y el atasco tiene que llegar justo a los N ms) y desde entonces se detectan.

## Síntesis con GHDL

`ghdl --synth` no sustituye a Quartus, pero confirma que todo es sintetizable y que no hay latches. Log: `logs/ghdl_synth.log`.

```
# ghdl --synth --std=93c (GHDL 4.1.0), 2026-10-25 14:56 hora de CDMX
seg7_disp: OK (avisos: 0, latches: 0)
ultra_sched: OK (avisos: 0, latches: 0)
ldr_dir: OK (avisos: 0, latches: 0)
obst_eval: OK (avisos: 0, latches: 0)
stall_detect: OK (avisos: 0, latches: 0)
fsm_nav: OK (avisos: 0, latches: 0)
drive_cmd: OK (avisos: 0, latches: 0)
encoder_vel: OK (avisos: 0, latches: 0)
pi_ctrl: OK (avisos: 0, latches: 0)
uart_tx: OK (avisos: 0, latches: 0)
telemetria: OK (avisos: 0, latches: 0)
vga_debug: OK (avisos: 0, latches: 0)
robot_top: OK (avisos: 4, latches: 0)

Avisos de robot_top (todos del atributo de Quartus en sync_2ff, que GHDL no usa):
rtl/sync_2ff.vhd:32:15:warning: unhandled attribute "altera_attribute" [-Wunhandled-attribute]
```

## Ajustes de tiempos

Sin Quartus no hay reporte de tiempos, así que se partieron en etapas registradas las cadenas que podían pasar de 20 ns a 50 MHz:

- `seg7_disp` y `telemetria`: multiplicación por 100 y conversión a decimal (double dabble) en registros separados del decodificador y del multiplexor de caracteres.
- `vga_debug`: la etapa A calcula qué zona toca cada pixel y la etapa B elige el color por prioridad; las sincronías pasan por las mismas dos etapas.
- `pi_ctrl`: medida a unidades de duty, error con integrador y corrección en 3 etapas.

Las pruebas de estos módulos se repitieron después del cambio (incluida la de sistema) y siguen pasando; `tb_seg7_disp` ahora espera 4 flancos en lugar de 2 por la latencia nueva.

## Pendiente

- TAREA-009: compilar en Quartus en la PC (recursos, Fmax y warnings reales).
- Los valores de calibración (velocidades, tiempos de giro, umbrales y VMAX del PI) son estimados; se ajustan en la arena con `docs/PRUEBAS_FISICAS.md`.
