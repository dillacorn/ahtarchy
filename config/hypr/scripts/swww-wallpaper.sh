#!/bin/bash

# --- Setup paths ---
CACHE_DIR="$HOME/.cache"
LAST_WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

# --- Ensure swww daemon is running ---
if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon --format xrgb & disown
    sleep 0.5  # Give it time to start
fi

# --- Ensure cache directory exists ---
mkdir -p "$CACHE_DIR"

# --- Determine what wallpaper to use ---
set_wallpaper() {
    local file="$1"
    if [[ -f "$file" ]]; then
        current="$(cat "$LAST_WALLPAPER_FILE" 2>/dev/null)"
        if [[ "$file" != "$current" ]]; then
            swww img "$file" --transition-type simple 2>/dev/null
            echo "$file" > "$LAST_WALLPAPER_FILE"
        fi
    fi
}

# --- First run? Set default wallpaper if exists ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
    set_wallpaper "$DEFAULT_WALLPAPER"
    touch "$FIRST_RUN_FLAG"
else
    # Restore last wallpaper
    [[ -f "$LAST_WALLPAPER_FILE" ]] && set_wallpaper "$(cat "$LAST_WALLPAPER_FILE")"
fi
