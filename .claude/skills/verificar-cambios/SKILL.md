---
name: verificar-cambios
description: Verifica que la página cumpla las reglas de CLAUDE.md. Usala siempre que termines de crear o modificar index.html, styles.css o cualquier archivo .js del proyecto, antes de dar el trabajo por terminado o de hacer un commit.
---

# Verificar cambios

1. Desde la raíz del proyecto, ejecutá el script:

   ```bash
   bash .claude/skills/verificar-cambios/scripts/check.sh
   ```

   No hace falta leer `scripts/check.sh`: ejecutalo y usá lo que muestra. Cada línea dice `OK` o `FALLA` con su número.

2. Si alguna línea dice `FALLA`, buscá esa verificación por su número en [references/reference.md](references/reference.md). Ahí está qué regla comprueba y cómo arreglarla. Arreglala y volvé a correr el script hasta que todo dé `OK`.
3. El script no puede comprobar todo. Revisá también lo que figura en "Qué hay que revisar a mano", al final de [references/reference.md](references/reference.md).
4. Contale al usuario qué verificaciones pasaron, cuáles fallaron y qué arreglaste, en palabras simples.
