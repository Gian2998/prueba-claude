#!/usr/bin/env bash
# Comprueba las reglas de CLAUDE.md que se pueden verificar leyendo los archivos.
# Uso (desde la raíz del proyecto): bash .claude/skills/verificar-cambios/scripts/check.sh
# Termina con código 0 si todo está bien y con 1 si alguna verificación falla.
# El detalle de cada verificación está en references/reference.md, con el mismo número.

# Va a la raíz del proyecto (cuatro carpetas arriba de este script:
# scripts → verificar-cambios → skills → .claude → raíz)
cd "$(dirname "$0")/../../../.." || exit 2

CSS=styles.css
HTML=index.html
JS_ARCHIVOS=$(ls ./*.js 2>/dev/null | sed 's|^\./||')

fallas=0
ok()    { printf 'OK     %s\n' "$1"; }
falla() { printf 'FALLA  %s\n' "$1"; fallas=$((fallas + 1)); }
# Muestra los detalles de una falla con sangría
detalle() { sed 's/^/         /'; }
# Lee un archivo sin los \r que agrega Windows al final de cada línea
leer() { tr -d '\r' < "$1"; }

# Imprime el contenido de un bloque de tema del CSS (sin la llave de apertura ni la de cierre)
bloque_tema() {
  leer "$CSS" | awk -v inicio="$1" '
    index($0, inicio) == 1 { dentro = 1; next }
    dentro && /^\}/ { exit }
    dentro { print }
  '
}
# Lista los nombres de variables (--algo) definidas en un texto
variables() { grep -oE -- '--[a-zA-Z0-9-]+[[:space:]]*:' | sed -E 's/[[:space:]]*:$//' | sort -u; }

for archivo in "$CSS" "$HTML"; do
  [ -f "$archivo" ] || { echo "No se encontró $archivo: ¿estás en la raíz del proyecto?"; exit 2; }
done

# ---------------------------------------------------------------------------
# 1. Colores fijos solo dentro de los bloques de tema
# ---------------------------------------------------------------------------
fuera=$(
  {
    leer "$CSS" | awk -v f="$CSS" '
      /^(:root|\[data-theme="dark"\])[[:space:]]*\{/ { tema = 1; next }
      tema && /^\}/ { tema = 0; next }
      !tema && /#[0-9a-fA-F]{3,8}([^0-9a-zA-Z_-]|$)|(rgba?|hsla?)\(/ { print f ":" NR ": " $0 }
    '
    leer "$HTML" | grep -nE '#[0-9a-fA-F]{3,8}([^0-9a-zA-Z_-]|$)|(rgba?|hsla?)\(' | sed "s|^|$HTML:|"
  }
)
if [ -z "$fuera" ]; then
  ok "1. Los colores fijos están solo en :root y [data-theme=\"dark\"]"
else
  falla "1. Hay colores fijos fuera de los bloques de tema (usá var(--…)):"
  echo "$fuera" | detalle
fi

# ---------------------------------------------------------------------------
# 2. Las mismas variables en los dos temas
# ---------------------------------------------------------------------------
claro=$(bloque_tema ':root' | variables)
oscuro=$(bloque_tema '[data-theme="dark"]' | variables)
solo_claro=$(comm -23 <(echo "$claro") <(echo "$oscuro"))
solo_oscuro=$(comm -13 <(echo "$claro") <(echo "$oscuro"))
if [ -z "$claro" ] || [ -z "$oscuro" ]; then
  falla "2. No se encontró el bloque :root o el bloque [data-theme=\"dark\"] en $CSS"
elif [ -z "$solo_claro$solo_oscuro" ]; then
  ok "2. Los dos temas definen las mismas $(echo "$claro" | wc -l | tr -d ' ') variables"
else
  falla "2. Los temas no definen las mismas variables:"
  [ -n "$solo_claro" ] && echo "$solo_claro" | sed 's/^/falta en el tema oscuro: /' | detalle
  [ -n "$solo_oscuro" ] && echo "$solo_oscuro" | sed 's/^/falta en el tema claro: /' | detalle
fi

# ---------------------------------------------------------------------------
# 3. Cada tema declara su color-scheme
# ---------------------------------------------------------------------------
sin_esquema=""
bloque_tema ':root' | grep -q 'color-scheme:[[:space:]]*light' || sin_esquema="$sin_esquema :root"
bloque_tema '[data-theme="dark"]' | grep -q 'color-scheme:[[:space:]]*dark' || sin_esquema="$sin_esquema [data-theme=\"dark\"]"
if [ -z "$sin_esquema" ]; then
  ok "3. Los dos temas declaran su color-scheme"
else
  falla "3. Falta color-scheme en:$sin_esquema"
fi

# ---------------------------------------------------------------------------
# 4. Toda variable usada con var(--…) está definida
# ---------------------------------------------------------------------------
usadas=$(leer "$CSS" | grep -oE 'var\(--[a-zA-Z0-9-]+' | sed 's/^var(//' | sort -u)
definidas=$(leer "$CSS" | variables)
sin_definir=$(comm -23 <(echo "$usadas") <(echo "$definidas"))
if [ -z "$sin_definir" ]; then
  ok "4. Todas las variables usadas con var(--…) están definidas"
else
  falla "4. Se usan variables que no están definidas:"
  echo "$sin_definir" | detalle
fi

# ---------------------------------------------------------------------------
# 5. El JavaScript no cambia estilos directamente
# ---------------------------------------------------------------------------
estilos_js=""
for f in $JS_ARCHIVOS; do
  r=$(leer "$f" | grep -nE '\.style\b|setProperty\(' | sed "s|^|$f:|")
  [ -n "$r" ] && estilos_js="$estilos_js$r"$'\n'
done
r=$(leer "$HTML" | grep -nE '\.style\b|setProperty\(|style="' | sed "s|^|$HTML:|")
[ -n "$r" ] && estilos_js="$estilos_js$r"$'\n'
if [ -z "$estilos_js" ]; then
  ok "5. El JavaScript no cambia estilos directamente (y no hay atributos style=\"…\")"
else
  falla "5. Hay estilos cambiados desde JavaScript o escritos en el HTML (cambiá un atributo y dejá los colores al CSS):"
  printf '%s' "$estilos_js" | detalle
fi

# ---------------------------------------------------------------------------
# 6. Todo acceso a localStorage está dentro de try { … }
# ---------------------------------------------------------------------------
# Recorre cada línea letra por letra y cuenta las llaves para saber
# si el localStorage está dentro de las llaves de un "try".
sin_try=$(
  for f in "$HTML" $JS_ARCHIVOS; do
    leer "$f" | awk -v f="$f" '
      {
        linea = $0
        sub(/\/\/.*/, "", linea)          # ignora los comentarios de una línea
        n = length(linea)
        for (i = 1; i <= n; i++) {
          antes = (i > 1) ? substr(linea, i - 1, 1) : " "
          despues = substr(linea, i + 3, 1)
          if (substr(linea, i, 3) == "try" && antes !~ /[A-Za-z0-9_$]/ && despues !~ /[A-Za-z0-9_$]/) esperando = 1
          c = substr(linea, i, 1)
          if (c == "{") { prof++; if (esperando) { pila[++tope] = prof; esperando = 0 } }
          else if (c == "}") { if (tope > 0 && pila[tope] == prof) tope--; prof-- }
          if (substr(linea, i, 12) == "localStorage" && tope == 0) {
            gsub(/^[[:space:]]+/, "", $0)
            print f ":" NR ": " $0
            break
          }
        }
      }
    '
  done
)
if [ -z "$sin_try" ]; then
  ok "6. Todos los accesos a localStorage están dentro de try/catch"
