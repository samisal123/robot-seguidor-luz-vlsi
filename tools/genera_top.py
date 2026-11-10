#!/usr/bin/env python3
# ============================================================
# genera_top.py
# Genera el nivel superior del sintetizador a partir de una sola
# descripcion de la red (instancias y senales), en dos formatos
# equivalentes:
#   rtl/sinte_top.vhd           VHDL estructural (simulacion con
#                               GHDL y alternativa en Quartus)
#   quartus/sintetizador.bdf    diagrama de bloques para el Block
#                               Editor de Quartus (nivel superior
#                               del proyecto, como en el material
#                               del curso)
#   quartus/simbolos/*.bsf      simbolos de cada bloque, para
#                               agregarlos o actualizarlos en el
#                               Block Editor
# Los puertos de cada bloque se leen de su entidad en rtl/, asi
# que el diagrama siempre coincide con el VHDL. En el .bdf los
# bloques van en columnas de la entrada a la salida y se dibujan
# los cables entre columnas vecinas; el reloj, el reset, los pulsos
# de tiempo y las rebanadas de bus van con un tramo de cable con
# el nombre de su senal (los cables con el mismo nombre quedan
# conectados). tools/revisa_bdf.py revisa que la red del .bdf sea
# la misma que la del VHDL.
#
# Uso: python3 tools/genera_top.py               (con cables)
#      python3 tools/genera_top.py --sin-cables  (solo tramos con nombre)
# ============================================================
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RTL = os.path.join(RAIZ, 'rtl')
IP = os.path.join(RAIZ, 'quartus', 'ip')      # bloques de Quartus (PLL)

# ------------------------------------------------------------
# Red del sintetizador
# ------------------------------------------------------------
# Pines de la tarjeta EP2C5T144: (nombre, direccion, ancho o None)
PINES = [
    ('CLOCK_50', 'in', None),
    ('BTN_RESET', 'in', None),
    ('BTN', 'in', 3),
    ('TEC1_COL', 'in', 4),
    ('TEC2_COL', 'in', 4),
    ('LED', 'out', 3),
    ('TEC1_FIL', 'out', 4),
    ('TEC2_FIL', 'out', 4),
    ('AUDIO_PWM', 'out', None),
    ('VGA_R', 'out', None),
    ('VGA_G', 'out', None),
    ('VGA_B', 'out', None),
    ('VGA_HS', 'out', None),
    ('VGA_VS', 'out', None),
]

COMENTARIO_PIN = {
    'CLOCK_50': 'oscilador de 50 MHz de la tarjeta (pin 17)',
    'BTN_RESET': 'boton RESET de la tarjeta, 0 = presionado (pin 144)',
    'BTN': 'botones METRONOMO, ACCION y MODO (2..0), 0 = presionado',
    'TEC1_COL': 'columnas del teclado 1, 0 = tecla (pull-up)',
    'TEC2_COL': 'columnas del teclado 2',
    'LED': 'LEDs D5, D4, D2 de la tarjeta (2..0), activos en bajo',
    'TEC1_FIL': 'filas del teclado 1 (0 o alta impedancia)',
    'TEC2_FIL': 'filas del teclado 2',
    'AUDIO_PWM': 'PWM de audio de 97.7 kHz (pin 93)',
    'VGA_R': 'rojo (270 ohm al DB15)',
    'VGA_G': 'verde',
    'VGA_B': 'azul',
    'VGA_HS': 'sincronia horizontal',
    'VGA_VS': 'sincronia vertical',
}

# Senales internas: (nombre, ancho o None)
SENALES = [
    ('clk', None), ('pll_listo', None),
    ('rst', None), ('tick_fs', None), ('tick_1ms', None),
    ('accion', None), ('metro_btn', None), ('modo', 2),
    ('teclas', 32), ('vivo', 21), ('func', 8),
    ('forma', 2), ('atk', 2), ('dec', 2), ('sus', 2), ('rel', 2),
    ('volumen', 3), ('tempo', 2), ('efecto', 2),
    ('metro_on', None), ('metro_suena', None),
    ('octava', 3), ('parametro', 3),
    ('cmd_grabar', None), ('cmd_reproducir', None), ('cmd_parar', None),
    ('grabado', 21), ('estado_sec', 2), ('eventos', 9), ('posicion', 9),
    ('pedidas', 21), ('notas_v', 21), ('gates', 3), ('activas', 3),
    ('muestras', 24), ('niveles', 24),
    ('beat', None), ('acento', None),
]

