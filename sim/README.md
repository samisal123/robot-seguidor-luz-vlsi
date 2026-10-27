# Testbenches

Un testbench por módulo de `rtl/`, con nombre `tb_<modulo>.vhd`, más la prueba del sistema completo (`tb_sinte_top.vhd`). Cada testbench verifica con `assert ... severity error` y termina con `report "tb_<modulo>: OK"`. Lo que revisa cada uno está en su encabezado y en [docs/PRUEBAS.md](../docs/PRUEBAS.md).

Modelos que usan las pruebas (los importa `correr.sh` automáticamente):

- `modelo_teclado.vhd`: teclado matricial 4 × 4 de membrana con pull-up en las columnas.

`captura_vga.vhd` guarda un cuadro de la VGA como imagen (se corre aparte, ver su encabezado).

## Cómo correrlos (GHDL)

```bash
sh sim/correr.sh                         # todos
sh sim/correr.sh secuenciador adsr       # solo esos
STOP=5sec sh sim/correr.sh sinte_top     # tope de tiempo simulado distinto
```

El script importa todo `rtl/` y los modelos, compila cada testbench en su propia carpeta `sim/work/<modulo>/` y sale con código 1 si alguno falla. Si `ghdl` no está en el PATH, se indica con `GHDL=/ruta/a/ghdl sh sim/correr.sh`.

La prueba del sistema completo simula 1.95 s a 50 MHz y tarda unos 20 minutos con GHDL 4.1; los otros 26 testbenches juntos tardan unos 3.5 minutos. Las salidas de la última corrida están en `logs/`.
