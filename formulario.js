// Validación del formulario de contacto.
// La página no tiene servidor: si todo está bien, solo se muestra un mensaje de éxito.
(function () {
  const form = document.getElementById("form-contacto");
  const estado = document.getElementById("form-estado");
  const campos = [
    document.getElementById("nombre"),
    document.getElementById("email"),
    document.getElementById("mensaje"),
  ];

  // Forma básica de un email: algo@algo.algo, sin espacios.
  const formatoEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  // Se vuelve true al primer intento de envío. Antes de eso no mostramos errores,
  // para no marcar campos que la persona todavía no terminó de completar.
  let intentoEnviar = false;

  // Devuelve el texto del error del campo, o "" si está bien.
  function validarCampo(campo) {
    // trim() saca los espacios del principio y del final.
    const valor = campo.value.trim();

    if (campo.id === "nombre") {
      if (valor === "") return "Escribí tu nombre.";
      if (valor.length < 2) return "El nombre tiene que tener al menos 2 letras.";
    }

    if (campo.id === "email") {
      if (valor === "") return "Escribí tu email.";
      if (!formatoEmail.test(valor)) return "Revisá el email, por ejemplo: nombre@mail.com.";
    }

    if (campo.id === "mensaje") {
      if (valor === "") return "Escribí un mensaje.";
      if (valor.length < 10) return "El mensaje tiene que tener al menos 10 caracteres.";
      if (valor.length > 1000) return "El mensaje no puede pasar de 1000 caracteres.";
    }

    return "";
  }

  // Muestra (o borra) el error debajo del campo.
  // El borde rojo lo pone el CSS a partir de aria-invalid: acá no tocamos colores.
  function mostrarError(campo, texto) {
    document.getElementById(campo.id + "-error").textContent = texto;
    if (texto) {
      campo.setAttribute("aria-invalid", "true");
    } else {
      campo.removeAttribute("aria-invalid");
    }
  }

  form.addEventListener("submit", function (evento) {
    // Evita que la página se recargue al enviar.
    evento.preventDefault();
    intentoEnviar = true;

    let primerCampoConError = null;
    campos.forEach(function (campo) {
      const error = validarCampo(campo);
      mostrarError(campo, error);
      if (error && !primerCampoConError) primerCampoConError = campo;
    });

    if (primerCampoConError) {
      // Llevamos el foco al primer error para que se pueda corregir enseguida.
      primerCampoConError.focus();
      return;
    }

    // Guardamos el nombre antes de vaciar el formulario.
    const nombre = campos[0].value.trim();
    form.reset();
    intentoEnviar = false;
    // textContent (y no innerHTML) muestra el texto tal cual, sin interpretar código.
    estado.textContent = "¡Gracias, " + nombre + "! Tu mensaje fue enviado.";
  });

  campos.forEach(function (campo) {
    campo.addEventListener("input", function () {
      // Si la persona vuelve a escribir, el mensaje de éxito anterior ya no corresponde.
      estado.textContent = "";
      // Después del primer intento, el error se actualiza mientras escribe.
      if (intentoEnviar) mostrarError(campo, validarCampo(campo));
    });
  });
})();
