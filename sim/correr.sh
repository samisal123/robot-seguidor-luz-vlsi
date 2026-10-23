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
    if "$GHDL" -a --workdir="$WORK" $archivos "$SIM/tb_$m.vhd" &&
       "$GHDL" -e --workdir="$WORK" "tb_$m" &&
       "$GHDL" -r --workdir="$WORK" "tb_$m" --assert-level=error; then
        echo "== tb_$m: PASA"
    else
        echo "== tb_$m: FALLA"
        fallos=$((fallos + 1))
    fi
done
[ $fallos -eq 0 ]
