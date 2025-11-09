#!/usr/bin/env bash
# Detecta documentos YAML grandes dentro de un rendered.yaml y muestra su "# Source:".
# Uso: ./detect_large_docs.sh [rendered.yaml] [threshold_bytes]
# Ej: ./detect_large_docs.sh rendered.yaml 3145728

set -euo pipefail

RENDERED_FILE="${1:-rendered.yaml}"
THRESHOLD="${2:-3145728}"  # 3 MiB por defecto
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

if [ ! -f "$RENDERED_FILE" ]; then
  echo "ERROR: archivo no encontrado: $RENDERED_FILE" >&2
  exit 2
fi

echo "Analizando: $RENDERED_FILE (umbral = $THRESHOLD bytes)"
echo

if command -v csplit >/dev/null 2>&1; then
  csplit -z -f "$TMPDIR/xx" "$RENDERED_FILE" '/^---$/' '{*}' >/dev/null 2>&1 || true
else
  awk -v outdir="$TMPDIR" 'BEGIN{doc=0; fname=sprintf("%s/xx%03d",outdir,doc); print "" > fname}
/^---$/ { doc++; fname=sprintf("%s/xx%03d",outdir,doc); next }
{ print >> fname }' "$RENDERED_FILE"
fi

shopt -s nullglob
files=("$TMPDIR"/xx*)
if [ "${#files[@]}" -eq 0 ]; then
  echo "No se detectaron documentos al dividir. Usando archivo completo como único documento."
  cp "$RENDERED_FILE" "$TMPDIR/xx000"
  files=("$TMPDIR"/xx000)
fi

echo
printf "%12s  %s\n" "bytes" "file"
declare -a lines
for f in "${files[@]}"; do
  sz=$(wc -c <"$f")
  lines+=("$sz:$f")
done

printf "%s\n" "${lines[@]}" | sort -t: -k1,1nr | head -n 20 | while IFS=: read -r sz f; do
  printf "%12d  %s\n" "$sz" "$f"
done

echo
echo "Documentos que exceden el umbral (${THRESHOLD} bytes):"
any=0
printf "%s\n" "${lines[@]}" | while IFS=: read -r sz f; do
  if [ "$sz" -ge "$THRESHOLD" ]; then
    any=1
    echo "-----------------------------"
    echo "Archivo: $f  (bytes: $sz)"
    echo "Origen (primer comentario '# Source:' si existe):"
    grep -m1 -n '^# Source:' "$f" || echo "  (no se encontró '# Source:')"
    echo
    echo "Primeras 200 líneas del documento:"
    echo "---------------------------------"
    head -n 200 "$f"
    echo
  fi
done

if [ "$any" -eq 0 ]; then
  echo "(ningún documento excede el umbral)"
fi

exit 0