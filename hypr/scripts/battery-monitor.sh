#!/bin/bash
LOW=20
CRITICAL=10
BAT="/sys/class/power_supply/BAT0"
AC="/sys/class/power_supply/AC"

# Lectura directa desde sysfs (más confiable que upower)
get_pct() { cat "$BAT/capacity" 2>/dev/null || echo 0; }
get_ac() { cat "$AC/online" 2>/dev/null || echo 0; }

# Estado anterior para detectar cambios sin depender solo de udev
last_ac="$(get_ac)"

while true; do
    pct=$(get_pct)
    ac=$(get_ac)

    if [ "$ac" != "$last_ac" ]; then
        if [ "$ac" = "1" ]; then
            notify-send -t 3000 "🔌 Cargando" "Batería al ${pct}%"
        else
            notify-send -t 3000 "🔋 Desconectado" "Batería al ${pct}%"
        fi
        canberra-gtk-play --file "$HOME/Descargas/cargar.wav" 2>/dev/null || true
        last_ac="$ac"
    fi

    # Alerta batería baja
    if [ "$ac" = "0" ]; then
        if [ "$pct" -le "$CRITICAL" ]; then
            notify-send -u critical -t 5000 "⚠️ Batería crítica" "${pct}% — Suspenderé pronto"
        elif [ "$pct" -le "$LOW" ]; then
            notify-send -u normal -t 4000 "🔋 Batería baja" "${pct}% — Conecta el cargador"
        fi
    fi

    sleep 5
done
