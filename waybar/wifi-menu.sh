#!/bin/bash

ROFI_THEME="$HOME/.config/rofi/catppuccin-mocha.rasi"
CURRENT_SSID=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -E "^.*:wlp" | head -1 | cut -d: -f1)

list_networks() {
    nmcli device wifi rescan 2>/dev/null &
    nmcli -t -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | \
        awk -F: -v cur="$CURRENT_SSID" '
        {
            ssid=$1; signal=$2; sec=$3
            if (ssid == "" || seen[ssid]++) next
            if (signal+0 >= 80) icon="󰤨"
            else if (signal+0 >= 60) icon="󰤥"
            else if (signal+0 >= 40) icon="󰤢"
            else if (signal+0 >= 20) icon="󰤡"
            else icon="󰤟"
            lock = (sec != "" && sec != "--") ? " 󰌾" : ""
            mark = (ssid == cur) ? " 󰄲" : ""
            print icon, ssid mark lock
        }' | sort
}

networks=$(list_networks)

if [ -z "$networks" ]; then
    notify-send -u critical "WiFi" "No se encontraron redes"
    exit 1
fi

if [ -n "$CURRENT_SSID" ]; then
    menu="󰑓 Rescanear\n󰖪 Desconectar de $CURRENT_SSID\n$networks"
else
    menu="󰑓 Rescanear\n$networks"
fi

chosen=$(echo -e "$menu" | rofi -dmenu -p "WiFi" -theme "$ROFI_THEME")

case "$chosen" in
    "")
        exit 0
        ;;
    "󰑓 Rescanear")
        exec "$0"
        ;;
    "󰖪 Desconectar"*)
        nmcli connection down "$CURRENT_SSID" 2>/dev/null
        notify-send "WiFi" "Desconectado de $CURRENT_SSID"
        exit 0
        ;;
    *)
        ssid=$(echo "$chosen" | sed 's/^[^ ]* //; s/ 󰌾//g; s/ 󰄲//g; s/ *$//')
        sec_type=$(nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null | grep -F ":$ssid:" | cut -d: -f3 | head -1)

        if [ -n "$sec_type" ] && [ "$sec_type" != "--" ] && [ "$sec_type" != "" ]; then
            password=$(rofi -dmenu -password -p "Contraseña" -theme "$ROFI_THEME" -theme-str "entry {placeholder: \"Contraseña para $ssid...\";}")
            if [ -z "$password" ]; then
                exit 1
            fi
            nmcli device wifi connect "$ssid" password "$password" 2>/dev/null
        else
            nmcli device wifi connect "$ssid" 2>/dev/null
        fi

        if [ $? -eq 0 ]; then
            notify-send "WiFi" "Conectado a $ssid"
        else
            notify-send -u critical "WiFi" "Error al conectar a $ssid"
        fi
        ;;
esac
