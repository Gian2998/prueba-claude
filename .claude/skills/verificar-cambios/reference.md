# Detalle de las verificaciones

Cada sección tiene el mismo número que la línea de `check.sh`. Las verificaciones leen los archivos como texto; no abren la página en un navegador. Por eso usan reglas simples que pueden equivocarse en casos raros: cada sección dice cuáles.

## 1. Colores fijos solo dentro de los bloques de tema

- **Regla:** cada color es una variable en `:root` y en `[data-theme="dark"]`; las reglas usan solo `var(--…)`.
- **Qué busca:** colores escritos directamente (`#fff`, `#1e3a8a`, `rgb(…)`, `rgba(…)`, `hsl(…)`) en `styles.css` fuera de esos dos bloques, y en `index.html`.
- **Cómo arreglarlo:** creá una variable en los dos bloques de tema y usá `var(--nombre)` en la regla.
- **Límites:** no detecta colores por nombre (`red`, `white`). Un color escrito dentro de un comentario también cuenta como falla.

## 2. Las mismas variables en los dos temas

- **Regla:** cada variable existe con el mismo nombre en `:root` y en `[data-theme="dark"]`.
- **Qué busca:** variables (`--algo:`) que están en un bloque y no en el otro.
- **Cómo arreglarlo:** agregá la variable que falta en el otro bloque, con un color adecuado para ese tema.
- **Límites:** los bloques tienen que empezar al principio de la línea (`:root {`) y cerrarse con `}` al principio de otra línea, como ahora.

## 3. Cada tema declara su color-scheme

- **Regla:** cada tema declara `color-scheme`, para que los controles del navegador (barras de desplazamiento, campos) acompañen el tema.
- **Qué busca:** `color-scheme: light` en `:root` y `color-scheme: dark` en `[data-theme="dark"]`.
- **Cómo arreglarlo:** agregá esa línea al bloque que la tiene ausente.

## 4. Toda variable usada está definida

- **Regla:** se deduce de la 1. Si se usa una variable que no existe, el navegador ignora la propiedad y el color no se aplica.
- **Qué busca:** nombres usados en `var(--…)` que no aparecen definidos como `--nombre:` en ningún lugar de `styles.css`.
- **Cómo arreglarlo:** corregí el nombre (suele ser un error de tipeo) o definí la variable en los dos temas.

## 5. El JavaScript no cambia estilos directamente

- **Regla:** el JavaScript cambia atributos (`data-theme`, `aria-invalid`) y el CSS decide los colores según esos atributos.
- **Qué busca:** `.style` o `setProperty(` en los `.js` y en `index.html`, y atributos `style="…"` en el HTML.
- **Cómo arreglarlo:** en vez de cambiar el estilo, cambiá un atributo o una clase desde JavaScript, y escribí en el CSS una regla para ese atributo. Ejemplo: `formulario.js` pone `aria-invalid="true"` y `styles.css` tiene `.contacto [aria-invalid="true"] { border-color: var(--error); }`.
- **Límites:** también marca usos de `.style` que no cambian colores (por ejemplo, el ancho). Si alguno fuera necesario, conviene igual pasarlo a una clase de CSS.

## 6. localStorage dentro de try/catch

- **Regla:** cada acceso a `localStorage` va dentro de `try/catch`. Algunos navegadores lo bloquean (por ejemplo, en modo privado), y sin `try/catch` el error frenaría todo el script.
- **Qué busca:** recorre los `.js` y el `index.html` contando llaves `{ }` para saber si cada `localStorage` está dentro de las llaves de un `try`. Un `localStorage` dentro de `catch { }` cuenta como falla.
- **Cómo arreglarlo:**

  ```js
  try {
    localStorage.setItem("tema", nuevo);
  } catch (e) {
    // Si el navegador bloquea localStorage, el tema simplemente no se recuerda.
  }
  ```

- **Límites:** se confunde si hay llaves `{` o `}` dentro de textos entre comillas o dentro de comentarios `/* … */`.

