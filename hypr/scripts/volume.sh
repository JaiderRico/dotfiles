#!/bin/bash
case $1 in
    up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c "MUTED")
if [ "$MUTED" -eq 1 ]; then
    msg="🔇"
else
    msg="${VOL}%"
fi
notify-send -h int:value:$VOL -h string:x-canonical-private-synchronous:volume "$msg" -t 1000