# Instancias: (nombre, entidad, columna, {puerto: senal})
# senal puede ser 'nombre', 'nombre[a..b]', 'nombre[i]' o None (sin conectar)
CLK = 'clk'      # 25 MHz del PLL
INSTANCIAS = [
    ('u_pll', 'pll_25mhz', 1, {'inclk0': 'CLOCK_50', 'c0': 'clk', 'locked': 'pll_listo'}),
    ('u_rst', 'reset_encendido', 1, {'clk': CLK, 'listo': 'pll_listo', 'boton_n': 'BTN_RESET',
                                     'rst': 'rst'}),
    ('u_tiempo', 'base_tiempo', 1, {'clk': CLK, 'rst': 'rst',
                                    'tick_fs': 'tick_fs', 'tick_1ms': 'tick_1ms'}),
    ('u_placa', 'entradas_placa', 1, {'clk': CLK, 'rst': 'rst', 'tick_1ms': 'tick_1ms',
                                      'btn': 'BTN', 'accion': 'accion',
                                      'metro_btn': 'metro_btn', 'modo': 'modo'}),
    ('u_teclados', 'interfaz_teclados', 1, {'clk': CLK, 'rst': 'rst', 'tick_1ms': 'tick_1ms',
                                            'tec1_col': 'TEC1_COL', 'tec2_col': 'TEC2_COL',
                                            'tec1_fil': 'TEC1_FIL', 'tec2_fil': 'TEC2_FIL',
                                            'teclas': 'teclas'}),
    ('u_notas', 'teclas_notas', 2, {'clk': CLK, 'rst': 'rst', 'teclas': 'teclas',
                                    'octava': 'octava', 'notas': 'vivo', 'func': 'func'}),
    ('u_control', 'control', 2, {'clk': CLK, 'rst': 'rst', 'modo': 'modo', 'func': 'func',
                                 'accion': 'accion', 'metro_btn': 'metro_btn',
                                 'estado_sec': 'estado_sec', 'forma': 'forma', 'atk': 'atk',
                                 'dec': 'dec', 'sus': 'sus', 'rel': 'rel', 'volumen': 'volumen',
                                 'tempo': 'tempo', 'efecto': 'efecto', 'metro_on': 'metro_on',
                                 'metro_suena': 'metro_suena', 'octava': 'octava',
                                 'parametro': 'parametro', 'cmd_grabar': 'cmd_grabar',
                                 'cmd_reproducir': 'cmd_reproducir', 'cmd_parar': 'cmd_parar'}),
    ('u_sec', 'secuenciador', 3, {'clk': CLK, 'rst': 'rst', 'tick_1ms': 'tick_1ms',
                                  'cmd_grabar': 'cmd_grabar', 'cmd_reproducir': 'cmd_reproducir',
                                  'cmd_parar': 'cmd_parar', 'conjunto': 'vivo',
                                  'salida': 'grabado', 'estado': 'estado_sec',
                                  'eventos': 'eventos', 'posicion': 'posicion', 'llena': None}),
    ('u_sel', 'selector_notas', 3, {'estado_sec': 'estado_sec', 'vivo': 'vivo',
                                    'grabado': 'grabado', 'pedidas': 'pedidas'}),
    ('u_gestor', 'gestor_voces', 3, {'clk': CLK, 'rst': 'rst', 'conjunto': 'pedidas',
                                     'activas': 'activas', 'notas_v': 'notas_v',
                                     'gates': 'gates'}),
]
for v in range(3):
    INSTANCIAS.append((f'u_voz{v}', 'voz', 4, {
        'clk': CLK, 'rst': 'rst', 'tick_fs': 'tick_fs',
        'nota': f'notas_v[{7 * v + 6}..{7 * v}]', 'gate': f'gates[{v}]',
        'forma': 'forma', 'atk': 'atk', 'dec': 'dec', 'sus': 'sus', 'rel': 'rel',
        'muestra': f'muestras[{8 * v + 7}..{8 * v}]', 'nivel': f'niveles[{8 * v + 7}..{8 * v}]',
        'activa': f'activas[{v}]'}))
