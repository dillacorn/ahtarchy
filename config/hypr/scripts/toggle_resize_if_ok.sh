#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/toggle_resize_if_ok.sh

set -euo pipefail

SELF="$(readlink -f "$0")"
STATE_FILE="/tmp/hypr-resize.state"
WATCH_PID_FILE="/tmp/hypr-resize.wpid"

reset_mode() {
  hyprctl dispatch submap reset >/dev/null 2>&1 || true
  if [[ -f "$WATCH_PID_FILE" ]]; then
    pid="$(cat "$WATCH_PID_FILE" 2>/dev/null || echo)"
    [[ -n "${pid:-}" ]] && kill "$pid" >/dev/null 2>&1 || true
    rm -f "$WATCH_PID_FILE"
  fi
  rm -f "$STATE_FILE"
}

# Explicit reset (used by your exit binds)
if [[ "${1:-}" == "reset" ]]; then
  reset_mode
  exit 0
fi

# If we believe we're active, toggle OFF
if [[ -f "$STATE_FILE" ]]; then
  reset_mode
  exit 0
fi

# Require an active window
aw="$(hyprctl -j activewindow 2>/dev/null || echo null)"
[[ "$aw" == "null" || -z "$aw" ]] && exit 0

# Block if fullscreen (covers multiple Hyprland versions)
if printf '%s' "$aw" | jq -e '
  (.fullscreen == true)
  or ((.fullscreen? | numbers) > 0)
  or ((.fullscreenstate?.internal? // 0) > 0)
  or ((.fullscreenstate?.client?   // 0) > 0)
' >/dev/null; then
  exit 0
fi

# Workspace must have >1 window
ws_id="$(hyprctl -j activeworkspace | jq -r '.id')"
count="$(hyprctl -j clients | jq --argjson ws "$ws_id" '[.[] | select(.workspace.id == $ws)] | length')"
[[ "${count:-0}" -le 1 ]] && exit 0

# Enter resize submap
hyprctl dispatch submap resize

# Record current workspace and start a SHORT-LIVED watcher that
# cancels the submap as soon as you switch workspaces (e.g., via Waybar).
printf '%s\n' "$ws_id" > "$STATE_FILE"

(
  start_ws="$ws_id"
  while :; do
    cur_ws="$(hyprctl -j activeworkspace | jq -r '.id' 2>/dev/null || echo "")"
    if [[ -n "$cur_ws" && "$cur_ws" != "$start_ws" ]]; then
      "$SELF" reset
      break
    fi
    sleep 0.2
  done
) & echo $! > "$WATCH_PID_FILE"
