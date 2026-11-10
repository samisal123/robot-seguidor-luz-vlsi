#!/usr/bin/env python3
# ============================================================
# arma_avance.py
# Arma el PDF del primer avance solo con las capturas de Quartus
# de la carpeta capturas/ (ver TAREA-020 en COORDINACION.md):
# una portada y una captura por pagina con su titulo.
#
# Uso: python3 tools/arma_avance.py [--equipo "Nombre 1" "Nombre 2" ...]
#      Deja el PDF en entregas/primer_avance.pdf
# Necesita reportlab y Pillow (pip install reportlab pillow).
# ============================================================
import argparse, datetime, glob, os, sys
from PIL import Image
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

TITULOS = {
    '01_proyecto': 'Proyecto en Quartus II 13.0 SP1 para la EP2C5T144C8',
    '02_simbolo': 'Creación del símbolo a partir del archivo .vhd',
    '03_bdf_completo': 'Diagrama de bloques del sintetizador (nivel superior)',
    '04_bdf_voces': 'Diagrama de bloques: voces, gestor de voces y salida de audio',
    '05_bdf_control': 'Diagrama de bloques: reloj, reset, teclados, botones, control, secuenciador y VGA',
    '06_top_level': 'Jerarquía del proyecto con el diagrama de bloques como nivel superior',
    '07_flow_summary': 'Resumen de la compilación',
    '08_recursos_entidad': 'Recursos por módulo',
    '09_pin_planner': 'Asignación de pines (Pin Planner)',
    '10_fmax': 'Frecuencia máxima (TimeQuest)',
    '11_rtl_viewer': 'Vista RTL del nivel superior',
}

MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
         'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']


def portada(c, ancho, alto, equipo):
    c.setFont('Helvetica-Bold', 22)
    c.drawCentredString(ancho / 2, alto - 60 * mm, 'Diseño Digital VLSI')
    c.setFont('Helvetica', 16)
    c.drawCentredString(ancho / 2, alto - 75 * mm, 'Proyecto final: sintetizador musical')
    c.drawCentredString(ancho / 2, alto - 85 * mm, 'Primer avance')
    c.setFont('Helvetica', 12)
    y = alto - 105 * mm
    c.drawCentredString(ancho / 2, y, 'Tarjeta EP2C5T144 (Cyclone II EP2C5T144C8)')
    y -= 8 * mm
    c.drawCentredString(ancho / 2, y, 'Repositorio: https://github.com/samisal123/robot-seguidor-luz-vlsi')
    y -= 14 * mm
    for nombre in equipo:
        c.drawCentredString(ancho / 2, y, nombre)
        y -= 7 * mm
    hoy = datetime.date.today()
    c.drawCentredString(ancho / 2, 25 * mm, '%d de %s de %d' % (hoy.day, MESES[hoy.month - 1], hoy.year))
    c.showPage()


def pagina(c, ancho, alto, ruta, n):
    base = os.path.splitext(os.path.basename(ruta))[0]
    titulo = TITULOS.get(base, base.replace('_', ' '))
    margen = 12 * mm
    c.setFont('Helvetica-Bold', 13)
    c.drawString(margen, alto - margen - 4 * mm, 'Figura %d. %s' % (n, titulo))
    img = Image.open(ruta)
    w, h = img.size
    caja_w = ancho - 2 * margen
    caja_h = alto - 2 * margen - 12 * mm
    esc = min(caja_w / w, caja_h / h)
    dw, dh = w * esc, h * esc
    x = (ancho - dw) / 2
    y = margen + (caja_h - dh) / 2
    c.drawImage(ruta, x, y, dw, dh)
    c.showPage()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--equipo', nargs='*', default=[])
    ap.add_argument('--salida', default=os.path.join(RAIZ, 'entregas', 'primer_avance.pdf'))
    a = ap.parse_args()
    capturas = sorted(glob.glob(os.path.join(RAIZ, 'capturas', '*.png')))
    if not capturas:
        sys.exit('No hay capturas en capturas/*.png (ver TAREA-020)')
    os.makedirs(os.path.dirname(a.salida), exist_ok=True)
    ancho, alto = landscape(A4)
    c = canvas.Canvas(a.salida, pagesize=(ancho, alto))
    c.setTitle('Sintetizador musical: primer avance')
    portada(c, ancho, alto, a.equipo)
    for n, ruta in enumerate(capturas, 1):
        pagina(c, ancho, alto, ruta, n)
    c.save()
    print('%s: portada y %d capturas' % (a.salida, len(capturas)))


if __name__ == '__main__':
    main()