INSTANCIAS += [
    ('u_audio', 'audio_salida', 5, {'clk': CLK, 'rst': 'rst', 'tick_fs': 'tick_fs',
                                    'tick_1ms': 'tick_1ms', 'voz0': 'muestras[7..0]',
                                    'voz1': 'muestras[15..8]', 'voz2': 'muestras[23..16]',
                                    'volumen': 'volumen', 'efecto': 'efecto',
                                    'metro_on': 'metro_suena', 'tempo': 'tempo',
                                    'pwm': 'AUDIO_PWM', 'beat': 'beat', 'acento': 'acento',
                                    'clip': None, 'nivel': None}),
    ('u_vga', 'vga_ui', 5, {'clk': CLK, 'rst': 'rst', 'modo': 'modo', 'estado_sec': 'estado_sec',
                            'forma': 'forma', 'atk': 'atk', 'dec': 'dec', 'sus': 'sus',
                            'rel': 'rel', 'volumen': 'volumen', 'tempo': 'tempo',
                            'efecto': 'efecto', 'metro_on': 'metro_on', 'beat': 'beat',
                            'acento': 'acento', 'octava': 'octava', 'notas': 'notas_v',
                            'gates': 'gates', 'niveles': 'niveles', 'parametro': 'parametro',
                            'eventos': 'eventos', 'posicion': 'posicion', 'vga_r': 'VGA_R',
                            'vga_g': 'VGA_G', 'vga_b': 'VGA_B', 'vga_hs': 'VGA_HS',
                            'vga_vs': 'VGA_VS'}),
    ('u_leds', 'leds_estado', 5, {'clk': CLK, 'rst': 'rst', 'tick_1ms': 'tick_1ms',
                                  'metro_on': 'metro_on', 'beat': 'beat',
                                  'estado_sec': 'estado_sec', 'led_n': 'LED'}),
]


# ------------------------------------------------------------
# Lectura de entidades
# ------------------------------------------------------------
def lee_entidad(nombre):
    """Regresa la lista de puertos [(nombre, dir, ancho o None, msb, lsb)]."""
    ruta = os.path.join(RTL, nombre + '.vhd')
    if not os.path.exists(ruta):
        ruta = os.path.join(IP, nombre + '.vhd')
    texto = open(ruta, encoding='ascii').read()
    texto = re.sub(r'--[^\n]*', '', texto)
    m = re.search(r'entity\s+' + nombre + r'\s+is(.*?)end\s+entity', texto, re.S | re.I)
    if not m:
        sys.exit(f'no encuentro la entidad {nombre}')
    cuerpo = m.group(1)
    mp = re.search(r'port\s*\((.*)\)\s*;', cuerpo, re.S | re.I)
    puertos = []
    for decl in mp.group(1).split(';'):
        decl = decl.strip()
        if not decl:
            continue
        nombres, resto = decl.split(':', 1)
        resto = resto.strip()
        d, tipo = resto.split(None, 1)
        d = d.lower()
        mv = re.match(r'std_logic_vector\s*\(\s*(\d+)\s+downto\s+(\d+)\s*\)', tipo, re.I)
        if mv:
            msb, lsb = int(mv.group(1)), int(mv.group(2))
            ancho = msb - lsb + 1
        elif re.match(r'std_logic\b', tipo, re.I):
            msb = lsb = None
            ancho = None
        else:
            sys.exit(f'{nombre}: tipo no soportado en el puerto {nombres}: {tipo}')
        for n in nombres.split(','):
            puertos.append((n.strip(), d, ancho, msb, lsb))
    return puertos


ENTIDADES = {}
for (_, ent, _, _) in INSTANCIAS:
    if ent not in ENTIDADES:
        ENTIDADES[ent] = lee_entidad(ent)

ANCHOS = {n: a for (n, a) in SENALES}
for (n, d, a) in PINES:
    ANCHOS[n] = a


def ancho_de(expr):
    m = re.match(r'(\w+)\[(\d+)\.\.(\d+)\]$', expr)
    if m:
        return int(m.group(2)) - int(m.group(3)) + 1
    m = re.match(r'(\w+)\[(\d+)\]$', expr)
    if m:
        return None
    if expr not in ANCHOS:
        sys.exit(f'senal desconocida: {expr}')
    return ANCHOS[expr]


