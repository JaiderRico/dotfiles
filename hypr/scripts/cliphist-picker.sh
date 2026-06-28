#!/usr/bin/env bash
# Cliphist picker — muestra texto e imágenes del historial
# Texto → copia directa
# Imagen → previsualiza en eog, copia al cerrar

ENTRY=$(cliphist list | rofi -dmenu -p "Historial" -theme-str 'inputbar {enabled: false;}')
[ -z "$ENTRY" ] && exit 1

ID=$(echo "$ENTRY" | cut -d'	' -f1)
TYPE=$(echo "$ENTRY" | grep -oP '\[\[ binary data \K(\w+)')

if [ "$TYPE" = "png" ] || [ "$TYPE" = "jpg" ] || [ "$TYPE" = "jpeg" ]; then
    TMPFILE=$(mktemp /tmp/cliphist-preview-XXXXXX.png)
    cliphist decode "$ID" > "$TMPFILE"
    eog "$TMPFILE" &
    EOG_PID=$!
    wait $EOG_PID
    wl-copy < "$TMPFILE"
    notify-send "Cliphist" "Imagen copiada al portapapeles"
    rm "$TMPFILE"
else
    cliphist decode "$ID" | wl-copy
    notify-send "Cliphist" "Texto copiado al portapapeles"
fi