else
  falla "6. Hay accesos a localStorage fuera de un try/catch:"
  echo "$sin_try" | detalle
fi

# ---------------------------------------------------------------------------
# 7. Solo se usan las media queries permitidas
# ---------------------------------------------------------------------------
otras_media=$(leer "$CSS" | grep -nE '@media' | grep -vE '@media \((min-width: 768px|max-width: 480px)\)' | sed "s|^|$CSS:|")
if [ -z "$otras_media" ]; then
  ok "7. Solo hay media queries de min-width: 768px y max-width: 480px"
else
  falla "7. Hay media queries distintas de las permitidas:"
  echo "$otras_media" | detalle
fi

# ---------------------------------------------------------------------------
# 8. Sin librerías externas ni paso de compilación
# ---------------------------------------------------------------------------
externas=$(leer "$HTML" | grep -nE '<(script|link)[^>]+(src|href)="(https?:)?//' | sed "s|^|$HTML:|")
[ -f package.json ] && externas="$externas"$'\n'"package.json existe"
externas=$(echo "$externas" | sed '/^$/d')
if [ -z "$externas" ]; then
  ok "8. No hay librerías externas ni package.json"
else
  falla "8. Hay librerías externas o archivos de compilación:"
  echo "$externas" | detalle
fi

# ---------------------------------------------------------------------------
# 9. El script del <head> aplica el tema y usa la misma clave que script.js
# ---------------------------------------------------------------------------
claves() { grep -oE 'localStorage\.(getItem|setItem|removeItem)\("[^"]*"' | sed -E 's/.*\("//; s/"$//' | sort -u; }
cabeza=$(leer "$HTML" | awk '/<\/head>/ { exit } { print }')
claves_head=$(echo "$cabeza" | claves)
claves_js=$( [ -f script.js ] && leer script.js | claves )
if ! echo "$cabeza" | grep -q 'data-theme' || [ -z "$claves_head" ]; then
  falla "9. El <head> no tiene el script que lee el tema de localStorage y pone data-theme"
