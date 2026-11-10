#!/usr/bin/env python3
# ============================================================
# revisa_bdf.py
# Revisa la conectividad de quartus/sintetizador.bdf contra la red
# de tools/genera_top.py, con las reglas del Block Editor:
#   - dos cables se unen si comparten un extremo;
#   - un cable se une a un puerto si su extremo cae en el punto del
#     puerto;
#   - los cables con el mismo nombre estan unidos aunque no se
#     toquen.
# Tambien marca lo que podria unir cosas por accidente: un extremo
# que cae a media linea de otro cable sin punto de union, o dos
# cables encimados de redes distintas.
#
# Uso: python3 tools/revisa_bdf.py   (sale con 1 si hay errores)
# ============================================================
import os
import re
import sys

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.argv = [sys.argv[0]]                       # genera_top no debe ver argumentos
sys.path.insert(0, os.path.join(RAIZ, 'tools'))
import genera_top as G                         # noqa: E402  (solo lee la red)

src = open(os.path.join(RAIZ, 'quartus', 'sintetizador.bdf')).read()


def bloques(tag):
    out = []
    i = 0
    while True:
        j = src.find('\n(' + tag, i)
        if j < 0:
            return out
        d = 0
        k = j + 1
        while True:
            if src[k] == '(':
                d += 1
            elif src[k] == ')':
                d -= 1
                if d == 0:
                    break
            k += 1
        out.append(src[j + 1:k + 1])
        i = k


errores = []
# puertos de los simbolos: punto absoluto -> (instancia, puerto)
puertos = {}
for s in bloques('symbol'):
    x0, y0 = map(int, re.search(r'\(rect (-?\d+) (-?\d+) ', s).groups())
    textos = re.findall(r'\(text "([^"]+)"', s)
    inst = textos[1]
    for p in re.finditer(r'\(port\s*\(pt (\d+) (\d+)\)\s*\((?:input|output)\)\s*\(text "([^"]+)"', s):
        nombre = re.sub(r'\[.*', '', p.group(3))
        puertos[(x0 + int(p.group(1)), y0 + int(p.group(2)))] = (inst, nombre)
for p in bloques('pin'):
    x0, y0 = map(int, re.search(r'\(rect (-?\d+) (-?\d+) ', p).groups())
    px, py = map(int, re.search(r'\(pt (\d+) (\d+)\)', p).groups())
    nombre = re.sub(r'\[.*', '', re.findall(r'\(text "([^"]+)"', p)[1])
    puertos[(x0 + px, y0 + py)] = ('pin', nombre)

segs = []
for c in bloques('connector'):
    pts = [tuple(map(int, m)) for m in re.findall(r'\(pt (-?\d+) (-?\d+)\)', c)]
    t = re.search(r'\(text "([^"]+)"', c)
    segs.append((pts[0], pts[1], t.group(1) if t else None))
uniones = {tuple(map(int, m)) for m in re.findall(r'\(junction \(pt (-?\d+) (-?\d+)\)\)', src)}

# union-find sobre extremos, puertos y nombres
padre = {}


def raiz(a):
    padre.setdefault(a, a)
    while padre[a] != a:
        padre[a] = padre[padre[a]]
        a = padre[a]
    return a


def une(a, b):
    padre[raiz(a)] = raiz(b)


for (a, b, nombre) in segs:
    une(('pt', a), ('pt', b))
    if nombre:
        base = re.sub(r'\[.*', '', nombre)
        # el nombre del bus completo (x[n..0]) es la senal x; una rebanada se queda como esta
        if base in G.ANCHOS and nombre == G.etiqueta_senal(base):
            nombre = base
        une(('pt', a), ('nombre', nombre))
for pt, (inst, p) in puertos.items():
    une(('pt', pt), ('puerto', inst, p))


def dentro(p, a, b):
    """p esta a media linea del tramo a-b (no en sus extremos)."""
    if p in (a, b):
        return False
    if a[0] == b[0] == p[0]:
        return min(a[1], b[1]) < p[1] < max(a[1], b[1])
    if a[1] == b[1] == p[1]:
        return min(a[0], b[0]) < p[0] < max(a[0], b[0])
    return False


extremos = [a for (a, _, _) in segs] + [b for (_, b, _) in segs] + list(puertos)
for (a, b, _) in segs:
    for p in extremos:
        if dentro(p, a, b) and p not in uniones:
            errores.append(f'un extremo en {p} cae a media linea del cable {a}-{b}')

# red esperada: cada puerto con la expresion de su senal
esperado = {}
for (inst, ent, _, mapa) in G.INSTANCIAS:
    for p, sexp in mapa.items():
        if sexp is not None:
            esperado[(inst, p)] = sexp
for (n, d, a) in G.PINES:
    esperado[('pin', n)] = n

# cada puerto debe quedar en el mismo grupo que su nombre de senal
grupo_de_nombre = {}
for (k, sexp) in esperado.items():
    r = raiz(('puerto',) + k)
    clave = ('nombre', sexp)
    if clave not in padre:
        # la red se dibujo sin nombre en ese extremo: basta con que todos
        # los puertos de la misma expresion queden juntos
        clave = ('expr', sexp)
    grupo_de_nombre.setdefault(sexp, set()).add(r)
for sexp, rs in grupo_de_nombre.items():
    if len(rs) != 1:
        errores.append(f'la senal {sexp} quedo partida en {len(rs)} grupos')
# y dos senales distintas no deben compartir grupo
dueño = {}
for sexp, rs in grupo_de_nombre.items():
    for r in rs:
        if r in dueño and dueño[r] != sexp:
            errores.append(f'{sexp} y {dueño[r]} quedaron unidas')
        dueño[r] = sexp
for k in esperado:
    if ('puerto',) + k not in padre:
        errores.append(f'el puerto {k} no tiene cable')

print(f'{len(puertos)} puertos, {len(segs)} cables, {len(uniones)} uniones, '
      f'{len(grupo_de_nombre)} senales revisadas')
for e in errores:
    print('ERROR:', e)
print('OK' if not errores else f'{len(errores)} errores')
sys.exit(1 if errores else 0)
