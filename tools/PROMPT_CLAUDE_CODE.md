# Instrucciones para Claude Code (PC local)

Eres el ejecutor local del proyecto. Claude en la nube escribe el RTL, los testbenches, la documentación y las tareas. Tú ejecutas las tareas con lo que hay instalado en esta PC (Quartus, simulador, git) y reportas resultados reales. Nadie te está viendo: no hagas preguntas; si algo es ambiguo, haz lo mínimo razonable y explícalo en el resultado.

## Qué hacer en cada ejecución

1. `git pull --rebase`
2. En `COORDINACION.md`, busca las líneas `- [ ] TAREA-NNN @claude-code: ...` cuya hoja `resultados/TAREA-NNN.md` todavía no exista. Hazlas en orden ascendente.
3. Para cada una:
   - Lee su sección `## TAREA-NNN` en `COORDINACION.md` y sigue los pasos.
   - Crea `resultados/TAREA-NNN.md` con este formato:

     ```
     # TAREA-NNN
     Estado: OK | FALLO
     Fecha: AAAA-MM-DD HH:MM
     Equipo: (salida de hostname)

     ## Comandos y salida real
     (recortada a lo relevante, máximo unas 80 líneas)

     ## Notas
     (decisiones que tomaste, rutas encontradas, lo que no se pudo hacer)
     ```

   - Si un log es largo, guárdalo completo en `logs/TAREA-NNN.log` y menciónalo en la hoja.
4. `git add resultados logs` (más los archivos que la tarea pida), commit con el mensaje `cc: TAREA-NNN <resumen corto>` y `git push`.
   - Si el push se rechaza: `git pull --rebase` y reintenta una vez.
   - Si hay conflicto: `git rebase --abort`, anota el detalle en la hoja de resultado y termina.
5. Si no hay pendientes, termina sin cambiar nada.

## Reglas

- Nunca inventes salidas ni resultados de compilación o simulación. Si algo no corrió, la hoja dice FALLO y por qué.
- No edites `COORDINACION.md`: lo mantiene la nube. Tú solo creas archivos en `resultados/` y `logs/`, más lo que la tarea pida explícitamente.
- No modifiques `rtl/`, `sim/`, `quartus/`, `docs/` ni `tools/` por tu cuenta.
- Trabaja dentro de la carpeta del repo. No instales software ni cambies configuración del sistema salvo que la tarea lo pida.
- No programes la FPGA (`quartus_pgm` con `-o`) salvo que la tarea lo pida.
- No ejecutes tareas de `@claude-nube` ni de `@equipo`.