elif [ "$claves_head" != "$claves_js" ]; then
  falla "9. La clave de localStorage no es la misma en el <head> y en script.js:"
  { echo "<head>: $(echo $claves_head)"; echo "script.js: $(echo $claves_js)"; } | detalle
else
  ok "9. El <head> aplica el tema y usa la misma clave que script.js (\"$(echo $claves_head)\")"
fi

# ---------------------------------------------------------------------------
# 10. Cada .js está enlazado al final del <body>
# ---------------------------------------------------------------------------
linea_footer=$(leer "$HTML" | grep -nE '</footer>' | tail -1 | cut -d: -f1)
linea_body=$(leer "$HTML" | grep -nE '</body>' | tail -1 | cut -d: -f1)
mal_enlazados=""
for f in $JS_ARCHIVOS; do
  l=$(leer "$HTML" | grep -nF "<script src=\"$f\"" | head -1 | cut -d: -f1)
  if [ -z "$l" ]; then
    mal_enlazados="$mal_enlazados$f no está enlazado en $HTML"$'\n'
  elif [ -n "$linea_footer" ] && [ -n "$linea_body" ] && { [ "$l" -lt "$linea_footer" ] || [ "$l" -gt "$linea_body" ]; }; then
    mal_enlazados="$mal_enlazados$f está enlazado en la línea $l, fuera del final del <body>"$'\n'
  fi
done
if [ -z "$mal_enlazados" ]; then
  ok "10. Cada .js está enlazado al final del <body>"
else
  falla "10. Hay archivos .js mal enlazados:"
  printf '%s' "$mal_enlazados" | detalle
fi

