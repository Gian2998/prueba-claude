// Hook "PreToolUse" de Claude Code para las herramientas Bash y PowerShell (configuración del equipo, en .claude/settings.json).
// Si el comando contiene una clave secreta "sk_live_...", la reemplaza por REDACTED
// y le pide permiso al usuario antes de ejecutar el comando ya censurado.
// Claude Code manda por la entrada un JSON con los datos de la herramienta en tool_input.

// Busca "sk_live_" seguido de letras, números, guiones o guiones bajos.
const CLAVE_SECRETA = /sk_live_[A-Za-z0-9_-]*/g;

let entrada = "";
process.stdin.on("data", (parte) => (entrada += parte));
process.stdin.on("end", () => {
  let datos;
  try {
    datos = JSON.parse(entrada).tool_input || {};
  } catch (e) {
    // Si no se puede leer el JSON, no hacemos nada.
    process.exit(0);
  }

  // updatedInput reemplaza todos los datos de la herramienta, así que copiamos
  // todos los campos y censuramos los que son texto (command, description, etc.).
  let encontrada = false;
  const datosCensurados = {};
  for (const [campo, valor] of Object.entries(datos)) {
    if (typeof valor === "string" && valor.match(CLAVE_SECRETA)) {
      encontrada = true;
      datosCensurados[campo] = valor.replace(CLAVE_SECRETA, "REDACTED");
    } else {
      datosCensurados[campo] = valor;
    }
  }

  if (encontrada) {
    // "ask": Claude Code le muestra el comando censurado al usuario y le pide permiso.
    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: "Se reemplazó una clave secreta sk_live_ por REDACTED",
        updatedInput: datosCensurados,
      },
    }));
  }
  process.exit(0);
});
