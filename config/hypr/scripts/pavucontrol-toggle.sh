#!/usr/bin/env bash
# ~/.config/hypr/scripts/pavucontrol-toggle.sh
# Toggle pavucontrol with workspace awareness while NEVER killing tiled windows.
# Requirements: hyprctl, jq, pgrep, pkill, nohup
#
# Semantics:
# 1) If any FLOATING pavucontrol exists on CURRENT workspace -> kill ONLY those (toggle off) and exit.
# 2) Else if any FLOATING pavucontrol exists on OTHER workspaces -> kill them, then launch here (toggle here).
# 3) Else (no floating anywhere) -> launch here, even if there is a TILED one on this workspace.
#
# Multiple instances:
# - pavucontrol is usually single-instance via D-Bus. To guarantee a new window even when one exists,
#   this script runs it in its own temporary D-Bus session: `dbus-run-session -- pavucontrol`.
# - Disable that behavior by exporting FORCE_NEW_INSTANCE=0 before calling the script.

set -euo pipefail

quiet() { "$@" 2>/dev/null; }

need() { command -v "$1" >/dev/null 2>&1; }
for bin in hyprctl jq pgrep pkill nohup; do
  need "$bin" || { echo "Missing dependency: $bin" >&2; exit 1; }
done

PROC_NAME="pavucontrol"
WM_CLASS="org.pulseaudio.pavucontrol"
FORCE_NEW_INSTANCE="${FORCE_NEW_INSTANCE:-1}"  # 1 -> launch via dbus-run-session to force a new window

is_running() { pgrep -x "$PROC_NAME" >/dev/null; }

cur_ws_id() { quiet hyprctl activeworkspace -j | quiet jq -r 'try .id // empty'; }

# PIDs of FLOATING pavucontrol windows on a given workspace
pids_floating_on_ws() {
  local ws="$1"
  [ -n "$ws" ] || return 0
  quiet hyprctl clients -j | quiet jq -r --arg cls "$WM_CLASS" --argjson ws "$ws" '
    .[]?
    | select(.class == $cls and (.floating // false) == true and (.workspace.id // -1) == $ws)
    | .pid
  '
}

# PIDs of FLOATING pavucontrol windows NOT on the given workspace
pids_floating_elsewhere() {
  local ws="$1"
  quiet hyprctl clients -j | quiet jq -r --arg cls "$WM_CLASS" --argjson ws "$ws" '
    .[]?
    | select(.class == $cls and (.floating // false) == true and (.workspace.id // -1) != $ws)
    | .pid
  '
}

kill_pids() {
  local p
  for p in "$@"; do
    [ -n "${p:-}" ] || continue
    kill -TERM "$p" 2>/dev/null || true
  done
  for _ in $(seq 1 50); do
    local any=0
    for p in "$@"; do
      if kill -0 "$p" 2>/dev/null; then any=1; fi
    done
    [ $any -eq 0 ] && break
    sleep 0.02
  done
  for p in "$@"; do
    kill -KILL "$p" 2>/dev/null || true
  done
}

launch_here() {
  # Force a genuinely new window even if pavucontrol is single-instance.
  if [ "${FORCE_NEW_INSTANCE}" = "1" ]; then
    nohup dbus-run-session -- "$PROC_NAME" >/dev/null 2>&1 &
  else
    nohup "$PROC_NAME" >/dev/null 2>&1 &
  fi
}

main() {
  local ws
  ws="$(cur_ws_id || true)"

  # 1) Toggle off: kill ONLY floating instances on the current workspace
  mapfile -t here < <(pids_floating_on_ws "${ws:-}" || true)
  if [ "${#here[@]}" -gt 0 ]; then
    kill_pids "${here[@]}"
    exit 0
  fi

  # 2) If there are floating instances elsewhere, replace them with one here
  mapfile -t elsewhere < <(pids_floating_elsewhere "${ws:-}" || true)
  if [ "${#elsewhere[@]}" -gt 0 ]; then
    kill_pids "${elsewhere[@]}"
    launch_here
    exit 0
  fi

  # 3) No floating anywhere. Launch here regardless of any tiled windows.
  launch_here
}

main
