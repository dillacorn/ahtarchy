#!/bin/bash

SUNSHINE_LOG="$HOME/.config/sunshine/sunshine.log"
TARGET_WORKSPACE="1"
STEAM_CLASS="steam"

echo "[Moonlight Auto-Fix] Waiting for $SUNSHINE_LOG to appear..."

while [ ! -f "$SUNSHINE_LOG" ]; do
    sleep 2
done

echo "[Moonlight Auto-Fix] Found log, starting monitor..."

tail -Fn0 "$SUNSHINE_LOG" | while read -r line; do
    if echo "$line" | grep -qi "Client connected"; then
        echo "$(date) [Moonlight Auto-Fix] Moonlight connection detected."

        # Find Steam window address and its current workspace
        STEAM_INFO=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$STEAM_CLASS"'") | "\(.address) \(.workspace.id)"' | head -n1)
        STEAM_WINDOW=$(echo "$STEAM_INFO" | awk '{print $1}')
        CURRENT_WS=$(echo "$STEAM_INFO" | awk '{print $2}')

        if [ -z "$STEAM_WINDOW" ]; then
            echo "$(date) [Moonlight Auto-Fix] Steam window not found."
            continue
        fi

        echo "$(date) [Moonlight Auto-Fix] Found Steam window $STEAM_WINDOW on workspace $CURRENT_WS."

        if [ "$CURRENT_WS" != "$TARGET_WORKSPACE" ]; then
            echo "$(date) [Moonlight Auto-Fix] Switching to workspace $CURRENT_WS to focus Steam..."
            hyprctl dispatch workspace "$CURRENT_WS"
            sleep 0.3
        fi

        echo "$(date) [Moonlight Auto-Fix] Focusing Steam window $STEAM_WINDOW..."
        hyprctl dispatch focuswindow "$STEAM_WINDOW"
        sleep 0.3

        ACTIVE_WIN_CLASS=$(hyprctl activewindow -j | jq -r '.class')
        if [ "$ACTIVE_WIN_CLASS" = "$STEAM_CLASS" ]; then
            echo "$(date) [Moonlight Auto-Fix] Steam focused, moving to workspace $TARGET_WORKSPACE..."
            hyprctl dispatch movetoworkspace "$TARGET_WORKSPACE"
            sleep 0.3
        else
            echo "$(date) [Moonlight Auto-Fix] Failed to focus Steam window; active window is $ACTIVE_WIN_CLASS. Not moving."
        fi

        echo "$(date) [Moonlight Auto-Fix] Switching to workspace $TARGET_WORKSPACE..."
        hyprctl dispatch workspace "$TARGET_WORKSPACE"
    fi
done
