#!/bin/bash
SCRIPT_PID_FILE="/tmp/usb-monitor.pid"
echo $$ > "$SCRIPT_PID_FILE"

STATE_DIR="/tmp/usb-monitor-state"
mkdir -p "$STATE_DIR"

notify() {
    local now=$(date +%s)
    local last=$(cat "$STATE_DIR/last_notify" 2>/dev/null || echo 0)
    if [ $((now - last)) -gt 3 ]; then
        notify-send -t 3000 "$1"
        canberra-gtk-play --file "$HOME/Descargas/usb.wav" 2>/dev/null || true
        echo "$now" > "$STATE_DIR/last_notify"
    fi
}

udevadm monitor --udev --subsystem-match=usb 2>/dev/null | \
    grep --line-buffered "^UDEV" | \
    while read -r line; do
        action=$(echo "$line" | awk '{print $3}')
        devpath=$(echo "$line" | awk '{print $4}')

        [ "$action" != "add" ] && [ "$action" != "remove" ] && continue

        parent=$(echo "$devpath" | grep -oP 'usb[0-9]+/[0-9]+-[0-9]+' | head -1)
        [ -z "$parent" ] && continue

        state_file="$STATE_DIR/$(echo "$parent" | tr '/' '_')"

        if [ "$action" = "add" ]; then
            if [ ! -f "$state_file" ]; then
                touch "$state_file"
                notify "🔌 USB conectado"
            fi
        elif [ "$action" = "remove" ]; then
            if [ -f "$state_file" ]; then
                rm -f "$state_file"
                notify "🔌 USB desconectado"
            fi
        fi
    done
