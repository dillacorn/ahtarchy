#!/bin/bash

# --- Config ---
CACHE_DIR="$HOME/.cache"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"
LOG_FILE="$CACHE_DIR/swww_log"

mkdir -p "$CACHE_DIR"

# --- Function: Expand tilde (~) in path ---
expand_path() {
    echo "$1" | sed "s|^~|$HOME|"
}

# --- Function: Set wallpaper with swww ---
set_wallpaper() {
    local path="$1"
    if [[ -f "$path" ]]; then
        swww img "$path" \
            --transition-type simple \
            --transition-duration 60 \
            --resize crop >> "$LOG_FILE" 2>&1
    else
        echo "Wallpaper not found: $path" >> "$LOG_FILE"
    fi
}

# --- Ensure swww-daemon is running ---
if ! pgrep -x swww-daemon >/dev/null; then
    echo "swww-daemon is not running. Exiting." >> "$LOG_FILE"
    exit 1
fi

# --- Get wallpaper path from Waypaper config ---
if [[ -f "$WAYPAPER_CONFIG" ]]; then
    wp_line=$(grep '^wallpaper *= *' "$WAYPAPER_CONFIG" | tail -n 1)
    wp_path_raw="${wp_line#*= }"
    wp_path=$(expand_path "$wp_path_raw")

    if [[ -f "$wp_path" ]]; then
        set_wallpaper "$wp_path"
        exit 0
    else
        echo "Waypaper config found, but wallpaper path invalid: $wp_path" >> "$LOG_FILE"
    fi
fi

# --- Fallback: use default wallpaper ---
set_wallpaper "$DEFAULT_WALLPAPER"
