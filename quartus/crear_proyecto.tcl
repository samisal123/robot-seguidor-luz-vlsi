# ============================================================
# crear_proyecto.tcl
# Genera el proyecto de Quartus desde cero. Este script es la
# fuente de verdad: sintetizador.qpf y sintetizador.qsf no se
# versionan.
#
# Tarjeta: EP2C5T144 (Cyclone II EP2C5T144C8). Se compila con
# Quartus II 13.0 SP1 Web Edition, la ultima version que soporta
# Cyclone II.
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

set_global_assignment -name FAMILY "Cyclone II"
set_global_assignment -name DEVICE EP2C5T144C8
set_global_assignment -name TOP_LEVEL_ENTITY $top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name VHDL_INPUT_VERSION VHDL_1993

# Pines sin uso como entradas en alta impedancia. En esta tarjeta
# es obligatorio: los pines 26 y 81 estan unidos a 1.2 V y 27 y 80
# a GND, y si Quartus los manejara (por omision los pone a GND)
# haria un corto con el regulador.
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"

# Fuentes VHDL de rtl/: primero los paquetes, luego lo demas
foreach archivo [lsort [glob -nocomplain -directory ../rtl *_pkg.vhd]] {
    set_global_assignment -name VHDL_FILE $archivo
}
foreach archivo [lsort [glob -nocomplain -directory ../rtl *.vhd]] {
    if {![string match *_pkg.vhd $archivo]} {
        set_global_assignment -name VHDL_FILE $archivo
    }
}

# PLL de 50 a 25 MHz (bloque de Quartus)
set_global_assignment -name VHDL_FILE ip/pll_25mhz.vhd

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
