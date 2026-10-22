# ============================================================
# watcher.ps1 (Windows)
# Revisa el repo cada $Intervalo segundos y lanza Claude Code
# cuando hay tareas @claude-code sin hoja en resultados/.
#
# Uso, desde la raiz del repo:
#   powershell -ExecutionPolicy Bypass -File tools\watcher.ps1
# Detener: Ctrl+C. Bitacora en watcher.log (no se versiona).
# ============================================================

$Intervalo = 120
$Log = "watcher.log"
$UltimaFirma = ""

Set-Location (git rev-parse --show-toplevel)

# Herramientas de Intel/Altera al PATH si estan en las rutas tipicas
foreach ($patron in @("C:\intelFPGA_lite\*\quartus\bin64", "C:\altera_lite\*\quartus\bin64",
                      "C:\intelFPGA_lite\*\questa_fse\win64", "C:\altera_lite\*\questa_fse\win64")) {
    foreach ($d in (Get-Item $patron -ErrorAction SilentlyContinue)) {
        $env:PATH = "$($d.FullName);$env:PATH"
    }
}

function Registrar($msg) {
    $linea = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
    Write-Host $linea
    Add-Content -Path $Log -Value $linea
}

# Tareas "- [ ] TAREA-NNN @claude-code" que aun no tienen resultados/TAREA-NNN.md
function Pendientes {
    $tareas = @()
    if (Test-Path "COORDINACION.md") {
        foreach ($m in (Select-String -Path "COORDINACION.md" -Pattern '^- \[ \] (TAREA-\d+) @claude-code')) {
            $t = $m.Matches[0].Groups[1].Value
            if (-not (Test-Path "resultados/$t.md")) { $tareas += $t }
        }
    }
    return ($tareas -join " ")
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "No encuentro 'claude' en el PATH"
    exit 1
}
Registrar "Watcher iniciado en $(Get-Location), revisando cada $Intervalo s"

while ($true) {
    git pull --rebase --quiet 2>&1 | Out-Null
    $p = Pendientes
    # Solo se lanza si cambio el repo o la lista de pendientes; evita reintentos infinitos
    $firma = "$(git rev-parse HEAD) $p"
    if ($p -and $firma -ne $UltimaFirma) {
        $UltimaFirma = $firma
        Registrar "Pendientes: $p"
        claude -p "Lee y sigue al pie de la letra tools/PROMPT_CLAUDE_CODE.md" --permission-mode acceptEdits --allowedTools "Bash,Read,Edit,Write,Glob,Grep" 2>&1 | Add-Content -Path $Log
        Registrar "Claude Code termino con codigo $LASTEXITCODE"
    }
    Start-Sleep -Seconds $Intervalo
}
