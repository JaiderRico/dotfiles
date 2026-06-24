#!/bin/bash
# Destruye workspaces vacíos automáticamente
while true; do
    hyprctl dispatch workspaceopt destroyempty 2>/dev/null
    sleep 2
done
