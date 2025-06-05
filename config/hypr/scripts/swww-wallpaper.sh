#!/bin/bash

DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

# Restart swww-daemon cleanly
pkill -x swww-daemon 2>/dev/null
sleep 0.2

# Start swww-daemon (silently)
swww-daemon --format xrgb >/dev/null 2>&1 &
sleep 0.5

# Try to restore last wallpaper
if ! swww restore >/dev/null 2>&1; then
    # If restore fails (first run), use default
    [[ -f "$DEFAULT_WALLPAPER" ]] && swww img "$DEFAULT_WALLPAPER"
fi
