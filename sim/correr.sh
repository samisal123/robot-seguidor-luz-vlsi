#!/bin/sh
# ============================================================
# correr.sh
# Simula testbenches con GHDL. Cada tb_<modulo>.vhd se analiza
# junto con los archivos de rtl/ que usa.
#
# Uso (desde cualquier carpeta):
#   sim/correr.sh                 todos los testbenches
#   sim/correr.sh pwm_8b debounce solo esos modulos
# Sale con codigo 1 si algun testbench falla.
# ============================================================
set -u
SIM=$(cd "$(dirname "$0")" && pwd)
RTL="$SIM/../rtl"
WORK="$SIM/work"
GHDL=${GHDL:-ghdl}
mkdir -p "$WORK"

# Dependencias de rtl/ de cada testbench (ademas del propio modulo)
deps() {
    case "$1" in
        debounce|motor_if|hcsr04) echo tick_gen ;;
        ultra_sched)  echo tick_gen hcsr04 ;;
        ldr_dir)      echo robot_pkg debounce ;;
        obst_eval|stall_detect|fsm_nav|drive_cmd|vga_debug) echo robot_pkg ;;
        telemetria)   echo robot_pkg uart_tx ;;
        robot_top)    echo robot_pkg tick_gen sync_2ff debounce pwm_8b motor_if hcsr04 \
                           seg7_disp ultra_sched ldr_dir obst_eval stall_detect fsm_nav \
                           drive_cmd encoder_vel pi_ctrl uart_tx telemetria vga_debug ;;
        *) echo "" ;;
    esac
}

if [ $# -eq 0 ]; then
    set -- $(cd "$SIM" && ls tb_*.vhd | sed 's/^tb_//; s/\.vhd$//')
fi

fallos=0
for m in "$@"; do
    archivos=""
    for d in $(deps "$m") "$m"; do archivos="$archivos $RTL/$d.vhd"; done
    # Pasa solo si no hubo assert de error y el testbench llego a su
    # report final; --stop-time corta un testbench que se quede colgado
    if "$GHDL" -a --workdir="$WORK" $archivos "$SIM/tb_$m.vhd" &&
       "$GHDL" -e --workdir="$WORK" "tb_$m" &&
       "$GHDL" -r --workdir="$WORK" "tb_$m" --assert-level=error --ieee-asserts=disable-at-0 --stop-time=${STOP:-10sec} \
           > "$WORK/tb_$m.out" 2>&1; ok=$?; cat "$WORK/tb_$m.out"; [ $ok -eq 0 ] &&
       grep -q "tb_$m: OK" "$WORK/tb_$m.out"; then
        echo "== tb_$m: PASA"
    else
        echo "== tb_$m: FALLA"
        fallos=$((fallos + 1))
    fi
done
[ $fallos -eq 0 ]
