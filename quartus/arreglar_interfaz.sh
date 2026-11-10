#!/bin/sh
# ============================================================
# arreglar_interfaz.sh
# Hace que abra la interfaz grafica de Quartus II 13.0 SP1 de 64
# bits en la PC del laboratorio (TAREA-026). Lo unico que le falta
# es libpng12.so.0, que Linux Mint ya no trae: se toma del paquete
# oficial de Ubuntu 16.04 (libpng12-0 1.2.54), se revisa su SHA-256
# contra el indice firmado de Ubuntu y se copia dentro de
# quartus/linux64. No usa sudo ni instala paquetes del sistema.
# Al final abre Quartus 40 s para ver que arranque y lo cierra.
#
# Uso: sh quartus/arreglar_interfaz.sh
#      Bitacora en logs/interfaz.log
# ============================================================
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
QD="$HOME/altera/13.0sp1/quartus"
L64="$QD/linux64"
EXTRA="$HOME/altera/13.0sp1/extra"
LOG="$R/logs/interfaz.log"
mkdir -p "$R/logs" "$EXTRA"
: > "$LOG"
say() { echo "$*" | tee -a "$LOG"; }

[ -x "$L64/quartus" ] || { say "No encuentro $L64/quartus (instala Quartus II 13.0 SP1)"; exit 1; }

baja() {   # baja <url> <archivo>
    if command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"
    else curl -sSL --max-time 120 -o "$2" "$1"; fi
}

if [ -e "$L64/libpng12.so.0" ]; then
    say "libpng12.so.0 ya esta en $L64"
else
    # url y SHA-256 del paquete segun el indice de Ubuntu xenial
    # (dists/xenial-security y dists/xenial, main, binary-amd64)
    deb=""
    for par in \
        "http://security.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb 9d938a376dafd1668827ceeb742f18b164c390e53774b06eaaf644713b6ffb25" \
        "http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb 1644e3936830ed3cf3ab7fac64de99f38e16f7be001ce7947600789ce85e7bcc"
    do
        url=${par% *}
        sha=${par#* }
        f="$EXTRA/$(basename "$url")"
        [ -s "$f" ] || { say "Bajando $url"; baja "$url" "$f"; }
        if [ -s "$f" ] && [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$sha" ]; then
            deb="$f"
            break
        fi
        say "  no se pudo bajar o su SHA-256 no coincide"
        rm -f "$f"
    done
    [ -n "$deb" ] || { say "FALLO: no consegui libpng12 (revisa la red de la PC)"; exit 1; }
    say "SHA-256 correcto: $(basename "$deb")"
    rm -rf "$EXTRA/libpng12"
    dpkg-deb -x "$deb" "$EXTRA/libpng12" || { say "FALLO: dpkg-deb -x"; exit 1; }
    cp -a "$EXTRA"/libpng12/lib/x86_64-linux-gnu/libpng12.so.0* "$L64/" || { say "FALLO al copiar a $L64"; exit 1; }
    say "Copiado a $L64:"
    ls -l "$L64"/libpng12.so.0* 2>&1 | tee -a "$LOG"
fi

say ""
say "Bibliotecas que le faltan a linux64/quartus (debe quedar vacio):"
LD_LIBRARY_PATH="$L64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ldd "$L64/quartus" 2>&1 | grep "not found" | tee -a "$LOG"

if [ -z "${DISPLAY:-}" ]; then
    say "Sin pantalla (DISPLAY vacio): no se prueba la interfaz"
    exit 0
fi

say ""
say "Probando la interfaz: se abre Quartus 40 s y se cierra sola"
SAL="$R/logs/interfaz_salida.log"
"$QD/bin/quartus" --64bit > "$SAL" 2>&1 &
pid=$!
sleep 40
if kill -0 "$pid" 2>/dev/null || pgrep -f "$L64/quartus( |$)" >/dev/null 2>&1; then
    say "OK: la interfaz sigue abierta despues de 40 s"
    estado=0
else
    say "FALLO: Quartus se cerro antes de 40 s"
    estado=1
fi
say "Lo que escribio Quartus en la terminal:"
cat "$SAL" | tee -a "$LOG"
kill "$pid" 2>/dev/null
pkill -f "$L64/quartus( |$)" 2>/dev/null
sleep 2
exit $estado
