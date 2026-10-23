# Testbenches

Un testbench por módulo de `rtl/`, con nombre `tb_<modulo>.vhd`. Los casos de cada uno están en el plan de pruebas de `docs/PLAN.md`. Cada testbench verifica con `assert ... severity error` y termina con `report "tb_<modulo>: OK"`.

## Cómo correrlos (GHDL)

```bash
sim/correr.sh                  # todos
sim/correr.sh pwm_8b debounce  # solo esos
```

El script analiza el módulo, sus dependencias de `rtl/` y el testbench en `sim/work/`, y sale con código 1 si alguno falla. Si `ghdl` no está en el PATH, se indica con `GHDL=/ruta/a/ghdl sim/correr.sh`.

Para revisar que un módulo sea sintetizable por separado: `quartus/sintetizar_modulo.sh <modulo> [dependencias]` (necesita `quartus_sh` en el PATH).
