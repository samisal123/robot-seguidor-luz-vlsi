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
# que el diagrama siempre coincide con el VHDL. En el .bdf cada
# puerto lleva un tramo de cable con el nombre de su senal; los
# cables con el mismo nombre quedan conectados.
#
# Uso: python3 tools/genera_top.py
# ============================================================
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RTL = os.path.join(RAIZ, 'rtl')

# ------------------------------------------------------------
# Red del sintetizador
# ------------------------------------------------------------
# Pines de la tarjeta: (nombre, direccion, ancho o None)
PINES = [
    ('MAX10_CLK1_50', 'in', None),
    ('KEY', 'in', 2),
    ('SW', 'in', 10),
    ('TEC1_COL', 'in', 4),
    ('TEC2_COL', 'in', 4),
    ('LEDR', 'out', 10),
    ('HEX0', 'out', 8),
    ('HEX1', 'out', 8),
    ('HEX2', 'out', 8),
    ('HEX3', 'out', 8),
    ('HEX4', 'out', 8),
    ('HEX5', 'out', 8),
    ('TEC1_FIL', 'out', 4),
    ('TEC2_FIL', 'out', 4),
    ('AUDIO_PWM', 'out', None),
    ('VGA_R', 'out', 4),
    ('VGA_G', 'out', 4),
    ('VGA_B', 'out', 4),
    ('VGA_HS', 'out', None),
    ('VGA_VS', 'out', None),
]

# Senales internas: (nombre, ancho o None)
SENALES = [
    ('rst', None), ('tick_fs', None), ('tick_1ms', None),
    ('accion', None), ('metro_btn', None), ('modo', 2),
    ('teclas', 32), ('vivo', 21), ('func', 8), ('ultima', 7),
    ('forma', 2), ('atk', 2), ('dec', 2), ('sus', 2), ('rel', 2),
    ('volumen', 3), ('tempo', 2), ('efecto', 2),
    ('metro_on', None), ('metro_suena', None),
    ('octava', 3), ('parametro', 3),
    ('cmd_grabar', None), ('cmd_reproducir', None), ('cmd_parar', None),
    ('grabado', 21), ('estado_sec', 2), ('eventos', 9), ('posicion', 9), ('llena', None),
    ('pedidas', 21), ('notas_v', 21), ('gates', 3), ('activas', 3),
    ('muestras', 24), ('niveles', 24),
    ('beat', None), ('acento', None), ('clip', None),
]

# Instancias: (nombre, entidad, columna, {puerto: senal})
# senal puede ser 'nombre', 'nombre[a..b]', 'nombre[i]' o None (sin conectar)
CLK = 'MAX10_CLK1_50'
INSTANCIAS = [
    ('u_rst', 'reset_encendido', 1, {'clk': CLK, 'rst': 'rst'}),
    ('u_tiempo', 'base_tiempo', 1, {'clk': CLK, 'rst': 'rst',
                                    'tick_fs': 'tick_fs', 'tick_1ms': 'tick_1ms'}),
    ('u_placa', 'entradas_placa', 1, {'clk': CLK, 'rst': 'rst', 'tick_1ms': 'tick_1ms',
                                      'key': 'KEY', 'sw': 'SW', 'accion': 'accion',
                                      'metro_btn': 'metro_btn', 'modo': 'modo'}),
    ('u_teclados', 'interfaz_teclados', 1, {'clk': CLK, 'rst': 'rst', 'tick_1ms': 'tick_1ms',
                                            'tec1_col': 'TEC1_COL', 'tec2_col': 'TEC2_COL',
                                            'tec1_fil': 'TEC1_FIL', 'tec2_fil': 'TEC2_FIL',
                                            'teclas': 'teclas'}),
    ('u_notas', 'teclas_notas', 2, {'clk': CLK, 'rst': 'rst', 'teclas': 'teclas',
                                    'octava': 'octava', 'notas': 'vivo', 'func': 'func',
                                    'ultima': 'ultima'}),
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
                                  'eventos': 'eventos', 'posicion': 'posicion', 'llena': 'llena'}),
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
                                    'clip': 'clip', 'nivel': None}),
    ('u_hex', 'display_hex', 5, {'clk': CLK, 'modo': 'modo', 'parametro': 'parametro',
                                 'forma': 'forma', 'atk': 'atk', 'dec': 'dec', 'sus': 'sus',
                                 'rel': 'rel', 'volumen': 'volumen', 'tempo': 'tempo',
                                 'efecto': 'efecto', 'octava': 'octava', 'ultima': 'ultima',
                                 'posicion': 'posicion', 'hex0': 'HEX0', 'hex1': 'HEX1',
                                 'hex2': 'HEX2', 'hex3': 'HEX3', 'hex4': 'HEX4', 'hex5': 'HEX5'}),
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
                                  'activas': 'activas', 'metro_on': 'metro_on', 'beat': 'beat',
                                  'estado_sec': 'estado_sec', 'llena': 'llena',
                                  'efecto': 'efecto', 'clip': 'clip', 'ledr': 'LEDR'}),
]


# ------------------------------------------------------------
# Lectura de entidades
# ------------------------------------------------------------
def lee_entidad(nombre):
    """Regresa la lista de puertos [(nombre, dir, ancho o None, msb, lsb)]."""
    texto = open(os.path.join(RTL, nombre + '.vhd'), encoding='ascii').read()
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
    w('-- Sintetizador musical digital sobre la DE10-Lite (MAX 10).')
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
    w('--   control: modos (SW9-SW8), teclas de funcion, KEY0 y KEY1,')
    w('--   parametros y ordenes al secuenciador')
    w('--   display_hex, vga_ui y leds_estado: interfaz de usuario')
    w('-- ============================================================')
    w('library ieee;')
    w('use ieee.std_logic_1164.all;')
    w('')
    w('entity sinte_top is')
    w('    port (')
    lineas = []
    for (n, d, a) in PINES:
        lineas.append(f'        {n:<13} : {d:<3} {vhdl_tipo(a)}')
    w(';\n'.join(lineas))
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


def genera_bsf(ent):
    txt, _, ancho, alto = simbolo(ent, 'inst', 0, 0)
    cuerpo = txt.replace('(symbol', '(symbol', 1)
    return ('/*\nSimbolo de ' + ent + ' para el Block Editor. ARCHIVO GENERADO por\n'
            'tools/genera_top.py a partir de rtl/' + ent + '.vhd.\n*/\n'
            '(header "symbol" (version "1.2"))\n' + cuerpo + '\n')


if __name__ == '__main__':
    open(os.path.join(RTL, 'sinte_top.vhd'), 'w', encoding='ascii').write(genera_vhdl())
    q = os.path.join(RAIZ, 'quartus')
    open(os.path.join(q, 'sintetizador.bdf'), 'w', encoding='ascii').write(genera_bdf())
    os.makedirs(os.path.join(q, 'simbolos'), exist_ok=True)
    for ent in ENTIDADES:
        open(os.path.join(q, 'simbolos', ent + '.bsf'), 'w', encoding='ascii').write(genera_bsf(ent))
    print('generados: rtl/sinte_top.vhd, quartus/sintetizador.bdf y',
          len(ENTIDADES), 'simbolos en quartus/simbolos/')
