#!/usr/bin/env bash
# Hook "Stop" de Claude Code (configuración del equipo, en .claude/settings.json).
# Se ejecuta cada vez que Claude quiere terminar de responder:
#   1. Corre la verificación de la skill verificar-cambios.
#   2. Si falla por primera vez, no deja terminar a Claude y le pasa los errores para que los corrija.
#   3. Si sigue fallando después de ese intento, lo deja terminar y te muestra los errores
#      (así no queda dando vueltas para siempre si hay algo que no puede arreglar).
#   4. Cuando Claude termina de verdad, suena el aviso de Windows.

# Va a la raíz del proyecto (Claude Code la pasa en CLAUDE_PROJECT_DIR)
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

# Claude Code manda un JSON por la entrada. "stop_hook_active": true significa
# que Claude ya está siguiendo porque este hook lo bloqueó una vez.
entrada=$(cat)
segundo_intento=""
if echo "$entrada" | grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  segundo_intento="sí"
fi

# Sonido de aviso de Windows. La pausa le da tiempo a sonar antes de que PowerShell se cierre.
sonar() {
  powershell.exe -NoProfile -Command "[System.Media.SystemSounds]::Asterisk.Play(); Start-Sleep -Milliseconds 800" > /dev/null 2>&1
}

resultado=$(bash .claude/skills/verificar-cambios/check.sh 2>&1)
if [ $? -eq 0 ]; then
  sonar
  exit 0
fi

# Solo las líneas de error (sin las que dieron OK)
fallas=$(echo "$resultado" | grep -v '^OK')

if [ -z "$segundo_intento" ]; then
  # Código 2: Claude Code no deja terminar y le muestra este texto a Claude
  {
    echo "La verificación de la página falló. Corregí estos problemas (el detalle de cada uno está en .claude/skills/verificar-cambios/reference.md) y volvé a correr check.sh:"
    echo "$fallas"
  } >&2
  exit 2
fi

# Segundo intento: deja terminar y, con código 1, te muestra el error a vos
sonar
{
  echo "La verificación sigue fallando después de un intento de corrección:"
  echo "$fallas"
} >&2
exit 1