# Revisa que cada puerto este conectado con el ancho correcto y que
# cada senal tenga exactamente un manejador
manejadores = {}
for (inst, ent, _, mapa) in INSTANCIAS:
    nombres = [p[0] for p in ENTIDADES[ent]]
    for p in mapa:
        if p not in nombres:
            sys.exit(f'{inst}: {ent} no tiene el puerto {p}')
    for (p, d, a, _, _) in ENTIDADES[ent]:
        if p not in mapa:
            sys.exit(f'{inst}: falta conectar el puerto {p}')
        s = mapa[p]
        if s is None:
            if d == 'in':
                sys.exit(f'{inst}: la entrada {p} no puede quedar abierta')
            continue
        if ancho_de(s) != a:
            sys.exit(f'{inst}.{p}: ancho {a} conectado a {s} ({ancho_de(s)})')
        if d == 'out':
            manejadores.setdefault(s, []).append(f'{inst}.{p}')
for (n, a) in SENALES:
    bits = 1 if a is None else a
    if n not in manejadores and not any(k.startswith(n + '[') for k in manejadores):
        sys.exit(f'la senal {n} no tiene quien la maneje')
for (n, d, a) in PINES:
    if d == 'out' and n not in manejadores:
        sys.exit(f'el pin {n} no tiene quien lo maneje')
for k, v in manejadores.items():
    if len(v) > 1:
        sys.exit(f'{k} tiene varios manejadores: {v}')


# ------------------------------------------------------------
# VHDL
# ------------------------------------------------------------
def vhdl_tipo(a):
    return 'std_logic' if a is None else f'std_logic_vector({a - 1} downto 0)'


def vhdl_expr(expr):
    m = re.match(r'(\w+)\[(\d+)\.\.(\d+)\]$', expr)
    if m:
        return f'{m.group(1)}({m.group(2)} downto {m.group(3)})'
    m = re.match(r'(\w+)\[(\d+)\]$', expr)
    if m:
        return f'{m.group(1)}({m.group(2)})'
    return expr


def genera_vhdl():
    L = []
    w = L.append
    w('-- ============================================================')
    w('-- sinte_top.vhd')
    w('-- Sintetizador musical digital sobre la tarjeta EP2C5T144')
    w('-- (Cyclone II). Reloj de 50 MHz -> PLL -> 25 MHz.')
    w('-- ARCHIVO GENERADO por tools/genera_top.py junto con')
    w('-- quartus/sintetizador.bdf (el mismo circuito como diagrama de')
    w('-- bloques). Para cambiar conexiones, editar el script.')
    w('--')
    w('--   teclados -> interfaz_teclados -> teclas_notas --+-> secuenciador')
    w('--                                                   v       |')
    w('--                   selector_notas (vivo o grabado) <-------+')
    w('--                                |')
    w('--                          gestor_voces -> voz 0, voz 1, voz 2')
    w('--                                               |')
    w('--   audio_salida: mezcla -> efectos -> volumen -> + metronomo -> PWM')
    w('--')
    w('--   control: modos (boton MODO), teclas de funcion, botones')
    w('--   ACCION y METRONOMO, parametros y ordenes al secuenciador')
    w('--   vga_ui y leds_estado: interfaz de usuario')
    w('-- ============================================================')
    w('library ieee;')
    w('use ieee.std_logic_1164.all;')
    w('')
    w('entity sinte_top is')
    w('    port (')
    for i, (n, d, a) in enumerate(PINES):
        fin = ';' if i < len(PINES) - 1 else ' '
        decl = f'        {n:<13} : {d:<3} {vhdl_tipo(a)}{fin}'
        w(f'{decl:<57} -- {COMENTARIO_PIN[n]}')
    w('    );')
    w('end entity sinte_top;')
    w('')
    w('architecture estructural of sinte_top is')
    for (n, a) in SENALES:
        w(f'    signal {n:<14} : {vhdl_tipo(a)};')
    w('begin')
    for (inst, ent, _, mapa) in INSTANCIAS:
        w('')
        w(f'    {inst} : entity work.{ent}')
        w('        port map (')
        asoc = []
        largo = max(len(p[0]) for p in ENTIDADES[ent])
        for (p, d, a, _, _) in ENTIDADES[ent]:
            s = mapa[p]
            asoc.append(f'            {p:<{largo}} => {"open" if s is None else vhdl_expr(s)}')
        w(',\n'.join(asoc))
        w('        );')
    w('')
    w('end architecture estructural;')
    w('')
    return '\n'.join(L)


