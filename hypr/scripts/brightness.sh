#!/bin/bash
case $1 in
    up)   brightnessctl set +5% ;;
    down) brightnessctl set 5%- ;;
esac
VAL=$(brightnessctl get)
MAX=$(brightnessctl max)
PCT=$((VAL * 100 / MAX))
notify-send -h int:value:$PCT -h string:x-canonical-private-synchronous:brightness "${PCT}%" -t 1000
