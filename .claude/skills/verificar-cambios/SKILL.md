---
name: verificar-cambios
description: Verifica que la página cumpla las reglas de CLAUDE.md. Usala siempre que termines de crear o modificar index.html, styles.css o cualquier archivo .js del proyecto, antes de dar el trabajo por terminado o de hacer un commit.
---

# Verificar cambios

1. Desde la raíz del proyecto, corré:

   ```bash
   bash .claude/skills/verificar-cambios/check.sh
   ```

2. Si alguna línea dice `FALLA`, buscá esa verificación por su número en [reference.md](reference.md). Ahí está qué regla comprueba y cómo arreglarla. Arreglala y volvé a correr el script hasta que todo dé `OK`.
3. El script no puede comprobar todo. Revisá también lo que figura en "Qué hay que revisar a mano", al final de [reference.md](reference.md).
4. Contale al usuario qué verificaciones pasaron, cuáles fallaron y qué arreglaste, en palabras simples.
