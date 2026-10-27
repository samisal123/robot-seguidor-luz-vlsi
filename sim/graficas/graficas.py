#!/usr/bin/env python3
# ============================================================
# graficas.py
# Dibuja las graficas de simulacion para el reporte a partir de
# los CSV de sim/graficas/salida/ (ver genera.sh). Las guarda en
# docs/img/sim_*.png.
# ============================================================
import csv
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
SAL = os.path.join(AQUI, 'salida')
IMG = os.path.join(AQUI, '..', '..', 'docs', 'img')
FS = 50e6 / 1024

TINTA = '#1d2733'
GRIS = '#6b7785'
AZUL = '#1f5fae'
NARANJA = '#d9771a'
VERDE = '#178245'
MORADO = '#6a4cc4'
ROJO = '#c7372b'

plt.rcParams.update({
    'font.family': 'DejaVu Sans',
    'font.size': 10,
    'axes.edgecolor': GRIS,
    'axes.labelcolor': TINTA,
    'axes.titlesize': 11,
    'axes.titleweight': 'bold',
    'axes.grid': True,
    'grid.color': '#dde3e9',
    'grid.linewidth': 0.6,
    'xtick.color': GRIS,
    'ytick.color': GRIS,
    'figure.dpi': 110,
    'savefig.dpi': 160,
    'savefig.bbox': 'tight',
})


def lee(nombre):
    with open(os.path.join(SAL, nombre)) as f:
        filas = list(csv.reader(f, delimiter=';'))
    cab = filas[0]
    datos = {c: [] for c in cab}
    for fila in filas[1:]:
        for c, v in zip(cab, fila):
            v = v.strip().strip("'")
            try:
                datos[c].append(float(v))
            except ValueError:
                datos[c].append(v)
    return {c: np.array(v) for c, v in datos.items()}


def bit(v):
    return np.array([1.0 if (x == 1 or x == '1') else 0.0 for x in v])


def guarda(fig, nombre):
    fig.savefig(os.path.join(IMG, nombre))
    plt.close(fig)
    print('docs/img/' + nombre)


# ------------------------------------------------------------
def voz():
    d = lee('voz.csv')
    t = d['n'] / FS * 1000
    gate = bit(d['gate'])
    fig, ax = plt.subplots(3, 1, figsize=(9, 8.2), gridspec_kw={'height_ratios': [1.25, 1, 1]})
    a = ax[0]
    a.fill_between(t, 0, gate * 270, color=AZUL, alpha=0.12, step='post', label='gate (tecla presionada)')
    a.plot(t, d['nivel'], color=AZUL, lw=1.8, label='nivel de la envolvente')
    a.set_ylim(-5, 280)
    a.set_xlim(0, 750)
    a.set_ylabel('nivel (0 a 255)')
    a.set_title('Envolvente ADSR: attack 50 ms, decay 200 ms, sustain 50 %, release 150 ms')
    for x, txt in ((35, 'A'), (110, 'D'), (330, 'S'), (560, 'R')):
        a.text(x, 262, txt, color=TINTA, fontsize=12, fontweight='bold', ha='center')
    a.legend(loc='center right', frameon=False)
    m = (t >= 8) & (t <= 40)
    a = ax[1]
    a.plot(t[m], d['cuadrada'][m], color=NARANJA, lw=1.1, label='cuadrada')
    a.plot(t[m], d['triangular'][m], color=VERDE, lw=1.1, label='triangular')
    a.plot(t[m], d['nivel'][m] / 2, color=AZUL, lw=1, ls='--', label='nivel / 2')
    a.set_title('Salida de la voz (A3 = 220 Hz) durante el attack')
    a.set_ylabel('muestra')
    a.set_xlabel('tiempo (ms)')
    a.legend(loc='upper left', frameon=False, ncol=3)
    m = (t >= 495) & (t <= 530)
    a = ax[2]
    a.plot(t[m], d['cuadrada'][m], color=NARANJA, lw=1.1, label='cuadrada')
    a.plot(t[m], d['triangular'][m], color=VERDE, lw=1.1, label='triangular')
    a.axvline(500, color=GRIS, lw=1, ls=':')
    a.text(500.5, 60, 'se suelta la tecla', color=GRIS, fontsize=9)
    a.set_title('Inicio del release')
    a.set_ylabel('muestra')
    a.set_xlabel('tiempo (ms)')
    fig.tight_layout()
    guarda(fig, 'sim_voz.png')


