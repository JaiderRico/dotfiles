#!/bin/bash

selected=$(hyprctl clients -j | jq -r '
  sort_by(.workspace.id)
  | .[]
  | select(.mapped == true and .hidden == false and .workspace.id > 0)
  | "\(.workspace.id) | \(.title) | \(.class) | \(.address)"
' | rofi -dmenu -p "Ventanas" -i -theme-str '
window { width: 50%; }
listview { lines: 15; }
')

[ -z "$selected" ] && exit 0

addr=$(echo "$selected" | awk -F ' \\| ' '{print $NF}')
hyprctl dispatch focuswindow address:"$addr"
