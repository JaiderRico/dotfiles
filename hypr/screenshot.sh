#!/bin/bash
SAVE_DIR="$HOME/Pictures"
mkdir -p "$SAVE_DIR"
FILE="$SAVE_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

case $(echo -e "Región\nVentana\nPantalla completa" | rofi -dmenu -p "Captura" -no-custom -theme ~/.config/rofi/catppuccin-mocha.rasi -theme-str 'inputbar {enabled: false;}') in
  "Región")
    grim -g "$(slurp)" "$FILE" ;;
  "Ventana")
    grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILE" ;;
  "Pantalla completa")
    grim "$FILE" ;;
esac

wl-copy < "$FILE"
cliphist store < "$FILE"