# ---------------------------------------------------------------------------
# 11. Cada elemento interactivo tiene :focus-visible y 44px de alto
# ---------------------------------------------------------------------------
tmp=$(mktemp -d)
# Reglas del CSS, una por línea: "selectores<TAB>declaraciones"
leer "$CSS" | awk '
  BEGIN { RS = "}" }
  {
    n = split($0, partes, "{")
    if (n < 2) next
    sel = partes[n - 1]
    gsub(/\/\*([^*]|\*+[^*\/])*\*+\//, "", sel)   # saca los comentarios
    gsub(/[[:space:]]+/, " ", sel)
    dec = partes[n]
    gsub(/[[:space:]]+/, " ", dec)
    print sel "\t" dec
  }
' > "$tmp/reglas"
# Elementos interactivos del HTML, uno por línea (las etiquetas de varias líneas se juntan)
leer "$HTML" | tr '\n' ' ' | grep -oE '<(a|button|input|textarea|select)[[:space:]][^>]*>' \
  | sed -E 's/[[:space:]]+/ /g' > "$tmp/elementos"
faltan=$(awk -F'\t' '
  # Una parte de selector como "button.boton-enviar" coincide con el elemento
  # si cada pedazo (etiqueta, #id, .clase) coincide.
  function coincide(comp,    t, toks, n, i, k) {
    if (comp == "") return 0
    t = comp; gsub(/[#.]/, " &", t)
    n = split(t, toks, " ")
    for (i = 1; i <= n; i++) {
      k = toks[i]
      if (substr(k, 1, 1) == "#") { if (k != id) return 0 }
      else if (substr(k, 1, 1) == ".") { if (index(" " clases " ", " " substr(k, 2) " ") == 0) return 0 }
      else if (k != etiqueta) return 0
    }
    return 1
  }
  function cubierto(lista, total,    i) {
    for (i = 1; i <= total; i++) if (coincide(lista[i])) return 1
    return 0
  }
  # Primer archivo: reglas del CSS
  FNR == NR {
    alto = ($2 ~ /height:[[:space:]]*(2\.75rem|44px)/)
    nsel = split($1, sels, ",")
    for (s = 1; s <= nsel; s++) {
      sel = sels[s]; gsub(/^ +| +$/, "", sel)
      foco = (sel ~ /:focus-visible$/)
      sub(/:focus-visible$/, "", sel)
      if (sel ~ /:/) continue               # ignora :hover y otros estados
      m = split(sel, comps, " ")
      if (foco) conFoco[++nf] = comps[m]
      else if (alto) conAlto[++na] = comps[m]
    }
    next
  }
  # Segundo archivo: elementos del HTML
  {
    match($0, /^<[a-z]+/); etiqueta = substr($0, 2, RLENGTH - 1)
    id = ""; if (match($0, /id="[^"]+"/)) id = "#" substr($0, RSTART + 4, RLENGTH - 5)
    clases = ""; if (match($0, /class="[^"]+"/)) clases = substr($0, RSTART + 7, RLENGTH - 8)
    nombre = $0; if (length(nombre) > 70) nombre = substr(nombre, 1, 67) "..."
    if (!cubierto(conFoco, nf)) print "sin :focus-visible: " nombre
    if (!cubierto(conAlto, na)) print "sin 44px de alto: " nombre
  }
' "$tmp/reglas" "$tmp/elementos" | sort -u)
cantidad=$(wc -l < "$tmp/elementos" | tr -d ' ')
rm -rf "$tmp"
if [ -z "$faltan" ]; then
  ok "11. Los $cantidad elementos interactivos tienen :focus-visible y 44px de alto"
else
  falla "11. Hay elementos interactivos sin :focus-visible o sin 44px de alto (min-height: 2.75rem):"
  echo "$faltan" | detalle
fi

# ---------------------------------------------------------------------------
# 12. El JavaScript no tiene errores de sintaxis
# ---------------------------------------------------------------------------
if command -v node > /dev/null 2>&1; then
  errores_js=""
  for f in $JS_ARCHIVOS; do
    # node muestra mucho texto; nos quedamos con el número de línea y el tipo de error
    r=$(node --check "$f" 2>&1) || {
      linea=$(echo "$r" | head -1 | grep -oE '[0-9]+$')
      error=$(echo "$r" | grep -m1 -E '^[A-Za-z]*Error')
      errores_js="$errores_js$f:$linea: $error"$'\n'
    }
  done
  if [ -z "$errores_js" ]; then
    ok "12. Los archivos .js no tienen errores de sintaxis"
  else
    falla "12. Hay errores de sintaxis en JavaScript:"
    printf '%s' "$errores_js" | detalle
  fi
else
  echo "--     12. Se saltó la revisión de sintaxis: node no está instalado"
fi

# ---------------------------------------------------------------------------
echo
if [ "$fallas" -eq 0 ]; then
  echo "Todo bien. Falta revisar a mano lo que figura al final de references/reference.md."
  exit 0
else
  echo "$fallas verificación(es) fallaron. El detalle de cada una está en references/reference.md."
  exit 1
fi
