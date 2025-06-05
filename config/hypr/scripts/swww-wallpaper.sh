#!/bin/bash

# --- Config ---
CACHE_DIR="$HOME/.cache"
LAST_WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

# --- Restart swww-daemon cleanly to ensure correct session ---
pkill -x swww-daemon 2>/dev/null
sleep 0.2

# --- Start swww-daemon silently ---
swww-daemon --format xrgb >/dev/null 2>&1 &
sleep 0.5

# --- Ensure cache directory exists ---
mkdir -p "$CACHE_DIR"

# --- Set wallpaper function ---
set_wallpaper() {
    local wallpaper="$1"
    [[ ! -f "$wallpaper" ]] && return 1

    # Wait until Hyprland has initialized monitors
    until hyprctl monitors &>/dev/null; do sleep 0.1; done
    sleep 0.5

    # Add delay if fractional scaling is detected
    if command -v jq >/dev/null; then
        HAS_SCALING=$(hyprctl monitors -j | jq '[.[].scale] | any(. != 1)')
        if [[ "$HAS_SCALING" == "true" ]]; then
            echo "📏 Detected fractional scaling. Waiting for compositor to stabilize..."
            sleep 1
        fi
    else
        echo "⚠️ jq not found, skipping scale check. Install 'jq' for better behavior."
    fi

    swww img "$wallpaper" --transition-type simple >/dev/null 2>&1 && \
        echo "$wallpaper" > "$LAST_WALLPAPER_FILE"
}

# --- First run: set default wallpaper ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
    set_wallpaper "$DEFAULT_WALLPAPER" || true
    touch "$FIRST_RUN_FLAG"
else
    # Subsequent runs: restore last wallpaper if available
    [[ -f "$LAST_WALLPAPER_FILE" ]] && set_wallpaper "$(cat "$LAST_WALLPAPER_FILE")"
fi