# ------------------------------------------------------------
def formas():
    d = lee('formas.csv')
    fig, ax = plt.subplots(2, 2, figsize=(9, 5.2), sharex=True, sharey=True)
    nombres = [('cuadrada', 'Cuadrada', NARANJA), ('triangular', 'Triangular', VERDE),
               ('sierra', 'Sierra', MORADO), ('seno', 'Seno (tabla de 256)', AZUL)]
    for a, (c, titulo, color) in zip(ax.flat, nombres):
        a.step(d['k'] / 256, d[c], where='post', color=color, lw=1.4)
        a.set_title(titulo)
        a.set_ylim(-140, 140)
        a.set_yticks([-127, 0, 127])
    for a in ax[1]:
        a.set_xlabel('fase (periodos)')
    for a in ax[:, 0]:
        a.set_ylabel('muestra')
    fig.suptitle('Formas de onda a partir de la fase del DDS (2 periodos)', fontweight='bold')
    fig.tight_layout()
    guarda(fig, 'sim_formas.png')


# ------------------------------------------------------------
def teclado():
    d = lee('teclado.csv')
    t = d['t_ms']
    fig, ax = plt.subplots(3, 1, figsize=(9, 5.6), sharex=True,
                           gridspec_kw={'height_ratios': [1.3, 1, 1]})
    ax[0].step(t, d['fila'], where='post', color=AZUL, lw=1.2)
    ax[0].set_yticks([1, 2, 3, 4])
    ax[0].set_ylabel('fila activa')
    ax[0].set_title('Barrido del teclado (una fila por ms) y antirrebote de la tecla "6"')
    ax[1].step(t, d['col3_crudo'], where='post', color=NARANJA, lw=1.1)
    ax[1].set_yticks([0, 1])
    ax[1].set_ylabel('columna 3\n(pin)')
    tecla = bit(d['tecla_filtrada'])
    ax[2].step(t, tecla, where='post', color=VERDE, lw=1.6)
    ax[2].set_yticks([0, 1])
    ax[2].set_ylabel('tecla\nfiltrada')
    ax[2].set_xlabel('tiempo (ms)')
    for a in ax:
        a.set_xlim(0, 100)
    fig.tight_layout()
    guarda(fig, 'sim_teclado.png')


