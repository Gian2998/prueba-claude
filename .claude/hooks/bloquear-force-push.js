// Hook "PreToolUse" de Claude Code para la herramienta Bash (configuración del equipo, en .claude/settings.json).
// Si el comando es un "git push" forzado, lo bloquea y le dice a Claude que haga un commit nuevo.
// Claude Code manda por la entrada un JSON con el comando en tool_input.command.

let entrada = "";
process.stdin.on("data", (parte) => (entrada += parte));
process.stdin.on("end", () => {
  let comando = "";
  try {
    comando = JSON.parse(entrada).tool_input.command || "";
  } catch (e) {
    // Si no se puede leer el JSON, no bloqueamos nada.
    process.exit(0);
  }

  if (esPushForzado(comando)) {
    // Este JSON le indica a Claude Code que no ejecute el comando y por qué.
    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "No usar force push: hacé un commit nuevo",
      },
    }));
  }
  process.exit(0);
});

// Devuelve true si alguno de los comandos de la línea es un "git push" forzado.
function esPushForzado(comando) {
  // Separa los comandos encadenados con &&, ||, ;, | o saltos de línea.
  const partes = comando.split(/&&|\|\||;|\||\n/);
  return partes.some((parte) => {
    // Divide en palabras y les saca las comillas.
    const palabras = parte.trim().split(/\s+/).map((p) => p.replace(/^["']|["']$/g, ""));
    // Saltea asignaciones de variables al principio, como GIT_TRACE=1 git push ...
    while (palabras.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(palabras[0])) palabras.shift();
    if (palabras[0] !== "git") return false;
    const posPush = palabras.indexOf("push");
    if (posPush === -1) return false;
    return palabras.slice(posPush + 1).some((p) =>
      p === "--force" ||
      p.startsWith("--force-with-lease") ||
      p === "--force-if-includes" ||
      /^-[a-zA-Z]*f[a-zA-Z]*$/.test(p) ||   // -f, o combinado como -uf
      /^\+[^\s]/.test(p)                     // +main: fuerza esa rama
    );
  });
}
