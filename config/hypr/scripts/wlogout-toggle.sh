#!/usr/bin/env bash

if pgrep -x wlogout > /dev/null; then
    pkill -x wlogout
    exit 0
fi

# Notify user to turn off caps lock if it's on
CAPS_STATE=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capsLock')

if [[ "$CAPS_STATE" == "true" ]]; then
    hyprctl notify -1 3000 "rgb(ff0000)" "Caps Lock is ON - disable it or use lowercase"
fi

wlogout
