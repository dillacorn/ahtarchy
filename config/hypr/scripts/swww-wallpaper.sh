#!/bin/bash

# --- Config ---
CACHE_DIR="$HOME/.cache"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

# --- Ensure cache directory exists ---
mkdir -p "$CACHE_DIR"

# --- Start swww-daemon if not running ---
if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon &
    sleep 0.5
fi

# --- Function to set wallpaper if it exists ---
set_wallpaper() {
    [[ -f "$1" ]] || return 1
    swww img "$1" --transition-type simple >/dev/null 2>&1 && \
        echo "$1" > "$CACHE_DIR/last_wallpaper"
}

# --- First run: use default wallpaper (if it exists) ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
    set_wallpaper "$DEFAULT_WALLPAPER" || true
    touch "$FIRST_RUN_FLAG"
else
    # Subsequent runs: pull last selected wallpaper from waypaper config
    if [[ -f "$WAYPAPER_CONFIG" ]]; then
        WALLPAPER_PATH=$(grep -E '^wallpaper *= *' "$WAYPAPER_CONFIG" | head -1 | cut -d'=' -f2- | xargs)
        WALLPAPER_PATH="${WALLPAPER_PATH/#\~/$HOME}"  # Expand tilde to $HOME
        if [[ -f "$WALLPAPER_PATH" ]]; then
            set_wallpaper "$WALLPAPER_PATH"
        else
            echo "Wallpaper file not found: $WALLPAPER_PATH" >&2
        fi
    else
        echo "Waypaper config not found at $WAYPAPER_CONFIG" >&2
    fi
fi
