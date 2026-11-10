#!/bin/sh
# ============================================================
# programar.sh
# Carga output_files/sintetizador.sof en la EP2C5T144 por el
# USB-Blaster (conector JTAG de 10 pines de la tarjeta). La
# configuracion se pierde al apagar la tarjeta; para que se quede,
# ver grabar_flash.sh.
# Uso: quartus/programar.sh   (despues de quartus/compilar.sh)
# ============================================================
set -u
Q=$(cd "$(dirname "$0")" && pwd)

# Primero la 13.0 SP1 (la unica con Cyclone II), aunque haya otro Quartus en el PATH
for d in "$HOME"/altera/13.0sp1/quartus/bin /opt/altera/13.0sp1/quartus/bin; do
    [ -x "$d/quartus_pgm" ] && { PATH="$d:$PATH"; export PATH; break; }
done

cd "$Q"
[ -f output_files/sintetizador.sof ] || { echo "Primero compila: quartus/compilar.sh"; exit 1; }
quartus_pgm -l
quartus_pgm -m jtag -o "p;output_files/sintetizador.sof"
