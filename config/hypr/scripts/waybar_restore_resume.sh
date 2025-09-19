#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="/tmp/waybar.state"

# Only relaunch if it was running before idle and it's not already running now
if [[ "$(cat "${STATE_FILE}" 2>/dev/null || true)" == "running" ]]; then
  if ! pgrep -x waybar >/dev/null 2>&1; then
    setsid nohup waybar >/dev/null 2>&1 &
  fi
fi
