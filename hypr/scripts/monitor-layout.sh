#!/usr/bin/env bash
# Monitor layout — cambia entre laptop-only, mirror, y dock
# Ejecutar sin args para menú rofi

MODE="${1:-menu}"

laptop_only() {
    hyprctl keyword monitor "eDP-1, preferred, 0x0, 1"
    hyprctl keyword monitor "HDMI-A-1, disabled"
    hyprctl keyword monitor "DP-1, disabled"
    hyprctl keyword monitor "DP-2, disabled"
    notify-send "Monitor" "Solo laptop"
}

mirror() {
    local ext="$(detect_external)"
    [ -z "$ext" ] && notify-send "Monitor" "No se detectó monitor externo" && exit 1
    hyprctl keyword monitor "$ext, preferred, auto, 1, mirror, eDP-1"
    notify-send "Monitor" "Mirror activado en $ext"
}

extend_right() {
    local ext="$(detect_external)"
    [ -z "$ext" ] && notify-send "Monitor" "No se detectó monitor externo" && exit 1
    local laptop_res="$(hyprctl monitors | grep -A2 'eDP-1' | grep 'bytes' | awk '{print $1}')"
    [ -z "$laptop_res" ] && laptop_res="1920x1080"
    hyprctl keyword monitor "eDP-1, $laptop_res, 0x0, 1"
    hyprctl keyword monitor "$ext, preferred, auto-right, 1"
    notify-send "Monitor" "Extendido a la derecha"
}

detect_external() {
    for m in HDMI-A-1 DP-1 DP-2; do
        if hyprctl monitors | grep -q "$m"; then
            echo "$m"
            return 0
        fi
    done
    return 1
}

menu() {
    local choice=$(printf "󰍹 Solo laptop\n󰹑 Mirror\n󰛋 Extender derecha" | rofi -dmenu -p "Monitores")
    case "$choice" in
        *laptop*) laptop_only ;;
        *Mirror*) mirror ;;
        *Extender*) extend_right ;;
    esac
}

case "$MODE" in
    laptop) laptop_only ;;
    mirror) mirror ;;
    extend) extend_right ;;
    *) menu ;;
esac