# ------------------------------------------------------------
# BDF (Block Editor)
# ------------------------------------------------------------
CAR = 7          # ancho aproximado de un caracter
PASO = 16        # separacion entre puertos
TRAMO = 48       # largo del cable con nombre en cada puerto


def etiqueta_puerto(p, a, msb, lsb):
    return p if a is None else f'{p}[{msb}..{lsb}]'


def etiqueta_senal(expr):
    if expr in ANCHOS and ANCHOS[expr] is not None:
        return f'{expr}[{ANCHOS[expr] - 1}..0]'
    return expr


def es_bus(expr):
    return ancho_de(expr) is not None


def texto(t, x1, y1, tam=None):
    f = f'(font "Arial" (font_size {tam}))' if tam else '(font "Arial" )'
    return f'(text "{t}" (rect {x1} {y1} {x1 + CAR * len(t)} {y1 + 12}){f})'


def simbolo(ent, inst, x, y):
    """Texto del simbolo en (x, y) y lista de (x, y, etiqueta, es_bus, lado)."""
    puertos = ENTIDADES[ent]
    ent_in = [p for p in puertos if p[1] == 'in']
    sal = [p for p in puertos if p[1] == 'out']
    li = max([len(etiqueta_puerto(p[0], p[2], p[3], p[4])) for p in ent_in] + [4])
    ls = max([len(etiqueta_puerto(p[0], p[2], p[3], p[4])) for p in sal] + [4])
    ancho = max(16 + 8 + CAR * (li + ls) + 40, 16 + CAR * len(ent) + 40)
    ancho = (ancho + 15) // 16 * 16
    filas = max(len(ent_in), len(sal))
    alto = 32 + PASO * filas + 16
    L = []
    w = L.append
    w('(symbol')
    w(f'\t(rect {x} {y} {x + ancho} {y + alto})')
    w('\t' + texto(ent, 5, 0, 10))
    w('\t' + texto(inst, 8, alto - 16))
    conexiones = []
    for i, (p, d, a, msb, lsb) in enumerate(ent_in):
        py = 32 + PASO * i
        e = etiqueta_puerto(p, a, msb, lsb)
        w('\t(port')
        w(f'\t\t(pt 0 {py})')
        w('\t\t(input)')
        w('\t\t' + texto(e, 0, 0))
        w('\t\t' + texto(e, 21, py - 5))
        w(f'\t\t(line (pt 0 {py})(pt 16 {py})(line_width {1 if a is None else 3}))')
        w('\t)')
        conexiones.append((x, y + py, p, 'izq'))
    for i, (p, d, a, msb, lsb) in enumerate(sal):
        py = 32 + PASO * i
        e = etiqueta_puerto(p, a, msb, lsb)
        w('\t(port')
        w(f'\t\t(pt {ancho} {py})')
        w('\t\t(output)')
        w('\t\t' + texto(e, 0, 0))
        w('\t\t' + texto(e, ancho - 21 - CAR * len(e), py - 5))
        w(f'\t\t(line (pt {ancho} {py})(pt {ancho - 16} {py})(line_width {1 if a is None else 3}))')
        w('\t)')
        conexiones.append((x + ancho, y + py, p, 'der'))
    w('\t(drawing')
    w(f'\t\t(rectangle (rect 16 16 {ancho - 16} {alto - 16})(line_width 1))')
    w('\t)')
    w(')')
    return '\n'.join(L), conexiones, ancho, alto


def conector(x1, y1, x2, y2, etiqueta, bus):
    L = ['(connector']
    if etiqueta:
        tx = min(x1, x2) + 2
        L.append('\t' + texto(etiqueta, tx, y1 - 13))
    L.append(f'\t(pt {x1} {y1})')
    L.append(f'\t(pt {x2} {y2})')
    if bus:
        L.append('\t(bus)')
    L.append(')')
    return '\n'.join(L)


