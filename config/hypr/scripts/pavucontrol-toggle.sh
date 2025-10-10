#!/usr/bin/env bash
# ~/.config/hypr/scripts/pavucontrol-toggle.sh
# Workspace-aware toggle for pavucontrol:
# - If pavucontrol is visible on the current workspace, close it.
# - If pavucontrol is running on another workspace, close it and relaunch here.
# - If pavucontrol is not running, launch it here.
# All hyprctl/jq noise is silenced; failures still exit nonzero.

set -euo pipefail

# -----------------------------------
# Dependencies and constants
# -----------------------------------
quiet() { "$@" 2>/dev/null; }     # silence only stderr of wrapped command

need() { command -v "$1" >/dev/null 2>&1; }
for bin in hyprctl jq pgrep pkill nohup; do
  need "$bin" || { echo "Missing dependency: $bin" >&2; exit 1; }
done

PROC_NAME="pavucontrol"                    # actual process name
WM_CLASS="org.pulseaudio.pavucontrol"      # Hyprland class

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
STATE_FILE="$STATE_DIR/pavucontrol-toggle.state"
mkdir -p "$STATE_DIR"

# -----------------------------------
# Helpers
# -----------------------------------
is_running() {
  # Match exact binary name; tolerate multiple instances.
  pgrep -x "$PROC_NAME" >/dev/null
}

cur_ws_id() {
  quiet hyprctl activeworkspace -j | quiet jq -r 'try .id // empty'
}

pavucontrol_visible_here() {
  local cur
  cur="$(cur_ws_id || true)"
  [ -n "${cur:-}" ] || return 1

  # Scan clients on the compositor; look for our class on the current workspace and not hidden.
  quiet hyprctl clients -j | quiet jq -e --arg cls "$WM_CLASS" --argjson ws "$cur" '
    [ (.[]? // empty)
      | select(.class == $cls and (.workspace.id // -1) == $ws and (.hidden // false) == false)
    ] | length > 0
  ' >/dev/null
}

save_state() {
  local ws_id ws_name mon now
  ws_id="$(cur_ws_id || true)"
  ws_name="$(quiet hyprctl activeworkspace -j | quiet jq -r 'try .name // empty' || true)"
  mon="$(quiet hyprctl monitors -j | quiet jq -r '.[]? | select(.focused==true) | .name' || true)"
  now="$(date +%s)"

  quiet jq -n \
    --arg ws_id "${ws_id:-}" \
    --arg ws_name "${ws_name:-}" \
    --arg monitor "${mon:-}" \
    --arg ts "$now" '
    {
      ws_id:   (if ($ws_id|length)>0 and ($ws_id|tonumber? != null) then ($ws_id|tonumber) else null end),
      ws_name: (if ($ws_name|length)>0 then $ws_name else null end),
      monitor: (if ($monitor|length)>0 then $monitor else null end),
      ts:      ($ts|tonumber)
    }' >"$STATE_FILE" || true
}

state_ws_id() {
  [ -f "$STATE_FILE" ] || { printf "%s" ""; return 0; }
  quiet jq -r 'try .ws_id // empty' <"$STATE_FILE" || true
}

kill_pavucontrol() {
  pkill -x "$PROC_NAME" 2>/dev/null || true
  for _ in $(seq 1 50); do is_running || return 0; sleep 0.02; done
  pkill -9 -x "$PROC_NAME" 2>/dev/null || true
}

launch_pavucontrol() {
  nohup "$PROC_NAME" >/dev/null 2>&1 &
  save_state
}

# -----------------------------------
# Main
# -----------------------------------
main() {
  if is_running; then
    if pavucontrol_visible_here; then
      kill_pavucontrol
      exit 0
    fi

    # Not visible here. If last-known ws matches current, treat as stale -> kill only.
    local cur_id saved_id
    cur_id="$(cur_ws_id || true)"
    saved_id="$(state_ws_id || true)"

    if [[ -n "${saved_id:-}" && -n "${cur_id:-}" && "$saved_id" == "$cur_id" ]]; then
      kill_pavucontrol
      exit 0
    fi

    kill_pavucontrol
    launch_pavucontrol
  else
    launch_pavucontrol
  fi
}

main
