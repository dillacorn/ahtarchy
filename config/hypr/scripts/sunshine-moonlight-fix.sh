#!/bin/bash

SUNSHINE_LOG="$HOME/.config/sunshine/sunshine.log"
TARGET_WORKSPACE="1"
STEAM_CLASS="steam"
WAIT_TIMEOUT=300  # seconds to wait for log file before exit

echo "[Moonlight Auto-Fix] Waiting for $SUNSHINE_LOG to appear (timeout $WAIT_TIMEOUT seconds)..."

elapsed=0
while [ ! -f "$SUNSHINE_LOG" ]; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ "$elapsed" -ge "$WAIT_TIMEOUT" ]; then
        echo "[Moonlight Auto-Fix] Timeout waiting for log file. Exiting."
        exit 1
    fi
done

echo "[Moonlight Auto-Fix] Found log, starting monitor..."

tail -F -n0 "$SUNSHINE_LOG" | while read -r line; do
    if echo "$line" | grep -qi "Client connected"; then
        echo "$(date) [Moonlight Auto-Fix] Moonlight connection detected."

        STEAM_INFO=$(hyprctl clients -j 2>/dev/null | jq -r --arg class "$STEAM_CLASS" '.[] | select(.class==$class) | "\(.address) \(.workspace.id)"' | head -n1)
        if [ $? -ne 0 ] || [ -z "$STEAM_INFO" ]; then
            echo "$(date) [Moonlight Auto-Fix] Error retrieving Steam window info or not found."
            continue
        fi

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
            sleep 0.5
        fi

        echo "$(date) [Moonlight Auto-Fix] Focusing Steam window $STEAM_WINDOW..."
        hyprctl dispatch focuswindow "$STEAM_WINDOW"
        sleep 0.5

        ACTIVE_WIN_CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class')
        if [ "$ACTIVE_WIN_CLASS" = "$STEAM_CLASS" ]; then
            echo "$(date) [Moonlight Auto-Fix] Steam focused, moving to workspace $TARGET_WORKSPACE..."
            hyprctl dispatch movetoworkspace "$TARGET_WORKSPACE"
            sleep 0.5
        else
            echo "$(date) [Moonlight Auto-Fix] Failed to focus Steam window; active window is $ACTIVE_WIN_CLASS. Not moving."
        fi

        echo "$(date) [Moonlight Auto-Fix] Switching to workspace $TARGET_WORKSPACE..."
        hyprctl dispatch workspace "$TARGET_WORKSPACE"
    fi
done
