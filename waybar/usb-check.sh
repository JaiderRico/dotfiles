#!/bin/bash
while true; do
    usbs=$(lsblk -o TRAN,MOUNTPOINT,NAME 2>/dev/null | grep "^usb" | grep -v "^$" | grep -c "/")
    if [ "$usbs" -gt 0 ]; then
        echo "{\"text\":\"󰁪 $usbs\",\"class\":\"connected\",\"tooltip\":\"$usbs USB conectada(s) - Click para expulsar\"}"
    else
        echo "{\"text\":\"\",\"class\":\"disconnected\"}"
    fi
    sleep 2
done
