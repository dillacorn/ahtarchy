#!/bin/bash

# Define paths
CACHE_DIR="$HOME/.cache"
LAST_WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# First login setup
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    # Only set default wallpaper if it exists (fail silently)
    if [ -f "$DEFAULT_WALLPAPER" ]; then
        swww img "$DEFAULT_WALLPAPER" && \
        echo "$DEFAULT_WALLPAPER" > "$LAST_WALLPAPER_FILE"
    fi
    touch "$FIRST_RUN_FLAG"
else
    # Subsequent logins: restore last wallpaper if recorded
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        swww img "$(cat "$LAST_WALLPAPER_FILE")"
    fi
fi