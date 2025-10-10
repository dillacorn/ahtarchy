#!/usr/bin/env bash
# ~/.config/hypr/scripts/wofi-toggle.sh
# Workspace-aware toggle for wofi:
# - If wofi is visible on the current workspace, close it.
# - If wofi is running on another workspace, close it and relaunch here.
# - If wofi is not running, launch it here.
# Quiet: all jq/hyprctl errors are silenced.

set -euo pipefail

# Silence noisy tool stderr; keep script failures visible.
quiet() { "$@" 2>/dev/null; }

need() { command -v "$1" >/dev/null 2>&1; }
for bin in hyprctl jq pgrep pkill; do
  need "$bin" || { echo "Missing dependency: $bin" >&2; exit 1; }
done

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
STATE_FILE="$STATE_DIR/wofi-toggle.state"
mkdir -p "$STATE_DIR"

is_running() { pgrep -x wofi >/dev/null; }

# Visible on current workspace (proxied by focused monitor’s overlay layer)
wofi_visible_here() {
  quiet hyprctl layers -j | quiet jq -e '
    ( .monitors // [] )[]
    | select(.focused == true)
    | ( .layers.overlay // [] )
    | any(.namespace == "wofi" and .mapped == true)
  ' >/dev/null
}

cur_ws_id() {
  quiet hyprctl activeworkspace -j | quiet jq -r 'try .id // empty'
}

save_state() {
  # Read values once; tolerate nulls/empties.
  local ws_id ws_name mon now
  ws_id="$(cur_ws_id || true)"
  ws_name="$(quiet hyprctl activeworkspace -j | quiet jq -r 'try .name // empty' || true)"
  mon="$(quiet hyprctl monitors -j | quiet jq -r '.[] | select(.focused==true) | .name' || true)"
  now="$(date +%s)"

  # Single jq build; no ternaries that break older jq; fully guarded.
  quiet jq -n \
    --arg ws_id "$ws_id" \
    --arg ws_name "$ws_name" \
    --arg monitor "$mon" \
    --arg ts "$now" '
    {
      ws_id:   (if ($ws_id|length) > 0 and ($ws_id|tonumber? != null) then ($ws_id|tonumber) else null end),
      ws_name: (if ($ws_name|length) > 0 then $ws_name else null end),
      monitor: (if ($monitor|length) > 0 then $monitor else null end),
      ts:      ($ts|tonumber)
    }' >"$STATE_FILE" || true
}

state_ws_id() {
  quiet jq -r 'try .ws_id // empty' <"$STATE_FILE" || true
}

kill_wofi() {
  pkill -x wofi 2>/dev/null || true
  for _ in $(seq 1 50); do is_running || return 0; sleep 0.02; done
  pkill -9 -x wofi 2>/dev/null || true
}

launch_wofi() {
  nohup wofi --show drun >/dev/null 2>&1 &
  save_state
}

main() {
  if is_running; then
    if wofi_visible_here; then
      kill_wofi
      exit 0
    fi
    # Not visible here. If last-known ws matches, treat as stale and just kill; else kill+relaunch.
    cur_id="$(cur_ws_id || true)"
    saved_id="$(state_ws_id || true)"
    if [[ -n "${saved_id:-}" && -n "${cur_id:-}" && "$saved_id" == "$cur_id" ]]; then
      kill_wofi
      exit 0
    fi
    kill_wofi
    launch_wofi
  else
    launch_wofi
  fi
}
main
