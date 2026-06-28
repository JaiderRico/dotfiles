#!/usr/bin/env bash
# Wifi menu con wofi — rápido, conectar/desconectar

pgrep -u "$UID" -x wofi &>/dev/null && exit 0

CURRENT_SSID=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep ":wlp" | head -1 | cut -d: -f1)

list_networks() {
    nmcli -t -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | awk -F: -v cur="$CURRENT_SSID" '
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

if [ -n "$CURRENT_SSID" ]; then
    menu="󰑓 Rescanear\n󰖪 Desconectar de $CURRENT_SSID\n$networks"
else
    menu="󰑓 Rescanear\n$networks"
fi

chosen=$(echo -e "$menu" | wofi --dmenu -p "WiFi" --width 520 --cache-file /dev/null)
[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰑓 Rescanear")
        nmcli device wifi rescan 2>/dev/null &
        notify-send "WiFi" "Escaneando redes..."
        sleep 2
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
            password=$(wofi --dmenu --password -p "Contrasena" --width 400 --cache-file /dev/null)
            [ -z "$password" ] && exit 1
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
