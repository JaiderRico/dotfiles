#!/usr/bin/env bash
# Quick note — abre un scratchpad con nvim para nota rápida
NOTE_FILE="/tmp/quicknote.md"

if [ -n "$(pgrep -f "nvim $NOTE_FILE")" ]; then
    # Si ya está abierto, traerlo al frente via Hyprland
    hyprctl dispatch focuswindow "title:.*quicknote.*" 2>/dev/null || \
    kitty --title "quicknote" nvim "$NOTE_FILE"
else
    kitty --title "quicknote" nvim "$NOTE_FILE"
fi
