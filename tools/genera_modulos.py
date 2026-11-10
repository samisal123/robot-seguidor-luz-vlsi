#!/usr/bin/env python3
# ============================================================
# genera_modulos.py
# Arma docs/MODULOS.md a partir del codigo: para cada archivo de
# rtl/ toma el encabezado (la descripcion del modulo), los
# genericos y los puertos de la entidad con sus comentarios, y el
# testbench que lo verifica. Asi la descripcion de los modulos y
# la definicion de sus interfaces siempre coinciden con el VHDL.
#
# Uso: python3 tools/genera_modulos.py
# ============================================================
import os
import re

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RTL = os.path.join(RAIZ, 'rtl')
SIM = os.path.join(RAIZ, 'sim')
SALIDA = os.path.join(RAIZ, 'docs', 'MODULOS.md')

# orden de presentacion: de la entrada a la salida
GRUPOS = [
    ('Nivel superior', ['sinte_top']),
    ('Reloj, reset y tiempos', ['reset_encendido', 'base_tiempo', 'sync_2ff', 'debounce']),
    ('Entradas', ['interfaz_teclados', 'teclado_scan', 'teclas_notas', 'entradas_placa']),
    ('Control y secuenciador', ['control', 'selector_notas', 'secuenciador', 'memoria_eventos']),
    ('Voces', ['gestor_voces', 'voz', 'dds', 'forma_onda', 'adsr']),
    ('Audio', ['audio_salida', 'mezclador', 'tremolo', 'eco', 'volumen', 'metronomo', 'salida_pwm']),
    ('Indicadores', ['leds_estado', 'vga_ui']),
    ('Paquetes', ['synth_pkg', 'fuente_5x7']),
]


def encabezado(lineas):
    """Lineas de comentario entre el nombre del archivo y la linea de ===."""
    txt = []
    dentro = False
    for l in lineas:
        s = l.rstrip('\n')
        if not s.startswith('--'):
            if dentro:
                break
            continue
        c = s[2:]
        if c.strip().startswith('====='):
            if dentro:
                break
            continue
        if not dentro and c.strip().endswith('.vhd'):
            dentro = True
            continue
        if dentro:
            txt.append(c[1:] if c.startswith(' ') else c)
    return txt


def entidad(codigo):
    """Nombre, genericos y puertos de la entidad (con su comentario)."""
    m = re.search(r'^entity\s+(\w+)\s+is(.*?)^end\s+entity', codigo, re.S | re.M | re.I)
    if not m:
        return None, [], []
    nombre, cuerpo = m.group(1), m.group(2)

    def bloque(palabra):
        b = re.search(palabra + r'\s*\((.*?)\n\s*\);', cuerpo, re.S | re.I)
        if not b:
            return []
        items = []
        for l in b.group(1).split('\n'):
            l = l.strip()
            if not l or l.startswith('--'):
                if l.startswith('--') and items:
                    items[-1][3] = (items[-1][3] + ' ' + l[2:].strip()).strip()
                continue
            com = ''
            if '--' in l:
                l, com = l.split('--', 1)
                com = com.strip()
            l = l.strip().rstrip(';').strip()
            if ':' not in l:
                continue
            izq, der = l.split(':', 1)
            der = der.strip()
            if palabra == 'port':
                d = re.match(r'(in|out|inout|buffer)\s+(.*)', der, re.I)
                direc, tipo = (d.group(1).lower(), d.group(2)) if d else ('', der)
            else:
                direc, tipo = '', der
            for n in izq.split(','):
                items.append([n.strip(), direc, tipo.strip(), com])
        return items

    return nombre, bloque('generic'), bloque('port')


def esc(s):
    return s.replace('|', '\\|')


def main():
    tbs = {f[3:-4] for f in os.listdir(SIM) if f.startswith('tb_') and f.endswith('.vhd')}
    hechos = set()
    out = ['# Módulos e interfaces', '',
           'Generado con `python3 tools/genera_modulos.py` a partir de los encabezados y las entidades de `rtl/` '
           '(no se edita a mano). La arquitectura, las FSM y las decisiones de diseño están en '
           '[ARQUITECTURA.md](ARQUITECTURA.md); cómo se verifica cada módulo, en [PRUEBAS.md](PRUEBAS.md).', '',
           'Convenciones: un solo reloj `clk` de 25 MHz; `rst` síncrono y activo en alto; los pulsos `tick_fs` '
           '(una vez por muestra, 48 828 Hz) y `tick_1ms` duran un ciclo; las señales activas en bajo terminan en `_n`.', '']
    indice = []
    cuerpo = []
    for grupo, mods in GRUPOS:
        cuerpo += ['## ' + grupo, '']
        for mod in mods:
            ruta = os.path.join(RTL, mod + '.vhd')
            if not os.path.exists(ruta):
                continue
            hechos.add(mod)
            lineas = open(ruta).readlines()
            codigo = ''.join(lineas)
            desc = encabezado(lineas)
            nombre, gens, ports = entidad(codigo)
            indice.append(f'[`{mod}`](#{mod})')
            cuerpo += [f'### {mod}', '']
            # descripcion: el encabezado tal cual (bloque preformateado si trae diagramas)
            parrafo = '\n'.join(desc).strip('\n')
            if parrafo:
                cuerpo += ['```text', parrafo, '```', '']
            if gens:
                cuerpo += ['| Genérico | Tipo y valor | Comentario |', '|---|---|---|']
                for n, _, t, c in gens:
                    cuerpo.append(f'| `{n}` | `{esc(t)}` | {esc(c)} |')
                cuerpo.append('')
            if ports:
                cuerpo += ['| Puerto | Dir. | Tipo | Comentario |', '|---|---|---|---|']
                for n, d, t, c in ports:
                    cuerpo.append(f'| `{n}` | {d} | `{esc(t)}` | {esc(c)} |')
                cuerpo.append('')
            prueba = 'tb_' + mod if mod in tbs else None
            if prueba:
                cuerpo += [f'Verificación: `sim/{prueba}.vhd`.', '']
            elif mod.endswith('_pkg') or mod == 'fuente_5x7':
                cuerpo += ['Paquete: lo usan los módulos que lo importan; sus tablas se revisan en los testbenches de esos módulos.', '']
            else:
                cuerpo += ['Verificación: dentro del testbench del módulo que lo contiene.', '']
    resto = sorted(f[:-4] for f in os.listdir(RTL) if f.endswith('.vhd') and f[:-4] not in hechos)
    if resto:
        cuerpo += ['## Otros', '']
        for mod in resto:
            cuerpo += [f'### {mod}', '', f'Ver `rtl/{mod}.vhd`.', '']
    out += ['Índice: ' + ' · '.join(indice), ''] + cuerpo
    open(SALIDA, 'w').write('\n'.join(out).rstrip('\n') + '\n')
    print(SALIDA, len(hechos), 'modulos')


if __name__ == '__main__':
    main()
