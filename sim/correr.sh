#!/bin/sh
# ============================================================
# correr.sh
# Simula testbenches con GHDL. GHDL importa todo rtl/ y los
# modelos de sim/ (modelo_*.vhd) y resuelve solo el orden de
# analisis (ghdl -i y ghdl -m). Cada testbench usa su propia
# carpeta de trabajo, asi se pueden correr varios a la vez.
#
# Uso (desde cualquier carpeta):
#   sim/correr.sh                     todos los testbenches
#   sim/correr.sh dds adsr            solo esos
# Variables: GHDL (ruta a ghdl), STOP (tope de tiempo simulado).
# Sale con codigo 1 si algun testbench falla.
# ============================================================
set -u
SIM=$(cd "$(dirname "$0")" && pwd)
RTL="$SIM/../rtl"
GHDL=${GHDL:-ghdl}

if [ $# -eq 0 ]; then
    set -- $(cd "$SIM" && ls tb_*.vhd | sed 's/^tb_//; s/\.vhd$//')
fi

fuentes="$(ls "$RTL"/*.vhd)"
for f in "$SIM"/modelo_*.vhd; do
    [ -f "$f" ] && fuentes="$fuentes $f"
done

fallos=0
for m in "$@"; do
    W="$SIM/work/$m"
    rm -rf "$W" && mkdir -p "$W"
    # Pasa solo si no hubo assert de error y el testbench llego a su
    # report final; --stop-time corta un testbench que se quede colgado
    if "$GHDL" -i --workdir="$W" $fuentes "$SIM/tb_$m.vhd" &&
       "$GHDL" -m --workdir="$W" "tb_$m" > "$W/make.txt" 2>&1 &&
       "$GHDL" -r --workdir="$W" "tb_$m" --assert-level=error \
           --ieee-asserts=disable-at-0 --stop-time=${STOP:-20sec} \
           > "$W/salida.txt" 2>&1; ok=$?; cat "$W/make.txt" "$W/salida.txt" 2>/dev/null |
           grep -v "^analyze\|^elaborate\|^link"; [ $ok -eq 0 ] &&
       grep -q "tb_$m: OK" "$W/salida.txt"; then
        echo "== tb_$m: PASA"
    else
        echo "== tb_$m: FALLA"
        fallos=$((fallos + 1))
    fi
done
[ $fallos -eq 0 ]
