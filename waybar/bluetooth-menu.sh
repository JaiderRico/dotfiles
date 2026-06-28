#!/usr/bin/env bash
# Bluetooth menu con wofi — rápido, conectar/desconectar/olvidar

pgrep -u "$UID" -x wofi &>/dev/null && exit 0

! command -v bluetoothctl &>/dev/null && notify-send -u critical "Bluetooth" "bluetoothctl no instalado" && exit 1

powered=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

build_menu() {
    local menu=""
    if [ "$powered" = "yes" ]; then
        menu+="󰂲 Apagar Bluetooth\n"
    else
        menu+="󰂯 Encender Bluetooth\n"
    fi

    if [ "$powered" = "yes" ]; then
        local paired=$(bluetoothctl devices Paired 2>/dev/null | sed 's/^Device //')
        if [ -n "$paired" ]; then
            menu+="---\n"
            local connected=$(bluetoothctl devices Connected 2>/dev/null | sed 's/^Device //')
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                mac=$(echo "$line" | awk '{print $1}')
                name=$(echo "$line" | cut -d' ' -f2-)
                if echo "$connected" | grep -q "$mac"; then
                    menu+="󰄲 $name\n"
                else
                    menu+="󰂱 $name\n"
                fi
            done <<< "$paired"
        fi
        menu+="---\n󰂰 Buscar dispositivos"
    fi

    echo -e "$menu"
}

chosen=$(build_menu | wofi --dmenu -p "Bluetooth" --width 520 --cache-file /dev/null)
[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰂲 Apagar Bluetooth")
        bluetoothctl power off 2>/dev/null
        notify-send "Bluetooth" "Apagado"
        exit 0
        ;;
    "󰂯 Encender Bluetooth")
        bluetoothctl power on 2>/dev/null
        notify-send "Bluetooth" "Encendido"
        exit 0
        ;;
    "󰂰 Buscar dispositivos")
        notify-send "Bluetooth" "Buscando dispositivos..."
        bluetoothctl scan on &>/dev/null &
        SCAN_PID=$!
        sleep 3
        kill "$SCAN_PID" 2>/dev/null
        bluetoothctl scan off 2>/dev/null

        new=$(bluetoothctl devices 2>/dev/null | sed 's/^Device //' | sort)
        paired=$(bluetoothctl devices Paired 2>/dev/null | sed 's/^Device //' | sort)
        unparied=$(comm -23 <(echo "$new") <(echo "$paired") 2>/dev/null)

        if [ -z "$unparied" ]; then
            notify-send "Bluetooth" "No se encontraron nuevos dispositivos"
            exit 0
        fi

        scan_menu=""
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            name=$(echo "$line" | cut -d' ' -f2-)
            scan_menu+="󰂰 $name\n"
        done <<< "$unparied"

        chosen_device=$(echo -e "$scan_menu" | wofi --dmenu -p "Bluetooth" --width 520 --cache-file /dev/null)
        if [ -n "$chosen_device" ]; then
            name=$(echo "$chosen_device" | sed 's/^[^ ]* //')
            mac=$(echo "$unparied" | grep -F "$name" | awk '{print $1}' | head -1)
            if [ -n "$mac" ]; then
                bluetoothctl pair "$mac" 2>/dev/null
                sleep 1
                bluetoothctl trust "$mac" 2>/dev/null
                bluetoothctl connect "$mac" 2>/dev/null
                notify-send "Bluetooth" "Conectado a $name"
            fi
        fi
        exit 0
        ;;
    *)
        name=$(echo "$chosen" | sed 's/^[^ ]* //; s/ *$//')
        mac=$(bluetoothctl devices Paired 2>/dev/null | grep -F " $name" | awk '{print $2}' | head -1)
        [ -z "$mac" ] && mac=$(bluetoothctl devices 2>/dev/null | grep -F " $name" | awk '{print $2}' | head -1)

        if [ -n "$mac" ]; then
            if bluetoothctl devices Connected 2>/dev/null | grep -q "$mac"; then
                action=$(echo -e "󰂲 Desconectar\n󰂎 Olvidar dispositivo" | wofi --dmenu -p "$name" --width 400 --cache-file /dev/null)
                case "$action" in
                    "󰂲 Desconectar")
                        bluetoothctl disconnect "$mac" 2>/dev/null
                        notify-send "Bluetooth" "Desconectado de $name"
                        ;;
                    "󰂎 Olvidar dispositivo")
                        bluetoothctl remove "$mac" 2>/dev/null
                        notify-send "Bluetooth" "$name eliminado"
                        ;;
                esac
            else
                action=$(echo -e "󰂱 Conectar\n󰂎 Olvidar dispositivo" | wofi --dmenu -p "$name" --width 400 --cache-file /dev/null)
                case "$action" in
                    "󰂱 Conectar")
                        bluetoothctl connect "$mac" 2>/dev/null
                        notify-send "Bluetooth" "Conectado a $name"
                        ;;
                    "󰂎 Olvidar dispositivo")
                        bluetoothctl remove "$mac" 2>/dev/null
                        notify-send "Bluetooth" "$name eliminado"
                        ;;
                esac
            fi
        fi
        ;;
esac
