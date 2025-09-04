# ~/.config/waybar/scripts/toggle_resize.sh
#!/usr/bin/env bash
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

# Explicit reset (optional)
if [[ "${1:-}" == "reset" ]]; then
  reset_mode
  exit 0
fi

# Toggle OFF if already active
if [[ -f "$STATE_FILE" ]]; then
  reset_mode
  exit 0
fi

# Always enter resize submap (no guards for fullscreen or window count)
hyprctl dispatch submap resize

# Track current workspace and auto-reset on workspace change
ws_id="$(hyprctl -j activeworkspace | jq -r '.id' 2>/dev/null || echo)"
printf '%s\n' "$ws_id" > "$STATE_FILE"

(
  start_ws="$ws_id"
  while :; do
    cur_ws="$(hyprctl -j activeworkspace | jq -r '.id' 2>/dev/null || echo)"
    if [[ -n "$cur_ws" && "$cur_ws" != "$start_ws" ]]; then
      "$SELF" reset
      break
    fi
    sleep 0.2
  done
) & echo $! > "$WATCH_PID_FILE"
