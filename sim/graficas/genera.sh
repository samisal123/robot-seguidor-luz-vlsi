#!/bin/sh
# ============================================================
# genera.sh
# Corre las simulaciones de sim/graficas/ (graf_*.vhd), que
# escriben sus datos en sim/graficas/salida/*.csv, y dibuja las
# graficas en docs/img/sim_*.png con graficas.py (matplotlib).
# Uso: sh sim/graficas/genera.sh
# ============================================================
set -eu
G=$(cd "$(dirname "$0")" && pwd)
GHDL=${GHDL:-ghdl}
W="$G/work"
rm -rf "$W"
mkdir -p "$W" "$G/salida"
cd "$G"
"$GHDL" -i --workdir="$W" "$G"/../../rtl/*.vhd "$G/../modelo_teclado.vhd" "$G"/graf_*.vhd
for g in voz formas teclado secuenciador efectos metronomo pwm; do
    "$GHDL" -m --workdir="$W" "graf_$g" > /dev/null
    "$GHDL" -r --workdir="$W" "graf_$g" --ieee-asserts=disable-at-0
done
python3 "$G/graficas.py"
