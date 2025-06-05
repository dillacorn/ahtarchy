#!/bin/bash

CONFIG="$HOME/.config/hypr/hyprland.conf"

if grep -q '^\$rotate *= *ALT' "$CONFIG"; then
    sed -i 's/^\($rotate *= *\)ALT/\1SUPER/' "$CONFIG"
    notify-send "Hyprland" "\$rotate changed to SUPER"
    ~/.config/hypr/scripts/silent-wallpaper-fix.sh
elif grep -q '^\$rotate *= *SUPER' "$CONFIG"; then
    sed -i 's/^\($rotate *= *\)SUPER/\1ALT/' "$CONFIG"
    notify-send "Hyprland" "\$rotate changed to ALT"
    ~/.config/hypr/scripts/silent-wallpaper-fix.sh
else
    notify-send "Hyprland" "No \$rotate line found to toggle"
fi