def pin(n, d, a, x, y):
    e = n if a is None else f'{n}[{a - 1}..0]'
    if d == 'in':
        L = ['(pin', '\t(input)', f'\t(rect {x} {y} {x + 168} {y + 16})',
             '\t' + texto('INPUT', 125, 0, 6), '\t' + texto(e, 5, 0), '\t(pt 168 8)',
             '\t(drawing', '\t\t(line (pt 84 12)(pt 109 12))', '\t\t(line (pt 84 4)(pt 109 4))',
             '\t\t(line (pt 113 8)(pt 168 8))', '\t\t(line (pt 84 12)(pt 84 4))',
             '\t\t(line (pt 109 4)(pt 113 8))', '\t\t(line (pt 109 12)(pt 113 8))', '\t)',
             '\t' + texto('VCC', 128, 7, 6), ')']
        return '\n'.join(L), (x + 168, y + 8), e
    L = ['(pin', '\t(output)', f'\t(rect {x} {y} {x + 176} {y + 16})',
         '\t' + texto('OUTPUT', 1, 0, 6), '\t' + texto(e, 90, 0), '\t(pt 0 8)',
         '\t(drawing', '\t\t(line (pt 0 8)(pt 52 8))', '\t\t(line (pt 52 4)(pt 78 4))',
         '\t\t(line (pt 52 12)(pt 78 12))', '\t\t(line (pt 52 12)(pt 52 4))',
         '\t\t(line (pt 78 4)(pt 82 8))', '\t\t(line (pt 82 8)(pt 78 12))',
         '\t\t(line (pt 78 12)(pt 82 8))', '\t)', ')']
    return '\n'.join(L), (x, y + 8), e


ENCABEZADO = '''/*
Diagrama de bloques del sintetizador (nivel superior del proyecto).
ARCHIVO GENERADO por tools/genera_top.py a partir de la misma red que
rtl/sinte_top.vhd. Cada puerto lleva un cable con el nombre de su senal:
los cables con el mismo nombre estan conectados.
*/
(header "graphic" (version "1.4"))
'''


def genera_bdf():
    partes = [ENCABEZADO]
    # columnas de instancias
    x_col = {1: 400, 2: 1100, 3: 1800, 4: 2500, 5: 3200}
    y_col = {c: 0 for c in x_col}
    anchos_col = {c: 0 for c in x_col}
    for (inst, ent, col, mapa) in INSTANCIAS:
        txt, conexiones, ancho, alto = simbolo(ent, inst, x_col[col], y_col[col])
        partes.append(txt)
        y_col[col] += alto + 64
        anchos_col[col] = max(anchos_col[col], ancho)
        for (cx, cy, p, lado) in conexiones:
            s = mapa[p]
            if s is None:
                continue
            et = etiqueta_senal(s)
            if lado == 'izq':
                partes.append(conector(cx - TRAMO, cy, cx, cy, et, es_bus(s)))
            else:
                partes.append(conector(cx, cy, cx + TRAMO, cy, et, es_bus(s)))
    # pines: entradas a la izquierda, salidas a la derecha
    y_in = 0
    y_out = 0
    x_out = x_col[5] + anchos_col[5] + 400
    for (n, d, a) in PINES:
        if d == 'in':
            txt, (px, py), e = pin(n, d, a, 0, y_in)
            partes.append(txt)
            partes.append(conector(px, py, px + TRAMO, py, e, a is not None))
            y_in += 48
        else:
            txt, (px, py), e = pin(n, d, a, x_out, y_out)
            partes.append(txt)
            partes.append(conector(px - TRAMO, py, px, py, e, a is not None))
            y_out += 48
    return '\n'.join(partes) + '\n'


# ------------------------------------------------------------
# BDF con cables dibujados
# ------------------------------------------------------------
# Las senales globales (reloj, reset y pulsos de tiempo) van con
# cables cortos con nombre en cada puerto, como en un esquematico
# normal. Las demas se dibujan como cables de verdad cuando van de
# un bloque a otro de la columna siguiente con el mismo nombre
# completo (sin rebanadas de bus): salen a la derecha del bloque,
# bajan o suben por un carril propio en el espacio entre columnas
# y entran por la izquierda del bloque destino. Lo que no se puede
# dibujar asi (rebanadas, conexiones hacia atras o que saltan
# columnas) queda con cable corto con nombre; Quartus une los
# cables con el mismo nombre, asi que la red es la misma.
GLOBALES = {'clk', 'rst', 'tick_fs', 'tick_1ms'}
COLUMNA_CABLES = {
    'u_pll': 1, 'u_rst': 1, 'u_tiempo': 1, 'u_placa': 1, 'u_teclados': 1,
    'u_notas': 2, 'u_control': 2,
    'u_sec': 3,
    'u_sel': 4,
    'u_gestor': 5,
    'u_voz0': 6, 'u_voz1': 6, 'u_voz2': 6,
    'u_audio': 7, 'u_vga': 7, 'u_leds': 7,
}
COL_PINES_SAL = 8
CARRIL = 16          # separacion entre carriles
MARGEN = 24          # entre el fin de los cables cortos y el primer carril


