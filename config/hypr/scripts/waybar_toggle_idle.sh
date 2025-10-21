#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/waybar_toggle_idle.sh

set -euo pipefail

STATE_FILE="/tmp/waybar.state"

if pgrep -x waybar >/dev/null 2>&1; then
  echo "running" > "${STATE_FILE}"
  pkill -x waybar || true
else
  echo "stopped" > "${STATE_FILE}"
fi