# ------------------------------------------------------------
NOMBRES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def nombre_nota(n):
    return NOMBRES[n % 12] + str(n // 12)


def secuenciador():
    d = lee('secuenciador.csv')
    t = d['t_ms']
    est = d['estado']
    fig, ax = plt.subplots(2, 1, figsize=(9, 5.8), sharex=False)
    i_g = np.where(est == 1)[0]
    i_r = np.where(est == 2)[0]
    paneles = ((ax[0], 'vivo', i_g, 'Grabacion: notas del teclado', ROJO),
               (ax[1], 'sal', i_r, 'Reproduccion: notas que manda el secuenciador', VERDE))
    for a, pref, idx, titulo, color in paneles:
        t0 = t[idx[0]]
        for k in (1, 2, 3):
            v = d[pref + str(k)][idx]
            tt = t[idx] - t0
            for j in range(len(v)):
                if v[j] > 0:
                    a.add_patch(plt.Rectangle((tt[j], v[j] - 0.4), 1, 0.8, color=color, lw=0))
        a.set_xlim(0, max(t[i_g[-1]] - t[i_g[0]], t[i_r[-1]] - t[i_r[0]]) + 10)
        a.set_ylim(46, 57)
        notas = [48, 50, 52, 53, 55]
        a.set_yticks(notas)
        a.set_yticklabels([nombre_nota(n) for n in notas])
        a.set_title(titulo)
        a.set_ylabel('nota')
    ax[1].set_xlabel('tiempo desde el inicio (ms)')
    fig.tight_layout()
    guarda(fig, 'sim_secuenciador.png')


# ------------------------------------------------------------
def efectos():
    d = lee('efectos.csv')
    t = d['n'] / FS * 1000
    fig, ax = plt.subplots(2, 1, figsize=(9, 5.8))
    ax[0].plot(t, d['x'], color='#b8c2cc', lw=0.4, label='entrada (440 Hz)')
    ax[0].plot(t, d['tremolo'], color=AZUL, lw=0.4, label='salida con tremolo')
    ax[0].set_title('Tremolo: LFO de 4.98 Hz, ganancia de 1.0 a 0.5')
    ax[0].set_ylabel('muestra (12 bits)')
    ax[0].legend(loc='upper right', frameon=False, ncol=2)
    ax[1].plot(t, d['eco'], color=VERDE, lw=0.4, label='salida con eco')
    ax[1].plot(t, d['x_eco'], color=NARANJA, lw=0.4, label='entrada (rafaga de 60 ms)')
    for k in range(1, 4):
        ax[1].axvline(k * 8192 / FS * 1000, color=GRIS, lw=0.8, ls=':')
    ax[1].set_title('Eco: retardo de 8192 muestras (167.8 ms), cada repeticion a la mitad')
    ax[1].set_ylabel('muestra (12 bits)')
    ax[1].set_xlabel('tiempo (ms)')
    ax[1].legend(loc='upper right', frameon=False, ncol=2)
    for a in ax:
        a.set_xlim(0, 600)
    fig.tight_layout()
    guarda(fig, 'sim_efectos.png')


# ------------------------------------------------------------
def metronomo():
    d = lee('metronomo.csv')
    t = d['n'] / 48.75          # 48.75 muestras por ms en esta simulacion
    beat = bit(d['beat']) > 0
    acento = bit(d['acento']) > 0
    fig, ax = plt.subplots(2, 1, figsize=(9, 5.2))
    ax[0].plot(t, d['clic'], color=GRIS, lw=0.5)
    for x in t[beat & ~acento]:
        ax[0].axvline(x, color=VERDE, lw=1.5)
    for x in t[beat & acento]:
        ax[0].axvline(x, color=ROJO, lw=2)
    ax[0].set_title('Metronomo a 120 BPM: un tiempo cada 500 ms, acento (rojo) cada 4')
    ax[0].set_ylabel('clic')
    ax[0].set_xlabel('tiempo (ms)')
    ax[0].set_xlim(-20, 2100)
    primero = t[beat][1] if beat.sum() > 1 else 0
    m = (t >= primero - 2) & (t <= primero + 30)
    ax[1].plot(t[m], d['clic'][m], color=AZUL, lw=1)
    ax[1].set_title('Clic de un tiempo normal: cuadrada de 2 kHz que se apaga en 24.7 ms')
    ax[1].set_ylabel('clic')
    ax[1].set_xlabel('tiempo (ms)')
    fig.tight_layout()
    guarda(fig, 'sim_metronomo.png')


# ------------------------------------------------------------
def pwm():
    d = lee('pwm.csv')
    c = d['ciclo']
    p = d['pwm']
    dt = 20e-9
    rc = 1e3 * 10e-9
    v1 = v2 = 3.3 * 0.5
    sal = np.empty(len(p))
    for i, b in enumerate(p):
        vin = 3.3 * b
        i1 = (vin - v1) / 1e3
        i2 = (v1 - v2) / 1e3
        v1 += (i1 - i2) * dt / 10e-9
        v2 += i2 * dt / 10e-9
        sal[i] = v2
    t = c * dt * 1000
    fig, ax = plt.subplots(2, 1, figsize=(9, 5.4))
    m = c < 2048
    ax[0].step(c[m] * dt * 1e6, p[m] * 3.3, where='post', color=NARANJA, lw=0.9)
    ax[0].set_title('PWM de 8 bits a 195.3 kHz (8 periodos de 5.12 us)')
    ax[0].set_ylabel('AUDIO_PWM (V)')
    ax[0].set_xlabel('tiempo (us)')
    ax[1].plot(t, sal, color=AZUL, lw=1.2, label='salida del filtro RC (simulada)')
    ax[1].plot(t, 1.65 + d['muestra'] * 3.3 / 256, color=GRIS, lw=0.9, ls='--',
               label='muestra digital escalada')
    ax[1].set_title('Senoidal de 1 kHz despues del filtro RC de 2 etapas (1 kOhm, 10 nF)')
    ax[1].set_ylabel('volts')
    ax[1].set_xlabel('tiempo (ms)')
    ax[1].legend(loc='upper right', frameon=False)
    fig.tight_layout()
    guarda(fig, 'sim_pwm.png')


if __name__ == '__main__':
    os.makedirs(IMG, exist_ok=True)
    voz()
    formas()
    teclado()
    secuenciador()
    efectos()
    metronomo()
    pwm()
