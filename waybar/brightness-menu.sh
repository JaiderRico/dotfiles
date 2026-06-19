#!/bin/bash
brightness=$(brightnessctl get)
max=$(brightnessctl max)
percent=$((brightness * 100 / max))
result=$(yad --scale \
    --value=$percent \
    --min-value=1 \
    --max-value=100 \
    --step=5 \
    --no-buttons \
    --undecorated \
    --fixed \
    --close-on-unfocus \
    --width=300 \
    --css ~/.config/gtk-3.0/yad.css \
    --title="󰃞 Brillo")
[ -n "$result" ] && brightnessctl set "${result}%"
