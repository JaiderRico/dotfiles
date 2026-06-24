#!/bin/bash
cliphist list | rofi -dmenu -no-custom \
  -theme-str 'inputbar {enabled: false;}' \
  -display-columns 2 | cliphist decode | wl-copy
