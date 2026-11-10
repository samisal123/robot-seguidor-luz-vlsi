#!/bin/sh
# ============================================================
# sintetizar_modulo.sh
# Corre Analysis & Synthesis de Quartus con un modulo de rtl/
# como top, en un proyecto temporal (quartus/mod/<modulo>/).
# Sirve para confirmar que el modulo es sintetizable y ver sus
# recursos antes de integrarlo.
#
# Uso: quartus/sintetizar_modulo.sh <modulo> [<dependencia> ...]
# Resumen en quartus/mod/<modulo>/output_files/<modulo>.map.summary
# ============================================================
set -eu
[ $# -ge 1 ] || { echo "uso: $0 <modulo> [dependencias]"; exit 2; }
Q=$(cd "$(dirname "$0")" && pwd)
m=$1
dir="$Q/mod/$m"
rm -rf "$dir" && mkdir -p "$dir"

{
    echo "project_new -overwrite $m"
    echo 'set_global_assignment -name FAMILY "Cyclone II"'
    echo 'set_global_assignment -name DEVICE EP2C5T144C8'
    echo "set_global_assignment -name TOP_LEVEL_ENTITY $m"
    echo 'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files'
    echo 'set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL'
    for f in "$@"; do echo "set_global_assignment -name VHDL_FILE $Q/../rtl/$f.vhd"; done
    echo 'project_close'
} > "$dir/crear.tcl"

cd "$dir"
quartus_sh -t crear.tcl > /dev/null
quartus_map "$m"
