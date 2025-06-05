#!/bin/bash

# --- Config ---
CACHE_DIR="$HOME/.cache"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

# --- Restart swww-daemon cleanly to ensure correct session ---
pkill -x swww-daemon 2>/dev/null
sleep 0.2

# --- Start swww-daemon (silently) ---
swww-daemon --format xrgb >/dev/null 2>&1 &
sleep 0.5

# --- Ensure cache exists ---
mkdir -p "$CACHE_DIR"

# --- Set wallpaper only if file exists ---
set_wallpaper() {
    [[ ! -f "$1" ]] && return 1  # Cancel if missing
    swww img "$1" --transition-type simple --transition-duration 60 --resize fit >/dev/null 2>&1 && \
        echo "$1" > "$CACHE_DIR/last_wallpaper"
}

# --- First run: try default wallpaper (silently skip if missing) ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
    set_wallpaper "$DEFAULT_WALLPAPER" || true  # Ignore failure
    touch "$FIRST_RUN_FLAG"
else
    # Subsequent runs: read wallpaper from waypaper config.ini and set if file exists
    WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
    if [[ -f "$WAYPAPER_CONFIG" ]]; then
        WALLPAPER_PATH=$(grep '^wallpaper *= *' "$WAYPAPER_CONFIG" | head -1 | cut -d'=' -f2- | xargs)
        # Expand ~ to $HOME if present
        WALLPAPER_PATH="${WALLPAPER_PATH/#\~/$HOME}"
        if [[ -f "$WALLPAPER_PATH" ]]; then
            set_wallpaper "$WALLPAPER_PATH"
        else
            echo "Wallpaper file from config.ini not found: $WALLPAPER_PATH" >&2
        fi
    else
        echo "Waypaper config.ini not found at $WAYPAPER_CONFIG" >&2
    fi
fi
