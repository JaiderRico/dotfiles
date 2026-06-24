#!/bin/bash
mounts=$(lsblk -o TRAN,MOUNTPOINT,NAME,SIZE 2>/dev/null | grep "^usb" | grep "/")
if [ -z "$mounts" ]; then
    notify-send "USB" "No hay USBs conectadas"
    exit 0
fi

options=""
while IFS= read -r line; do
    mountpoint=$(echo "$line" | awk '{print $2}')
    size=$(echo "$line" | awk '{print $3}')
    name=$(echo "$line" | awk '{print $4}')
    label=$(lsblk -o LABEL "/dev/$name" 2>/dev/null | tail -1)
    [ -z "$label" ] && label="$name"
    options+="󰁪 $label ($mountpoint) [$size]\n"
done <<< "$mounts"

chosen=$(echo -e "$options" | rofi -dmenu -p "Expulsar USB" -no-custom -theme-str 'entry { enabled: false;} mainbox { children: [listview]; }')
[ -z "$chosen" ] && exit 0

mountpoint=$(echo "$chosen" | sed 's/.*(\([^)]*\)).*/\1/')
if [ -n "$mountpoint" ]; then
    sync
    udisksctl unmount -b "$mountpoint" 2>/dev/null || sudo umount "$mountpoint" 2>/dev/null
    sleep 1
    device=$(lsblk -o MOUNTPOINT,NAME 2>/dev/null | grep "$mountpoint" | awk '{print $2}')
    if [ -z "$device" ]; then
        notify-send "USB" "Expulsada correctamente"
    else
        notify-send -u critical "USB" "Error al expulsar. Cierra archivos abiertos e intenta de nuevo."
    fi
fi