def genera_bdf_cables():
    partes = [ENCABEZADO.replace(
        'Cada puerto lleva un cable con el nombre de su senal:\nlos cables con el mismo nombre estan conectados.',
        'Los cables dibujados unen bloques de columnas vecinas; el reloj, el\n'
        'reset, los pulsos de tiempo y las rebanadas de bus van con cables\n'
        'cortos con nombre. Los cables con el mismo nombre estan conectados.')]
    # 1) tamanos de los simbolos y alturas por columna
    cols = {}
    for (inst, ent, _, mapa) in INSTANCIAS:
        _, conex, ancho, alto = simbolo(ent, inst, 0, 0)
        cols.setdefault(COLUMNA_CABLES[inst], []).append((inst, ent, mapa, ancho, alto))
    ancho_col = {c: max(b[3] for b in bs) for c, bs in cols.items()}
    ancho_col[0] = 168                       # pines de entrada
    # 2) extremos: (columna, lado, y relativo dentro de la columna, inst, puerto, expr, dir)
    #    primero con x = 0 por columna; la x real se suma despues
    extremos = []
    y_bloque = {}
    for c, bs in cols.items():
        y = 0
        for (inst, ent, mapa, ancho, alto) in bs:
            y_bloque[inst] = y
            _, conex, _, _ = simbolo(ent, inst, 0, y)
            dirs = {pp[0]: pp[1] for pp in ENTIDADES[ent]}
            for (cx, cy, p, lado) in conex:
                if mapa[p] is None:
                    continue
                extremos.append({'col': c, 'dx': cx, 'y': cy, 'inst': inst, 'puerto': p,
                                 'expr': mapa[p], 'dir': dirs[p], 'lado': lado})
            y += alto + 64
    y_in = 0
    y_out = 0
    for (n, d, a) in PINES:
        if d == 'in':
            extremos.append({'col': 0, 'dx': 168, 'y': y_in + 8, 'inst': 'pin', 'puerto': n,
                             'expr': n, 'dir': 'out', 'lado': 'der'})
            y_in += 48
        else:
            extremos.append({'col': COL_PINES_SAL, 'dx': 0, 'y': y_out + 8, 'inst': 'pin', 'puerto': n,
                             'expr': n, 'dir': 'in', 'lado': 'izq'})
            y_out += 48
    # 3) redes que se pueden dibujar
    redes = {}
    for e in extremos:
        redes.setdefault(e['expr'], []).append(e)
    dibujo = {}      # expr -> (manejador, [destinos])
    for expr, es in redes.items():
        if expr in GLOBALES or '[' in expr:
            continue
        man = [e for e in es if e['dir'] == 'out']
        if len(man) != 1:
            continue
        m = man[0]
        dest = [e for e in es if e['dir'] == 'in' and e['col'] == m['col'] + 1]
        if dest:
            dibujo[expr] = (m, dest)

    def carriles_y_x(dibujo):
        # carriles por canal (columna del manejador), ordenados por y del manejador
        por_canal = {}
        for expr, (m, dest) in dibujo.items():
            por_canal.setdefault(m['col'], []).append(expr)
        x_col = {0: 0}
        carril = {}
        ultima = max(list(cols) + [COL_PINES_SAL])
        for c in range(0, ultima):
            nets = sorted(por_canal.get(c, []), key=lambda n: dibujo[n][0]['y'])
            ini = x_col[c] + ancho_col.get(c, 0) + TRAMO + MARGEN
            for k, n in enumerate(nets):
                carril[n] = ini + CARRIL * k
            fin = ini + CARRIL * max(len(nets) - 1, 0)
            x_col[c + 1] = max(fin + MARGEN + TRAMO + 32, x_col[c] + ancho_col.get(c, 0) + 240)
            x_col[c + 1] = (x_col[c + 1] + 15) // 16 * 16
            # los carriles dependen de x_col[c], que ya es definitiva
        return x_col, carril

    # 4) quita redes que choquen (tramos horizontales de redes distintas en la misma y)
    while True:
        x_col, carril = carriles_y_x(dibujo)
        horiz = []
        for expr, (m, dest) in dibujo.items():
            xm = x_col[m['col']] + m['dx']
            horiz.append((m['y'], min(xm, carril[expr]), max(xm, carril[expr]), expr))
            for d in dest:
                xd = x_col[d['col']] + d['dx']
                horiz.append((d['y'], min(xd, carril[expr]), max(xd, carril[expr]), expr))
        choque = None
        for i in range(len(horiz)):
            for j in range(i + 1, len(horiz)):
                a, b = horiz[i], horiz[j]
                if a[3] != b[3] and a[0] == b[0] and a[1] <= b[2] and b[1] <= a[2]:
                    choque = b[3]
                    break
            if choque:
                break
        if not choque:
            break
        del dibujo[choque]
    # 5) simbolos, pines y cables
    for c, bs in cols.items():
        for (inst, ent, mapa, ancho, alto) in bs:
            txt, _, _, _ = simbolo(ent, inst, x_col[c], y_bloque[inst])
            partes.append(txt)
    y_in = 0
    y_out = 0
    for (n, d, a) in PINES:
        if d == 'in':
            txt, _, _ = pin(n, d, a, 0, y_in)
            y_in += 48
        else:
            txt, _, _ = pin(n, d, a, x_col[COL_PINES_SAL], y_out)
            y_out += 48
        partes.append(txt)
    dibujados = set()
    for expr, (m, dest) in dibujo.items():
        bus = es_bus(expr) if expr in ANCHOS else False
        xt = carril[expr]
        xm, ym = x_col[m['col']] + m['dx'], m['y']
        partes.append(conector(xm, ym, xt, ym, etiqueta_senal(expr), bus))
        dibujados.add((m['inst'], m['puerto']))
        ys = sorted({ym} | {d['y'] for d in dest})
        for y1, y2 in zip(ys, ys[1:]):
            partes.append(conector(xt, y1, xt, y2, None, bus))
        for d in dest:
            xd = x_col[d['col']] + d['dx']
            if xd != xt:
                partes.append(conector(xt, d['y'], xd, d['y'], None, bus))
            dibujados.add((d['inst'], d['puerto']))
        # puntos de union donde el carril tiene mas de dos tramos
        for y in ys:
            grado = (1 if y == ym else 0) + sum(1 for d in dest if d['y'] == y)
            grado += (1 if y != ys[0] else 0) + (1 if y != ys[-1] else 0)
            if grado >= 3:
                partes.append(f'(junction (pt {xt} {y}))')
    # cables cortos con nombre para todo lo demas
    for e in extremos:
        if (e['inst'], e['puerto']) in dibujados:
            continue
        x = x_col[e['col']] + e['dx']
        et = etiqueta_senal(e['expr'])
        bus = es_bus(e['expr'])
        if e['lado'] == 'izq':
            partes.append(conector(x - TRAMO, e['y'], x, e['y'], et, bus))
        else:
            partes.append(conector(x, e['y'], x + TRAMO, e['y'], et, bus))
    return '\n'.join(partes) + '\n'


