# Reportes de Quartus

Reportes que genero Quartus II 13.0 SP1 Web Edition al compilar el sintetizador para la EP2C5T144C8 en la PC del laboratorio (TAREA-025, 9 de noviembre de 2026), copiados tal cual de `quartus/output_files/`:

| Archivo | Etapa |
|---|---|
| `sintetizador.flow.rpt` | resumen del flujo completo (recursos y estado de cada etapa) |
| `sintetizador.map.rpt` | Analysis & Synthesis: recursos por modulo, memorias inferidas y maquinas de estados extraidas |
| `sintetizador.fit.rpt` | Fitter: recursos por entidad, pines asignados y memorias M4K |
| `sintetizador.sta.rpt` | TimeQuest: Fmax, setup y hold (modelos lento y rapido) |

Se vuelven a generar con `sh quartus/compilar.sh` (quedan en `quartus/output_files/`, que no se versiona).
