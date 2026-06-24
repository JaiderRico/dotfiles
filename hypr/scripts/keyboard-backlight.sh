#!/bin/bash
MAX=255
CUR=$(cat /sys/class/leds/smc::kbd_backlight/brightness)
case $1 in
    up)   NEW=$((CUR + 25)); [ $NEW -gt $MAX ] && NEW=$MAX ;;
    down) NEW=$((CUR - 25)); [ $NEW -lt 0 ] && NEW=0 ;;
esac
echo $NEW | sudo tee /sys/class/leds/smc::kbd_backlight/brightness
PCT=$((NEW * 100 / MAX))
notify-send -h string:x-canonical-private-synchronous:kbdlight "Teclado" "$PCT%" -t 1000
