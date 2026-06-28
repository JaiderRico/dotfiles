#!/usr/bin/env bash
# Cliphist picker — muestra texto e imágenes en rofi con thumbnails grandes

CACHE_DIR="/tmp/cliphist-thumbs"
mkdir -p "$CACHE_DIR"
find "$CACHE_DIR" -type f -mmin +60 -delete 2>/dev/null

ENTRIES=""
while IFS=$'\t' read -r id content; do
    if [[ "$content" =~ binary\ data.*(png|jpg|jpeg) ]]; then
        THUMB="$CACHE_DIR/$id.png"
        if [ ! -f "$THUMB" ]; then
            DIMS=$(echo "$content" | grep -oP '\d+x\d+' | head -1)
            cliphist decode "$id" 2>/dev/null | magick - -resize 100x100 PNG:"$THUMB" 2>/dev/null
        else
            DIMS=$(magick identify -format "%wx%h" "$THUMB" 2>/dev/null)
        fi
        ICON="$THUMB"
        TEXT="$DIMS"
    else
        ICON="edit-paste"
        TEXT=$(echo "$content" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-50)
    fi
    ENTRIES+="$id  $TEXT\0icon\x1f$ICON\n"
done < <(cliphist list 2>/dev/null)

[ -z "$ENTRIES" ] && notify-send "Cliphist" "Historial vacío" && exit 0

SELECTED=$(echo -e "$ENTRIES" | rofi -dmenu -p "Historial" -theme-str 'inputbar{enabled:false;}listview{lines:8;spacing:4;}element-icon{size:100px;horizontal-align:0.5;}element-text{vertical-align:0.5;font:"Sans 10";}')
[ -z "$SELECTED" ] && exit 0

ID=$(echo "$SELECTED" | awk '{print $1}')

if cliphist decode "$ID" 2>/dev/null | wl-copy; then
    notify-send "Cliphist" "Copiado al portapapeles"
else
    notify-send -u critical "Cliphist" "Error al copiar"
fi
