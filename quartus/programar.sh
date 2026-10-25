#!/bin/sh
# ============================================================
# programar.sh
# Carga output_files/robot.sof en la DE10-Lite por el USB-Blaster.
# La configuracion se pierde al apagar la tarjeta.
# Uso: quartus/programar.sh   (despues de quartus/compilar.sh)
# ============================================================
set -u
Q=$(cd "$(dirname "$0")" && pwd)

if ! command -v quartus_pgm >/dev/null 2>&1; then
    for d in "$HOME"/altera_lite/*/quartus/bin "$HOME"/intelFPGA_lite/*/quartus/bin; do
        [ -x "$d/quartus_pgm" ] && PATH="$d:$PATH"
    done
    export PATH
fi

cd "$Q"
[ -f output_files/robot.sof ] || { echo "Primero compila: quartus/compilar.sh"; exit 1; }
quartus_pgm -l
quartus_pgm -m jtag -o "p;output_files/robot.sof"
