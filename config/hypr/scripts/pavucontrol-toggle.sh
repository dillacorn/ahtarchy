#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/pavucontrol-toggle.sh

# Toggle pavucontrol without killing tiled windows. Fast, single snapshot.

set -euo pipefail

WM_CLASS="org.pulseaudio.pavucontrol"
PROC_NAME="pavucontrol"

kill_list() {
  mapfile -t pids
  [ "${#pids[@]}" -gt 0 ] || return 0
  kill -TERM "${pids[@]}" 2>/dev/null || true
  kill -KILL "${pids[@]}" 2>/dev/null || true
}

launch_new() {
  if command -v dbus-run-session >/dev/null 2>&1; then
    dbus-run-session -- "$PROC_NAME" >/dev/null 2>&1 &
  else
    "$PROC_NAME" >/dev/null 2>&1 &
  fi
}

ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r 'try .id // 0')"
clients="$(hyprctl clients -j 2>/dev/null || printf '[]')"

here_float="$(printf '%s' "$clients" | jq -r --arg c "$WM_CLASS" --argjson ws "$ws" '
  .[]? | select(.class==$c and (.floating//false)==true and (.hidden//false)==false and (.workspace.id//-1)==$ws) | .pid
')"

elsewhere_float="$(printf '%s' "$clients" | jq -r --arg c "$WM_CLASS" --argjson ws "$ws" '
  .[]? | select(.class==$c and (.floating//false)==true and ((.workspace.id//-1)!=$ws or (.hidden//false)==true)) | .pid
')"

if [ -n "$here_float" ]; then
  printf '%s\n' "$here_float" | kill_list
  exit 0
fi

if [ -n "$elsewhere_float" ]; then
  printf '%s\n' "$elsewhere_float" | kill_list
  launch_new
  exit 0
fi

launch_new
