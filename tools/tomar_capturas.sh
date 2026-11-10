#!/bin/sh
# ============================================================
# tomar_capturas.sh
# Guia para tomar las capturas de Quartus del primer avance
# (TAREA-020). Para cada captura dice que dejar en la pantalla de
# Quartus; al presionar Enter cuenta unos segundos para que se
# cambie a la ventana de Quartus y toma la pantalla completa en
# capturas/NN_nombre.png. Despues se puede repetir o seguir.
#
# Uso, desde la raiz del repo y con el proyecto ya compilado:
#   sh tools/tomar_capturas.sh          (las 14)
#   sh tools/tomar_capturas.sh 07 12    (solo esas)
# ============================================================
set -u
R=$(cd "$(dirname "$0")/.." && pwd)
cd "$R" || exit 1
mkdir -p capturas logs

[ -f quartus/output_files/sintetizador.sta.rpt ] || {
    echo "Primero compila: sh quartus/compilar.sh"; exit 1; }

# Herramienta para la captura de pantalla completa
if command -v gnome-screenshot >/dev/null 2>&1; then
    captura() { gnome-screenshot -f "$1" 2>/dev/null; }
elif command -v import >/dev/null 2>&1; then
    captura() { import -window root "$1"; }
elif command -v scrot >/dev/null 2>&1; then
    captura() { scrot -o "$1"; }
elif python3 -c "from PIL import ImageGrab" 2>/dev/null; then
    captura() { python3 -c "import sys; from PIL import ImageGrab; ImageGrab.grab().save(sys.argv[1])" "$1"; }
else
    echo "No encuentro gnome-screenshot, import, scrot ni Pillow para tomar capturas"
    exit 1
fi

# Quartus abierto con el proyecto
if ! pgrep -f "13.0sp1/quartus/linux64/quartus( |$)" >/dev/null 2>&1; then
    echo "Abriendo Quartus con el proyecto (bitacora en logs/quartus_gui.log)..."
    sh quartus/abrir_quartus.sh > logs/quartus_gui.log 2>&1 &
    echo "Cuando termine de abrir, maximiza la ventana de Quartus y regresa aqui."
    printf "Enter para empezar... "
    read -r _
fi

TODAS="01 02 03 04 05 06 07 08 09 10 11 12 13 14"
LISTA="${*:-$TODAS}"

datos() {   # datos NN -> nombre, segundos de espera e instrucciones
    case "$1" in
    01) n=01_proyecto; t=5
        i="Project Navigator (izquierda), pestana Files, con la carpeta Files desplegada: se ven los .vhd de rtl/ y sintetizador.bdf." ;;
    02) n=02_simbolo; t=10
        i="Abre voz.vhd (doble clic en Files). Al presionar Enter tienes 10 s: cambia a Quartus, abre el menu File > Create / Update y deja el puntero sobre Create Symbol Files for Current File, sin hacer clic." ;;
    03) n=03_bdf_completo; t=5
        i="Abre sintetizador.bdf (doble clic en Files) y usa View > Fit in Window para que se vea el diagrama completo." ;;
    04) n=04_bdf_voces; t=5
        i="En el BDF acerca (Ctrl + rueda) la mitad derecha: gestor_voces, las 3 voz, audio_salida, vga_ui y leds_estado, hasta que se lean los nombres de los bloques y de sus puertos." ;;
    05) n=05_bdf_control; t=5
        i="Ahora la mitad izquierda: pll_25mhz, reset_encendido, base_tiempo, entradas_placa, interfaz_teclados, teclas_notas, control, secuenciador y selector_notas." ;;
    06) n=06_top_level; t=5
        i="Project Navigator, pestana Hierarchy: despliega sintetizador para que se vean sus bloques debajo y, arriba, Cyclone II: EP2C5T144C8." ;;
    07) n=07_flow_summary; t=5
        i="Processing > Compilation Report (Ctrl+R) y elige Flow Summary." ;;
    08) n=08_recursos_entidad; t=5
        i="En el Compilation Report: Fitter > Resource Section > Resource Utilization by Entity, con |sintetizador desplegado para que se vean los modulos." ;;
    09) n=09_pin_planner; t=5
        i="Assignments > Pin Planner. Abajo, la lista All Pins con las columnas Node Name y Location. Despues de la captura cierra el Pin Planner." ;;
    10) n=10_fmax; t=5
        i="Compilation Report: TimeQuest Timing Analyzer > Slow Model > Fmax Summary." ;;
    11) n=11_rtl_viewer; t=5
        i="Tools > Netlist Viewers > RTL Viewer, en el nivel superior (sintetizador)." ;;
    12) n=12_fsm_adsr; t=5
        i="Tools > Netlist Viewers > State Machine Viewer. Arriba elige |sintetizador|voz:u_voz0|adsr:u_adsr|est; deben verse el diagrama de estados y la tabla de transiciones." ;;
    13) n=13_fsm_secuenciador; t=5
        i="En el State Machine Viewer elige |sintetizador|secuenciador:u_sec|est (diagrama y tabla de transiciones)." ;;
    14) n=14_simbolos; t=5
        i="Regresa al BDF y acerca dos o tres bloques (por ejemplo voz, secuenciador y control) hasta que se lean bien los nombres de sus puertos." ;;
    *)  n=""; t=0; i="" ;;
    esac
}

hechas=0
for k in $LISTA; do
    datos "$k"
    [ -n "$n" ] || { echo "No conozco la captura $k"; continue; }
    while true; do
        echo
        echo "== Captura $k: capturas/$n.png =="
        echo "$i" | fold -s -w 78
        printf "Enter para tomarla en %s s (s = saltar)... " "$t"
        read -r r
        [ "$r" = "s" ] && break
        echo "Cambia a la ventana de Quartus ahora."
        s=$t
        while [ "$s" -gt 0 ]; do printf "%s " "$s"; sleep 1; s=$((s - 1)); done
        echo
        captura "$R/capturas/$n.png"
        if [ -s "capturas/$n.png" ]; then
            echo "Guardada: capturas/$n.png ($(wc -c < "capturas/$n.png") bytes)"
            printf "Enter para seguir, r para repetirla... "
            read -r r
            [ "$r" = "r" ] && continue
            hechas=$((hechas + 1))
        else
            echo "No se guardo la captura; se repite."
            continue
        fi
        break
    done
done

echo
echo "Listo: $hechas capturas nuevas. En capturas/:"
ls -1 capturas/*.png 2>/dev/null
echo "No hace falta hacer commit: avisa para que se revisen y se arme el PDF."
