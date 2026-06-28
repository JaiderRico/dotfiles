#!/usr/bin/env bash
# Pomodoro timer — 25 min trabajo + 5 min descanso
# Cierra con Ctrl+C, notifica via swaync

WORK_MIN=25
BREAK_MIN=5
PID_FILE="/tmp/pomodoro.pid"
STATE_FILE="/tmp/pomodoro-state"

show_help() {
    cat <<EOF
Uso: pomodoro.sh {start|stop|status|toggle}

  start    Inicia ciclo de trabajo ($WORK_MIN min)
  stop     Detiene el temporizador
  status   Muestra tiempo restante y estado
  toggle   Cambia entre trabajo/descanso manualmente
EOF
}

notify() {
    notify-send -u critical "$1" "$2"
}

timer_loop() {
    local label="$1" minutes="$2"
    local seconds=$((minutes * 60))
    while [ $seconds -gt 0 ]; do
        echo "$label|$seconds" > "$STATE_FILE"
        sleep 1
        ((seconds--))
    done
    echo "done|0" > "$STATE_FILE"
    case "$label" in
        work)
            notify "Pomodoro" "¡Tiempo de descanso! ($BREAK_MIN min)"
            timer_loop "break" "$BREAK_MIN"
            ;;
        break)
            notify "Pomodoro" "¡Tiempo de trabajo! ($WORK_MIN min)"
            timer_loop "work" "$WORK_MIN"
            ;;
    esac
}

case "${1:-}" in
    start)
        echo $$ > "$PID_FILE"
        timer_loop "work" "$WORK_MIN"
        ;;
    stop)
        [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE" "$STATE_FILE"
        notify "Pomodoro" "Temporizador detenido"
        ;;
    status)
        if [ -f "$STATE_FILE" ]; then
            IFS='|' read -r label seconds < "$STATE_FILE"
            min=$((seconds / 60))
            sec=$((seconds % 60))
            icon="󰔡"
            [ "$label" = "break" ] && icon="󰅶"
            echo "$icon ${label^^} ${min}:$(printf '%02d' $sec)"
        else
            echo "󰅥 Inactivo"
        fi
        ;;
    toggle)
        [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null
        sleep 0.5
        bash "$0" start &
        ;;
    *)
        show_help
        ;;
esac