def genera_bsf(ent):
    txt, _, ancho, alto = simbolo(ent, 'inst', 0, 0)
    cuerpo = txt.replace('(symbol', '(symbol', 1)
    return ('/*\nSimbolo de ' + ent + ' para el Block Editor. ARCHIVO GENERADO por\n'
            'tools/genera_top.py a partir de rtl/' + ent + '.vhd.\n*/\n'
            '(header "symbol" (version "1.2"))\n' + cuerpo + '\n')


if __name__ == '__main__':
    open(os.path.join(RTL, 'sinte_top.vhd'), 'w', encoding='ascii').write(genera_vhdl())
    q = os.path.join(RAIZ, 'quartus')
    # --sin-cables: diagrama solo con cables cortos con nombre en cada puerto
    bdf = genera_bdf() if '--sin-cables' in sys.argv else genera_bdf_cables()
    open(os.path.join(q, 'sintetizador.bdf'), 'w', encoding='ascii').write(bdf)
    os.makedirs(os.path.join(q, 'simbolos'), exist_ok=True)
    for ent in ENTIDADES:
        open(os.path.join(q, 'simbolos', ent + '.bsf'), 'w', encoding='ascii').write(genera_bsf(ent))
    print('generados: rtl/sinte_top.vhd, quartus/sintetizador.bdf y',
          len(ENTIDADES), 'simbolos en quartus/simbolos/')
