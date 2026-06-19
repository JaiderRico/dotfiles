#!/bin/bash
case "$1" in
    up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}')
muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c "MUTED")
if [ "$muted" -eq 1 ]; then
    icon="🔇"; message="Silencio"; value=0
else
    icon="🔊"; message="${vol}%"; value=${vol%.*}
fi
notify-send -t 1500 -h int:value:$value -h string:x-canonical-private-synchronous:volume "$icon Volumen" "$message"
