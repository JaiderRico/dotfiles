#!/usr/bin/env bash

# Close swaync control center if open
swaync-client -cp 2>/dev/null

# Toggle eww popup
if eww active-windows | grep -q calendar_popup; then
    eww close calendar_popup
else
    eww open calendar_popup
fi
