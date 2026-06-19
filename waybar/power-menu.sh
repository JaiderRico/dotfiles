#!/bin/bash
choice=$(printf "󰤄 Suspender\n󰍃 Cerrar sesión\n󰜉 Reiniciar\n󰐥 Apagar" | rofi -dmenu -p "Sistema" -no-custom)
case "$choice" in
    *Suspender) systemctl suspend ;;
    *"Cerrar sesión") hyprctl dispatch exit ;;
    *Reiniciar) systemctl reboot ;;
    *Apagar) systemctl poweroff ;;
esac