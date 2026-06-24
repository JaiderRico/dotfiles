#!/bin/bash

# Configura el porcentaje mínimo para la alerta
LOW_BATTERY=20

# Obtiene el estado actual de la batería (puedes verificar si tu batería se llama BAT0 o BAT1)
BATTERY_PATH=$(ls /sys/class/power_supply/ | grep -E '^BAT[0-9]')
PERCENTAGE=$(cat /sys/class/power_supply/$BATTERY_PATH/capacity)
STATUS=$(cat /sys/class/power_supply/$BATTERY_PATH/status)

# Si la batería está bajando (Discharging) y es menor o igual al límite, manda la alerta
if [ "$STATUS" = "Discharging" ] && [ "$PERCENTAGE" -le "$LOW_BATTERY" ]; then
    notify-send -u critical -i battery-low "Batería Baja" "El equipo está al $PERCENTAGE%. Conecta el cargador."
fi