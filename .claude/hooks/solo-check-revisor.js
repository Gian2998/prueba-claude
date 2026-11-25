// Hook "PreToolUse" de Claude Code para el subagente code-reviewer (configuración del equipo,
// en el frontmatter de .claude/agents/code-reviewer.md).
// El revisor es de solo lectura: con Bash solo puede ejecutar el check.sh de la skill verificar-cambios.
// Cualquier otro comando (incluso check.sh encadenado con otro, como "check.sh; rm x") se bloquea.
// Claude Code manda por la entrada un JSON con el comando en tool_input.command y el nombre
// del subagente en agent_type.

const path = require("path");

let entrada = "";
process.stdin.on("data", (parte) => (entrada += parte));
process.stdin.on("end", () => {
  let datos;
  try {
    datos = JSON.parse(entrada);
  } catch (e) {
    // Si no se puede leer el JSON, no sabemos qué comando es: lo bloqueamos por las dudas.
    bloquear("No se pudo leer el comando.");
    return;
  }

  // Solo vigilamos al revisor. Su nombre es "code-reviewer" o, si viene del plugin,
  // "kit-gianfranco:code-reviewer". Para cualquier otro, este hook no hace nada.
  const agente = datos.agent_type || "";
  if (agente !== "code-reviewer" && !agente.endsWith(":code-reviewer")) {
    process.exit(0);
  }

  const comando = (datos.tool_input && datos.tool_input.command) || "";
  if (!esCheckSh(comando)) {
    bloquear(
      "El revisor es de solo lectura: con Bash solo puede ejecutar check.sh, " +
      "con el comando exacto que indica la skill verificar-cambios."
    );
    return;
  }
  process.exit(0);
});

// Le indica a Claude Code que no ejecute el comando y por qué.
function bloquear(motivo) {
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: motivo,
    },
  }));
  process.exit(0);
}

// Devuelve true si el comando es exactamente "bash <ruta de check.sh>", sin nada más.
function esCheckSh(comando) {
  const script = "skills/verificar-cambios/scripts/check.sh";
  const permitidos = [
    // Copia del proyecto, como la escribe su SKILL.md
    "bash .claude/" + script,
    // Copia del plugin, por si el SKILL.md llega con la variable sin reemplazar
    "bash ${CLAUDE_PLUGIN_ROOT}/" + script,
    "bash $CLAUDE_PLUGIN_ROOT/" + script,
    // La carpeta que contiene a hooks/: en el proyecto es .claude y en el plugin es su raíz
    "bash " + path.resolve(__dirname, "..") + "/" + script,
  ];
  if (process.env.CLAUDE_PROJECT_DIR) {
    permitidos.push("bash " + process.env.CLAUDE_PROJECT_DIR + "/.claude/" + script);
  }
  if (process.env.CLAUDE_PLUGIN_ROOT) {
    permitidos.push("bash " + process.env.CLAUDE_PLUGIN_ROOT + "/" + script);
  }
  return permitidos.map(normalizar).includes(normalizar(comando));
}

// Escribe el comando de una sola forma para poder compararlo: sin comillas, con barras "/",
// con un solo espacio entre palabras, en minúsculas (Windows no distingue mayúsculas en las
// rutas) y con /c/... convertido en c:/...
function normalizar(texto) {
  return texto
    .trim()
    .replace(/["']/g, "")
    .replace(/\\/g, "/")
    .replace(/\s+/g, " ")
    .replace(/(^| )\/([a-z])\//gi, "$1$2:/")
    .toLowerCase();
}
