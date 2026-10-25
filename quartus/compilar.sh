#!/bin/sh
# ============================================================
# compilar.sh
# Crea el proyecto de Quartus y lo compila completo (sintesis,
# fitter, ensamblador y analisis de tiempos). Deja el log en
# logs/compilacion.log y muestra el resumen.
#
# Uso: quartus/compilar.sh
# Si quartus_sh no esta en el PATH, se busca en ~/altera_lite y
# ~/intelFPGA_lite.
# ============================================================
set -u
Q=$(cd "$(dirname "$0")" && pwd)
LOG="$Q/../logs/compilacion.log"

if ! command -v quartus_sh >/dev/null 2>&1; then
    for d in "$HOME"/altera_lite/*/quartus/bin "$HOME"/intelFPGA_lite/*/quartus/bin; do
        [ -x "$d/quartus_sh" ] && PATH="$d:$PATH"
    done
    export PATH
fi
command -v quartus_sh >/dev/null 2>&1 || { echo "No encuentro quartus_sh"; exit 1; }

cd "$Q"
quartus_sh -t crear_proyecto.tcl > /dev/null || { echo "Fallo crear_proyecto.tcl"; exit 1; }
quartus_sh --flow compile robot > "$LOG" 2>&1
estado=$?

grep -E "was successful|was unsuccessful|^Error|Critical Warning" "$LOG"
echo
if [ -f output_files/robot.fit.summary ]; then
    echo "==== Recursos (output_files/robot.fit.summary) ===="
    cat output_files/robot.fit.summary
fi
if [ -f output_files/robot.sta.rpt ]; then
    echo "==== Fmax ===="
    grep -A 8 "Fmax Summary" output_files/robot.sta.rpt | head -14
fi
echo
echo "Log completo: logs/compilacion.log"
exit $estado
