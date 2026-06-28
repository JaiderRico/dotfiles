#!/usr/bin/env bash
# Wofi clipboard picker — texto + indicador de imágenes

CACHE_DIR="/tmp/cliphist-wofi"
mkdir -p "$CACHE_DIR"
find "$CACHE_DIR" -type f -mmin +120 -delete 2>/dev/null

ENTRIES=""
while IFS=$'\t' read -r id content; do
    if [[ "$content" =~ binary\ data.*(png|jpg|jpeg|bmp|gif) ]]; then
        DIMS=$(echo "$content" | grep -oP '\d+x\d+' | head -1 || echo "??x??")
        TEXT="  $DIMS"
    else
        TEXT=$(echo "$content" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-80)
        [ -z "$TEXT" ] && TEXT="(empty)"
    fi
    ENTRIES+="$id\t$TEXT\n"
done < <(cliphist list 2>/dev/null)

[ -z "$ENTRIES" ] && notify-send "Cliphist" "Historial vacío" && exit 0

SELECTED=$(echo -e "$ENTRIES" | wofi --dmenu -p "Historial" --cache-file /dev/null --prompt "cliphist")
[ -z "$SELECTED" ] && exit 0

ID=$(echo "$SELECTED" | awk '{print $1}')

if cliphist decode "$ID" 2>/dev/null | wl-copy; then
    notify-send "Cliphist" "Copiado al portapapeles"
else
    notify-send -u critical "Cliphist" "Error al copiar"
fi
