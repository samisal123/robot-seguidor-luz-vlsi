#!/usr/bin/env bash
# ============================================================
# watcher.sh (Linux)
# Revisa el repo cada INTERVALO segundos y lanza Claude Code
# cuando hay tareas @claude-code sin hoja en resultados/.
#
# Uso, desde la raiz del repo:
#   bash tools/watcher.sh
# Detener: Ctrl+C. Bitacora en watcher.log (no se versiona).
# ============================================================
set -u

INTERVALO="${INTERVALO:-120}"
LOG="watcher.log"
ultima_firma=""

cd "$(git rev-parse --show-toplevel)" || exit 1

# Herramientas de Intel/Altera al PATH si estan en las rutas tipicas.
# Cada una se pone al frente, asi que la ultima de la lista gana:
# Quartus II 13.0 SP1 (la unica con Cyclone II) va al final.
for d in "$HOME"/altera_lite/*/quartus/bin "$HOME"/intelFPGA_lite/*/quartus/bin \
         "$HOME"/altera_lite/*/questa_fse/bin "$HOME"/intelFPGA_lite/*/questa_fse/bin \
         "$HOME"/altera_lite/*/modelsim_ase/bin "$HOME"/intelFPGA_lite/*/modelsim_ase/bin \
         /opt/altera/13.0sp1/quartus/bin "$HOME"/altera/13.0sp1/quartus/bin; do
    [ -d "$d" ] && PATH="$d:$PATH"
done
export PATH

log() { echo "$(date '+%F %T')  $*" | tee -a "$LOG"; }

# Tareas "- [ ] TAREA-NNN @claude-code" que aun no tienen resultados/TAREA-NNN.md
pendientes() {
    grep -oE '^- \[ \] TAREA-[0-9]+ @claude-code' COORDINACION.md 2>/dev/null \
        | grep -oE 'TAREA-[0-9]+' \
        | while read -r t; do [ -f "resultados/$t.md" ] || printf '%s ' "$t"; done
}

command -v claude >/dev/null 2>&1 || { echo "No encuentro 'claude' en el PATH"; exit 1; }
log "Watcher iniciado en $(pwd), revisando cada ${INTERVALO}s"

while true; do
    git pull --rebase --quiet >/dev/null 2>&1 || log "git pull fallo; se reintenta en la siguiente vuelta"
    p="$(pendientes)"
    # Solo se lanza si cambio el repo o la lista de pendientes; evita reintentos infinitos
    firma="$(git rev-parse HEAD) $p"
    if [ -n "$p" ] && [ "$firma" != "$ultima_firma" ]; then
        ultima_firma="$firma"
        log "Pendientes: $p"
        claude -p "Lee y sigue al pie de la letra tools/PROMPT_CLAUDE_CODE.md" \
            --permission-mode acceptEdits \
            --allowedTools "Bash,Read,Edit,Write,Glob,Grep" >>"$LOG" 2>&1
        log "Claude Code termino con codigo $?"
    fi
    sleep "$INTERVALO"
done
