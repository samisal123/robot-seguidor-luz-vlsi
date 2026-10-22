# ============================================================
# crear_proyecto.tcl
# Genera el proyecto de Quartus desde cero. Este script es la
# fuente de verdad: robot.qpf y robot.qsf no se versionan.
#
# Uso (desde la carpeta quartus/):
#   quartus_sh -t crear_proyecto.tcl
#   quartus_sh --flow compile robot
# ============================================================

set proyecto robot
set top      robot_top

project_new -overwrite $proyecto

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY $top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL

# Todas las fuentes VHDL de rtl/
foreach archivo [lsort [glob -nocomplain -directory ../rtl *.vhd]] {
    set_global_assignment -name VHDL_FILE $archivo
}

# Restricciones de tiempo
set_global_assignment -name SDC_FILE robot.sdc

# Asignacion de pines (se agrega cuando se defina el cableado)
if {[file exists pines.tcl]} {
    source pines.tcl
}

project_close
