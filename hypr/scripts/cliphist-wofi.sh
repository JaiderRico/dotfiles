#!/usr/bin/env bash
# Wofi clipboard picker — rápido, una sola instancia

pgrep -u "$UID" -x wofi &>/dev/null && exit 0

ENTRIES=$(cliphist list 2>/dev/null | head -50 | awk '
{
    id = $1
    $1 = ""
    sub(/^[ \t]+/, "")
    if (match($0, /binary data.* ([0-9]+)x([0-9]+)/, a)) {
        text = "\357\200\276  " a[1] "x" a[2]
    } else {
        gsub(/[\n\t]+/, " ", $0)
        text = substr($0, 1, 80)
        if (text == "") text = "(vacio)"
    }
    print id "\t" text
}')

[ -z "$ENTRIES" ] && notify-send "Cliphist" "Historial vacio" && exit 0

SELECTED=$(echo "$ENTRIES" | wofi --dmenu -p "Historial" --cache-file /dev/null --prompt "cliphist" --width 520)
[ -z "$SELECTED" ] && exit 0

ID=$(echo "$SELECTED" | awk '{print $1}')

if cliphist decode "$ID" 2>/dev/null | wl-copy; then
    notify-send "Cliphist" "Copiado al portapapeles"
else
    notify-send -u critical "Cliphist" "Error al copiar"
fi
