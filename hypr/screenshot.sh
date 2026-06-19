#!/bin/bash
choice=$(printf "󰹑 Región\n󰍹 Pantalla completa\n󰖯 Ventana activa" | rofi -dmenu -p "📸 Captura" -theme-str 'inputbar { enabled: false; }')
FILE=~/Imágenes/screenshot-$(date +%Y%m%d-%H%M%S).png

case "$choice" in
    *Región)
        grim -g "$(slurp)" "$FILE" && wl-copy < "$FILE" ;;
    *"Pantalla completa")
        grim "$FILE" && wl-copy < "$FILE" ;;
    *"Ventana activa")
        hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | \
        grim -g - "$FILE" && wl-copy < "$FILE" ;;
esac
