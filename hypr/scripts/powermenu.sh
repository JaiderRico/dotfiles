#!/bin/bash
choice=$(printf "󰤄 Suspender\n󰍃 Cerrar sesión\n󰜉 Reiniciar\n󰐥 Apagar" | rofi -dmenu -p "Sistema" -no-custom -theme ~/.config/rofi/catppuccin-mocha.rasi -theme-str 'inputbar {enabled: false;}')
case "$choice" in
*Suspender) systemctl suspend ;;
*"Cerrar sesión") hyprctl dispatch exit ;;
*Reiniciar) systemctl reboot ;;
*Apagar) systemctl poweroff ;;
esac
