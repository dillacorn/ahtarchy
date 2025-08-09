#!/bin/sh

handled=0

hyprctl -j subscribe openwindow | while read -r _; do
    while :; do
        steam_id=$(hyprctl clients -j | jq -r '.[] | select(.title=="Steam" and .class=="steam") | .address')
        friends_id=$(hyprctl clients -j | jq -r '.[] | select(.title=="Friends List" and .class=="steam") | .address')

        if [ -n "$steam_id" ] && [ -n "$friends_id" ] && [ "$handled" -eq 0 ]; then
            # Focus Steam window
            hyprctl dispatch focuswindow address:"$steam_id"
            # Set split ratio for Steam window (65%)
            hyprctl dispatch splitratio 0.35
            # Move Friends List window to right (floating, tiled right split)
            hyprctl dispatch movewindow address:"$friends_id" workspace active
            hyprctl dispatch movewindow right
            handled=1
            break
        fi

        sleep 0.2
    done
done
