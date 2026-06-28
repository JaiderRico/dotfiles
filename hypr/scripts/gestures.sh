#!/usr/bin/env bash
# Gestures for Hyprland via libinput-gestures
# This integrates with Hyprland's built-in gesture support

set -e

# Ensure libinput-gestures is configured
CONFIG_DIR="$HOME/.config/libinput-gestures"
CONFIG_FILE="$CONFIG_DIR/libinput-gestures.conf"

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" << 'GESTURES'
# Gestures para Hyprland
# 3 dedos: navegación de workspaces
gesture swipe left 3 hyprctl dispatch workspace e+1
gesture swipe right 3 hyprctl dispatch workspace e-1

# 4 dedos: minimizar/restaurar scratchpad
gesture swipe up 4 hyprctl dispatch togglespecialworkspace
gesture swipe down 4 hyprctl dispatch movetoworkspace special

# 4 dedos izquierda/derecha: cerrar ventana / abrir rofi
gesture swipe left 4 hyprctl dispatch killactive
gesture swipe right 4 hyprctl dispatch exec rofi -show drun
GESTURES

# Reload config
libinput-gestures-setup stop 2>/dev/null || true
libinput-gestures-setup start 2>/dev/null || true

notify-send "Gestures" "Gestos táctiles configurados"
