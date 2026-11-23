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

  boton.addEventListener("click", function () {
    const nuevo = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
    aplicarTema(nuevo);
    try {
      localStorage.setItem("tema", nuevo);
    } catch (e) {
      // Si el navegador bloquea localStorage, el tema simplemente no se recuerda.
    }
  });
})();
