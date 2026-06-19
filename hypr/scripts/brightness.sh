#!/bin/bash
case "$1" in
    up)   brightnessctl set 5%+ ;;
    down) brightnessctl set 5%- ;;
esac
bright=$(brightnessctl i | grep -oP '\(\K[0-9]+(?=%)')
notify-send -t 1500 -h int:value:$bright -h string:x-canonical-private-synchronous:brightness "☀️ Brillo" "$bright%"