## 7. Solo las media queries permitidas

- **Regla:** estilos base para celular; las pantallas grandes con `@media (min-width: 768px)` y los ajustes chicos con `@media (max-width: 480px)`.
- **Qué busca:** cualquier `@media` escrito distinto de esas dos formas exactas.
- **Cómo arreglarlo:** usá uno de los dos cortes permitidos. Si un diseño necesita otro, primero agregalo como regla en `CLAUDE.md` y en este script.

## 8. Sin librerías externas

- **Regla:** HTML, CSS y JavaScript sin librerías ni paso de compilación.
- **Qué busca:** `<script src>` o `<link href>` que apunten a otra página (`https://…` o `//…`), y un archivo `package.json`.
- **Cómo arreglarlo:** escribí el código a mano en los archivos del proyecto.

## 9. Script del head y clave del tema

- **Regla:** el script del `<head>` aplica el tema antes de pintar la página; la clave `tema` la usan ese script y `script.js`.
- **Qué busca:** que antes de `</head>` haya un script que lea `localStorage` y ponga `data-theme`, y que las claves de `localStorage` sean las mismas ahí y en `script.js`.
- **Cómo arreglarlo:** si se movió el script, devolvelo al `<head>`. Si cambiaste la clave en un lado, cambiala también en el otro.

## 10. Archivos .js enlazados al final del body

- **Regla:** cada funcionalidad de JavaScript va en su propio archivo `.js`, enlazado al final del `<body>`.
- **Qué busca:** que cada `.js` de la raíz tenga su `<script src="…">` entre `</footer>` y `</body>`.
- **Cómo arreglarlo:** agregá `<script src="archivo.js"></script>` justo antes de `</body>`.

## 11. :focus-visible y 44px en cada elemento interactivo

- **Regla:** cada elemento interactivo mide al menos 44px de alto (`min-height: 2.75rem`) y tiene un estilo `:focus-visible`.
- **Qué busca:** para cada `<a>`, `<button>`, `<input>`, `<textarea>` y `<select>` del HTML, busca en el CSS:
  - una regla `…:focus-visible` cuya última parte del selector coincida con el elemento (su etiqueta, su `#id` o una de sus `.clases`);
  - una regla con `height` o `min-height` de `2.75rem` o `44px` que coincida de la misma forma.
- **Cómo arreglarlo:** agregá al elemento `min-height: 2.75rem` y una regla como esta:

  ```css
  .mi-boton:focus-visible {
    outline: 3px solid var(--accent);
    outline-offset: 2px;
  }
  ```

- **Límites:** solo mira la última parte del selector. Por ejemplo, considera que `.contacto input` cubre a todos los `<input>`, aunque haya uno fuera de `.contacto`. No calcula el tamaño real en pantalla.

## 12. Sintaxis del JavaScript

- **Qué busca:** errores de escritura en los `.js` (por ejemplo, una llave sin cerrar), con `node --check`. Un error así hace que no funcione nada del archivo.
- **Límites:** se saltea si `node` no está instalado. No revisa los scripts escritos dentro del HTML.

## Qué hay que revisar a mano

El script no puede comprobar estas reglas de `CLAUDE.md`. Revisalas siguiendo la sección "Cómo probar" de `CLAUDE.md`:

- **Contraste de 4.5:1** entre cada texto y su fondo, en los dos temas. Para un color nuevo, medilo con un comprobador de contraste (por ejemplo, el que tienen las herramientas de desarrollador del navegador al inspeccionar un texto).
- **Sin scroll horizontal a 360px**: F12 → modo dispositivo.
- **Orden de los bloques de `styles.css`**: uno por sección, en el orden de la página, y cada media query justo debajo de la regla que modifica.
- **Comentarios en español** en HTML, CSS y JavaScript.
- **Navegación con Tab**: recorre todo en orden y se ve el contorno de foco.
- **El formulario**: los casos de "Cómo probar" en `CLAUDE.md`.
