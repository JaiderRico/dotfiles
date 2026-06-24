#!/bin/bash
case "$choice" in
    *Suspender) systemctl suspend ;;
    *"Cerrar sesión") hyprctl dispatch exit ;;
    *Reiniciar) systemctl reboot ;;
    *Apagar) systemctl poweroff ;;
esac