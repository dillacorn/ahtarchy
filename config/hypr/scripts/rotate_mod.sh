#!/bin/bash

CONFIG="$HOME/.config/hypr/hyprland.conf"

sed -i 's/^\($rotate *= *\)ALT/\1SUPER/;t; s/^\($rotate *= *\)SUPER/\1ALT/' "$CONFIG"

echo "Toggled \$rotate between ALT and SUPER in $CONFIG"
