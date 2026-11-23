// Interruptor de modo claro / oscuro
(function () {
  const root = document.documentElement;
  const boton = document.getElementById("tema-toggle");

  function aplicarTema(tema) {
    root.setAttribute("data-theme", tema);
    const oscuro = tema === "dark";
    boton.textContent = oscuro ? "☀️" : "🌙";
    boton.setAttribute(
      "aria-label",
      oscuro ? "Cambiar a modo claro" : "Cambiar a modo oscuro"
    );
  }

  // El tema inicial ya lo fijó el script del <head>; acá solo sincronizamos el botón.
  aplicarTema(root.getAttribute("data-theme") === "dark" ? "dark" : "light");

  // Indica si la persona eligió un tema con el botón (en esta visita o en una anterior).
  let eligioTema = false;
  try {
    const guardado = localStorage.getItem("tema");
    eligioTema = guardado === "light" || guardado === "dark";
  } catch (e) {
    // Si el navegador bloquea localStorage, se asume que no hay elección guardada.
  }

  boton.addEventListener("click", function () {
    const nuevo = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
    aplicarTema(nuevo);
    eligioTema = true;
    try {
      localStorage.setItem("tema", nuevo);
    } catch (e) {
      // Si el navegador bloquea localStorage, el tema simplemente no se recuerda.
    }
  });

  // Si cambia el tema del sistema con la página abierta, lo seguimos,
  // pero solo mientras la persona no haya elegido uno con el botón.
  const preferenciaOscura = window.matchMedia("(prefers-color-scheme: dark)");
  preferenciaOscura.addEventListener("change", function (evento) {
    if (eligioTema) return;
    aplicarTema(evento.matches ? "dark" : "light");
  });
})();
