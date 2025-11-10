#!/usr/bin/env bash

# github.com/dillacorn/awtarchy/tree/main/config/waybar/scripts
# ~/.config/waybar/scripts/clock_toggle.sh

#   clock_toggle.sh           -> print JSON for current mode
#   clock_toggle.sh toggle    -> flip mode and signal waybar (RTMIN+12)

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="${STATE_DIR}/waybar-clock-mode"
mkdir -p "$STATE_DIR"

if [ "${1:-}" = "toggle" ]; then
  current="time"
  if [ -f "$STATE_FILE" ]; then
    current="$(cat "$STATE_FILE" 2>/dev/null || echo time)"
  fi
  if [ "$current" = "time" ]; then
    echo "date" > "$STATE_FILE"
  else
    echo "time" > "$STATE_FILE"
  fi
  pkill -RTMIN+12 waybar 2>/dev/null || true
  exit 0
fi

mode="time"
if [ -f "$STATE_FILE" ]; then
  mode="$(cat "$STATE_FILE" 2>/dev/null || echo time)"
fi

if [ "$mode" = "time" ]; then
  now_24="$(date +'%H:%M')"
  now_12="$(date +'%I:%M %p')"
  full_date="$(date +'%A, %d, %Y')"
  printf '{"text":" %s","tooltip":"%s\\n24h: %s\\n12h: %s","class":["time"]}\n' \
    "$now_24" "$full_date" "$now_24" "$now_12"
else
  md="$(date +'%m-%d')"
  now_24="$(date +'%H:%M')"
  now_12="$(date +'%I:%M %p')"
  full_date="$(date +'%A, %d, %Y')"
  printf '{"text":" %s","tooltip":"%s\\n24h: %s\\n12h: %s","class":["date"]}\n' \
    "$md" "$full_date" "$now_24" "$now_12"
fi
