#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/toggle_animations.sh
# 
# Toggle Hyprland global animations on/off at runtime and send a desktop notification.
# Works without jq; uses JSON if available for robustness.

set -euo pipefail

HYPRCTL="$(command -v hyprctl || true)"
NOTIFY_SEND="$(command -v notify-send || true)"

if [[ -z "$HYPRCTL" ]]; then
  echo "hyprctl not found in PATH" >&2
  exit 1
fi

read_state_json() {
  "$HYPRCTL" getoption "animations:enabled" -j 2>/dev/null \
    | sed -n 's/.*"int":\s*\([0-9]\+\).*/\1/p'
}

read_state_fallback() {
  # Example non-JSON output often includes a line with "int: 1" or similar; extract the first integer.
  "$HYPRCTL" getoption "animations:enabled" 2>/dev/null \
    | awk '{
        for(i=1;i<=NF;i++){
          if ($i ~ /^[0-9]+$/) { print $i; exit }
          if ($i ~ /[0-9]+:/)  { gsub(/[^0-9]/,"",$i); print $i; exit }
        }
      }'
}

state="$(read_state_json || true)"
if [[ -z "${state:-}" ]]; then
  state="$(read_state_fallback || true)"
fi
if [[ -z "${state:-}" ]]; then
  # If still unknown, assume enabled and flip off.
  state="1"
fi

if [[ "$state" == "1" ]]; then
  target="0"
  msg="OFF"
else
  target="1"
  msg="ON"
fi

"$HYPRCTL" keyword "animations:enabled" "$target"

if [[ -n "$NOTIFY_SEND" ]]; then
  # Replace existing notification to avoid stacking
  "$NOTIFY_SEND" -a "Hyprland" \
    -r 49110 \
    "Animations: $msg" \
    "animations:enabled = $target"
fi
