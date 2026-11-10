#!/bin/sh
# ============================================================
# estimar_recursos.sh
# Estimacion de recursos con el Quartus Prime Lite de la PC, que
# ya no soporta Cyclone II y solo trae la familia MAX 10: compila
# rtl/sinte_top.vhd para una MAX 10 (10M50DAF484C7G), que usa el
# mismo elemento logico de 4 entradas que la Cyclone II, y muestra
# los elementos logicos por modulo. Sirve para saber si el diseno
# cabe en los 4 608 LE de la EP2C5 sin tener Quartus II 13.0 SP1.
#
# Para que las tablas vayan a memoria como en la Cyclone II:
#   - el modo de configuracion es "imagen unica con memoria
#     inicializada" (sin eso la MAX 10 no acepta ROM con contenido
#     inicial y las arma con logica, lo que infla la cuenta);
#   - en una copia del RTL, romstyle "M4K" se cambia por "M9K".
# Los bits de memoria no se comparan (M9K contra M4K).
# El PLL se sustituye por el modelo de simulacion (un divisor).
# No toca el proyecto real: trabaja en quartus/estimacion/.
#
# Uso: sh quartus/estimar_recursos.sh
# ============================================================
set -u
Q=$(cd "$(dirname "$0")" && pwd)
R="$Q/.."

if ! command -v quartus_sh >/dev/null 2>&1; then
    for d in "$HOME"/altera_lite/*/quartus/bin "$HOME"/intelFPGA_lite/*/quartus/bin; do
        [ -x "$d/quartus_sh" ] && { PATH="$d:$PATH"; break; }
    done
    export PATH
fi
command -v quartus_sh >/dev/null 2>&1 || { echo "No encuentro quartus_sh"; exit 1; }

D="$Q/estimacion"
rm -rf "$D" && mkdir -p "$D/rtl"
for f in "$R"/rtl/*.vhd "$R"/sim/modelo_pll.vhd; do
    sed 's/"M4K"/"M9K"/g' "$f" > "$D/rtl/$(basename "$f")"
done
{
    echo 'project_new -overwrite estimacion'
    echo 'set_global_assignment -name FAMILY "MAX 10"'
    echo 'set_global_assignment -name DEVICE 10M50DAF484C7G'
    echo 'set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE WITH ERAM"'
    echo 'set_global_assignment -name TOP_LEVEL_ENTITY sinte_top'
    echo 'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files'
    echo 'set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL'
    echo 'set_global_assignment -name VHDL_INPUT_VERSION VHDL_1993'
    echo "set_global_assignment -name VHDL_FILE rtl/synth_pkg.vhd"
    for f in "$D"/rtl/*.vhd; do
        case "$f" in *_pkg.vhd) ;; *) echo "set_global_assignment -name VHDL_FILE rtl/$(basename "$f")" ;; esac
    done
    echo 'project_close'
} > "$D/crear.tcl"

cd "$D"
quartus_sh -t crear.tcl > /dev/null || { echo "Fallo crear.tcl"; exit 1; }
quartus_map estimacion > map.log 2>&1 && quartus_fit estimacion > fit.log 2>&1
estado=$?
grep -E "was successful|was unsuccessful|^Error" map.log fit.log
echo
echo "==== Tablas que no fueron a memoria (deberia no salir ninguna) ===="
grep -E "uninferred" map.log
echo "==== Memorias inferidas ===="
grep -E "Inferred altsyncram" map.log | sed 's/.*logic: //'
echo
[ -f output_files/estimacion.fit.summary ] && cat output_files/estimacion.fit.summary
echo
echo "==== Elementos logicos por modulo (Fitter Resource Utilization by Entity) ===="
n=$(grep -n "; Fitter Resource Utilization by Entity" output_files/estimacion.fit.rpt | head -1 | cut -d: -f1)
[ -n "$n" ] && sed -n "$((n+2)),$((n+80))p" output_files/estimacion.fit.rpt \
    | grep -E "^; +\|" | grep -v "lpm_\|altsyncram\|auto_generated\|alt_u_div\|sign_div" | cut -c1-110
exit $estado
