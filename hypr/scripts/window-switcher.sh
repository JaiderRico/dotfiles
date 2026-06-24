#!/bin/bash
# Muestra todas las ventanas abiertas con rofi y cambia a la seleccionada

clients=$(hyprctl clients -j | jq -r '
    [.[] | select(.workspace.id > 0 and .mapped == true)]
    | sort_by(.workspace.id, .at[1], .at[0])
    | .[]
    | "\(.workspace.id): \(.title) [\(.address)]"
')

[ -z "$clients" ] && exit 1

selected=$(echo "$clients" | rofi -dmenu -p " Ventanas " -i \
    -theme-str 'window {width: 50%;} listview {lines: 10;}')

[ -z "$selected" ] && exit

addr=$(echo "$selected" | sed 's/.*\[\(0x[0-9a-f]*\)\].*/\1/')
[ -n "$addr" ] && hyprctl dispatch focuswindow address:"$addr"
