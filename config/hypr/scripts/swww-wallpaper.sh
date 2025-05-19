#!/bin/bash

# --- Config ---
CACHE_DIR="$HOME/.cache"
LAST_WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

# --- Start swww-daemon (silently) ---
if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon --format xrgb >/dev/null 2>&1 &
    sleep 0.5
fi

# --- Ensure cache exists ---
mkdir -p "$CACHE_DIR"

# --- Set wallpaper only if file exists ---
set_wallpaper() {
    [[ ! -f "$1" ]] && return 1  # Cancel if missing
    swww img "$1" --transition-type simple >/dev/null 2>&1 && \
        echo "$1" > "$LAST_WALLPAPER_FILE"
}

# --- First run: try default wallpaper (silently skip if missing) ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
    set_wallpaper "$DEFAULT_WALLPAPER" || true  # Ignore failure
    touch "$FIRST_RUN_FLAG"
else
    # Subsequent runs: restore last wallpaper (if exists)
    [[ -f "$LAST_WALLPAPER_FILE" ]] && set_wallpaper "$(cat "$LAST_WALLPAPER_FILE")"
fi
