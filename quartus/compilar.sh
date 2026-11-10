#!/bin/sh
# ============================================================
# compilar.sh
# Crea el proyecto de Quartus y lo compila completo (sintesis,
# fitter, ensamblador y analisis de tiempos). Deja el log en
# logs/compilacion.log y muestra el resumen.
#
# Uso: sh quartus/compilar.sh             (nivel superior: sintetizador.bdf)
#      sh quartus/compilar.sh sinte_top   (nivel superior: rtl/sinte_top.vhd)
# Usa Quartus II 13.0 SP1 (la ultima version con Cyclone II): la
# busca primero en ~/altera/13.0sp1 y /opt/altera/13.0sp1 y si no
# esta, usa el quartus_sh del PATH.
# ============================================================
set -u
Q=$(cd "$(dirname "$0")" && pwd)
LOG="$Q/../logs/compilacion.log"

# Primero la 13.0 SP1 (la unica con Cyclone II), aunque haya otro Quartus en el PATH
for d in "$HOME"/altera/13.0sp1/quartus/bin /opt/altera/13.0sp1/quartus/bin; do
    [ -x "$d/quartus_sh" ] && { PATH="$d:$PATH"; export PATH; break; }
done
command -v quartus_sh >/dev/null 2>&1 || { echo "No encuentro quartus_sh"; exit 1; }
quartus_sh --version | grep -i "version" | head -1

mkdir -p "$Q/../logs"
cd "$Q"
quartus_sh -t crear_proyecto.tcl "$@" > /dev/null || { echo "Fallo crear_proyecto.tcl"; exit 1; }
quartus_sh --flow compile sintetizador > "$LOG" 2>&1
estado=$?

grep -E "was successful|was unsuccessful|^Error|Critical Warning" "$LOG"
echo
if [ -f output_files/sintetizador.fit.summary ]; then
    echo "==== Recursos (output_files/sintetizador.fit.summary) ===="
    cat output_files/sintetizador.fit.summary
fi
if [ -f output_files/sintetizador.sta.rpt ]; then
    echo "==== Fmax ===="
    grep -A 8 "Fmax Summary" output_files/sintetizador.sta.rpt | head -14
fi
echo
echo "Log completo: logs/compilacion.log"
exit $estado
