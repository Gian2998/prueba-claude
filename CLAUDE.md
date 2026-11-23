# Mi página

Página web personal estática hecha con HTML, CSS y JavaScript puro, sin frameworks, dependencias ni paso de compilación. Para verla, se abre `index.html` en el navegador.

## Archivos

- `index.html`: estructura y contenido.
  - Encabezado con el título y el botón de tema (`#tema-toggle`).
  - Sección de presentación (`.presentacion`).
  - Sección "Mis proyectos" (`.proyectos`), con tarjetas `.tarjeta` dentro de `.proyectos-grid`.
  - Pie de página.
  - Incluye un script corto en el `<head>` que aplica el tema antes de pintar la página. Tiene que quedar en el `<head>` para que no parpadee al cargar.
- `styles.css`: todos los estilos, ordenados en bloques.
  - Variables del tema claro, variables del tema oscuro y reinicio básico.
  - Estilos de cada sección, en el orden en que aparecen en la página.
  - No hay un bloque de media queries al final: cada media query va justo después de los estilos que modifica.
- `script.js`: solo maneja el botón de tema.
  - Alterna `data-theme` en `<html>`.
  - Actualiza el ícono 🌙/☀️ y el `aria-label`.
  - Guarda la elección en `localStorage` con la clave `tema`.

## Temas claro y oscuro

- Los colores se definen **solo** como variables CSS:
  - En `:root` para el tema claro.
  - En `[data-theme="dark"]` para el tema oscuro, con los mismos nombres.
- En las reglas, nunca uses colores fijos: usá siempre `var(--…)`.
- Si necesitás un color nuevo, agregá la variable en los dos temas.
- El JavaScript nunca cambia colores directamente: solo cambia el atributo `data-theme`.
- Cada tema declara su `color-scheme`, para que los controles nativos del navegador acompañen el tema.
- El texto tiene que tener un contraste de al menos 4.5:1 en los dos temas.
- Todo acceso a `localStorage` va dentro de `try/catch`.

## Celular (responsive)

- Todo tiene que funcionar y verse bien en celular, sin scroll horizontal.
- Se diseña primero para celular:
  - Los estilos base son para pantallas chicas.
  - Las pantallas grandes se agregan con `@media (min-width: 768px)`.
  - Hay ajustes extra para pantallas de 480px o menos, con `@media (max-width: 480px)`.
- Las tarjetas van en una columna en celular y en 3 columnas desde 768px.
- Los elementos interactivos necesitan:
  - Un tamaño cómodo para tocar (unos 44px).
  - Un estilo `:focus-visible`, para quien navega con teclado.

## Comentarios

- Los comentarios del código se escriben en español, en los tres archivos (HTML, CSS y JavaScript).

## Cómo probar

No hay tests automáticos. Hay que abrir `index.html` y revisar:

- Los dos temas: alternar con el botón y recargar para comprobar que recuerda la elección.
- El modo celular de las herramientas de desarrollador (F12).
- La navegación con Tab.
