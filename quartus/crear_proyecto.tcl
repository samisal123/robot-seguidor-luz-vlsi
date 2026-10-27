# ============================================================
# crear_proyecto.tcl
# Genera el proyecto de Quartus desde cero. Este script es la
# fuente de verdad: sintetizador.qpf y sintetizador.qsf no se
# versionan.
#
# Nivel superior: sintetizador.bdf, el diagrama de bloques del
# Block Editor (generado por tools/genera_top.py). El mismo
# circuito existe en VHDL en rtl/sinte_top.vhd y se puede usar
# como nivel superior pasando su nombre como argumento.
#
# Uso, desde una terminal:
#   cd quartus
#   quartus_sh -t crear_proyecto.tcl              (top: sintetizador.bdf)
#   quartus_sh -t crear_proyecto.tcl sinte_top    (top: rtl/sinte_top.vhd)
#   quartus_sh --flow compile sintetizador
# o simplemente sh quartus/compilar.sh [sinte_top]
# Desde la interfaz de Quartus: Tools > Tcl Scripts..., elegir
# este archivo y Run; luego File > Open Project > sintetizador.qpf.
# ============================================================

# Trabaja siempre en la carpeta de este script (quartus/), sin
# importar desde donde se ejecute
cd [file dirname [file normalize [info script]]]

set proyecto sintetizador
set top      sintetizador
if {[info exists quartus(args)] && [llength $quartus(args)] > 0} {
    set top [lindex $quartus(args) 0]
}

project_new -overwrite $proyecto

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY $top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name VHDL_INPUT_VERSION VHDL_1993

# Fuentes VHDL de rtl/: primero los paquetes, luego lo demas
foreach archivo [lsort [glob -nocomplain -directory ../rtl *_pkg.vhd]] {
    set_global_assignment -name VHDL_FILE $archivo
}
foreach archivo [lsort [glob -nocomplain -directory ../rtl *.vhd]] {
    if {![string match *_pkg.vhd $archivo]} {
        set_global_assignment -name VHDL_FILE $archivo
    }
}

# Diagrama de bloques del nivel superior (y sus simbolos, para
# editarlo en el Block Editor). Con el top en VHDL no se agrega,
# asi un problema en el .bdf no detiene esa compilacion.
if {$top eq "sintetizador"} {
    set_global_assignment -name BDF_FILE sintetizador.bdf
}
set_global_assignment -name SEARCH_PATH simbolos

# Restricciones de tiempo
set_global_assignment -name SDC_FILE sintetizador.sdc

# Asignacion de pines
if {[file exists pines.tcl]} {
    source pines.tcl
}

project_close
