#!/bin/sh
# ============================================================
# abrir_quartus.sh
# Abre la interfaz grafica de Quartus II 13.0 SP1 (64 bits) con
# el proyecto del sintetizador. Antes hay que compilar una vez
# con quartus/compilar.sh (crea quartus/sintetizador.qpf).
# La version de 64 bits es la que tiene todas sus bibliotecas en
# esta PC (libpng12 se agrega en quartus/linux64, ver TAREA-026).
#
# Uso: sh quartus/abrir_quartus.sh
# ============================================================
Q=$(cd "$(dirname "$0")" && pwd)
B="$HOME/altera/13.0sp1/quartus/bin"
[ -x "$B/quartus" ] || { echo "No encuentro $B/quartus (instala Quartus II 13.0 SP1)"; exit 1; }
[ -f "$Q/sintetizador.qpf" ] || { echo "Primero compila: sh quartus/compilar.sh"; exit 1; }
cd "$Q" || exit 1
exec "$B/quartus" --64bit sintetizador.qpf
