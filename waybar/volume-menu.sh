#!/bin/bash
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
result=$(yad --scale \
    --value=$volume \
    --min-value=0 \
    --max-value=100 \
    --step=5 \
    --no-buttons \
    --undecorated \
    --fixed \
    --close-on-unfocus \
    --width=300 \
    --css ~/.config/gtk-3.0/yad.css \
    --title="󰕾 Volumen")
[ -n "$result" ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ "${result}%"
