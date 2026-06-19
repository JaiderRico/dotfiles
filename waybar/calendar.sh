#!/bin/bash
GTK_THEME="" yad --calendar \
    --no-buttons \
    --undecorated \
    --fixed \
    --close-on-unfocus \
    --width=380 \
    --height=220 \
    --posx=810 \
    --posy=42 \
    --css ~/.config/gtk-3.0/yad.css
