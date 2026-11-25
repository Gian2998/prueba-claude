# Mi página

Página personal estática: HTML, CSS y JavaScript sin librerías ni paso de compilación. Se ve abriendo `index.html` en el navegador.

## Estructura

- El script del `<head>` de `index.html` aplica el tema antes de pintar la página. Dejalo en el `<head>` para que no parpadee.
- `styles.css`: primero las variables de los dos temas y el reinicio; después un bloque por sección, en el orden de la página. Cada media query va justo debajo de la regla que modifica.
- Cada funcionalidad de JavaScript va en su propio archivo `.js`, enlazado al final del `<body>`: `script.js` (tema), `formulario.js` (contacto).
- La clave `tema` de `localStorage` la usan el script del `<head>` y `script.js`. Si la cambiás, cambiala en los dos.

## Colores y temas

- Cada color es una variable con el mismo nombre en `:root` (claro) y en `[data-theme="dark"]` (oscuro). Las reglas usan solo `var(--…)`.
- El JavaScript cambia atributos (`data-theme`, `aria-invalid`) y el CSS decide los colores según esos atributos.
- Cada tema declara su `color-scheme`.
- El texto tiene un contraste de al menos 4.5:1 contra su fondo, en los dos temas.
- Cada acceso a `localStorage` va dentro de `try/catch`.

## Celular y teclado

- Los estilos base son para celular. Las pantallas grandes se agregan con `@media (min-width: 768px)` y los ajustes para 480px o menos con `@media (max-width: 480px)`.
- A 360px de ancho no hay scroll horizontal.
- Cada elemento interactivo mide al menos 44px de alto (`min-height: 2.75rem`) y tiene un estilo `:focus-visible`.

## Comentarios

- Los comentarios del código van en español, en HTML, CSS y JavaScript.

## Cómo probar

No hay tests automáticos. Al terminar un cambio, seguí la skill `verificar-cambios`: corre `check.sh` y lista lo que hay que revisar a mano en el navegador.
