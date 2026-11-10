#!/bin/sh
# ============================================================
# grabar_flash.sh
# Graba output_files/sintetizador.pof en la memoria EPCS4 de la
# tarjeta EP2C5T144 (modo Active Serial). Asi la FPGA se configura
# sola cada vez que se enciende la tarjeta.
# El cable del USB-Blaster va al conector "AS" de la tarjeta (no al
# "JTAG"). Despues de grabar, se apaga y se vuelve a encender.
# Uso: sh quartus/grabar_flash.sh   (despues de quartus/compilar.sh)
# ============================================================
set -u
Q=$(cd "$(dirname "$0")" && pwd)

# Primero la 13.0 SP1 (la unica con Cyclone II), aunque haya otro Quartus en el PATH
for d in "$HOME"/altera/13.0sp1/quartus/bin /opt/altera/13.0sp1/quartus/bin; do
    [ -x "$d/quartus_pgm" ] && { PATH="$d:$PATH"; export PATH; break; }
done

cd "$Q"
[ -f output_files/sintetizador.pof ] || { echo "Primero compila: quartus/compilar.sh"; exit 1; }
quartus_pgm -l
quartus_pgm -m as -o "pv;output_files/sintetizador.pof"
