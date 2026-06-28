#!/usr/bin/env bash
# Idle check — notifica si el sistema lleva mucho tiempo encendido

UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)

if [ "$UPTIME_HOURS" -gt 12 ]; then
    notify-send -u critical "Sistema activo" "Llevas $UPTIME_HOURS horas sin reiniciar"
elif [ "$UPTIME_HOURS" -gt 8 ]; then
    notify-send -u normal "Sistema activo" "Llevas $UPTIME_HOURS horas encendido"
fi
