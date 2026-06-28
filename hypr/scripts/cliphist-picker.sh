#!/usr/bin/env bash
# Cliphist picker — muestra texto e imágenes en rofi con thumbnails

CACHE_DIR="/tmp/cliphist-thumbs"
mkdir -p "$CACHE_DIR"

# Clean thumbs older than 1h
find "$CACHE_DIR" -type f -mmin +60 -delete 2>/dev/null

ENTRIES=""
while IFS=$'\t' read -r id content; do
    if [[ "$content" =~ binary\ data.*(png|jpg) ]]; then
        THUMB="$CACHE_DIR/$id.png"
        [ ! -f "$THUMB" ] && cliphist decode "$id" 2>/dev/null | magick - -resize 32x32 PNG:"$THUMB" 2>/dev/null
        ICON="$THUMB"
        TEXT="[img] $id"
    else
        ICON="edit-paste"
        TEXT=$(echo "$content" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-60)
    fi
    ENTRIES+="$id  $TEXT\0icon\x1f$ICON\n"
done < <(cliphist list 2>/dev/null)

[ -z "$ENTRIES" ] && notify-send "Cliphist" "Historial vacío" && exit 0

SELECTED=$(echo -e "$ENTRIES" | rofi -dmenu -p "Historial" -theme-str 'inputbar{enabled:false;}listview{lines:10;}')
[ -z "$SELECTED" ] && exit 0

ID=$(echo "$SELECTED" | awk '{print $1}')

if cliphist decode "$ID" 2>/dev/null | wl-copy; then
    notify-send "Cliphist" "Copiado al portapapeles"
else
    notify-send -u critical "Cliphist" "Error al copiar"
fi
