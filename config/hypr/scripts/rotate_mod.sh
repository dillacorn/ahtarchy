#!/bin/bash

CONFIG="$HOME/.config/hypr/hyprland.conf"

if grep -q '^\$rotate *= *ALT' "$CONFIG"; then
    sed -i 's/^\($rotate *= *\)ALT/\1SUPER/' "$CONFIG"
    notify-send "Hyprland" "\$rotate changed to SUPER"
    hyprctl reload
elif grep -q '^\$rotate *= *SUPER' "$CONFIG"; then
    sed -i 's/^\($rotate *= *\)SUPER/\1ALT/' "$CONFIG"
    notify-send "Hyprland" "\$rotate changed to ALT"
    hyprctl reload
else
    notify-send "Hyprland" "No \$rotate line found to toggle"
fi
