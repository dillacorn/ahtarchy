#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/restore_brightness.sh

set -euo pipefail

# Optional: pin a display. Use exactly one token, e.g. "--bus=5"
# Export in your environment or set here. Leave empty to auto-select.
: "${DDCUTIL_BUS:=}"

BR_FILE="/tmp/brightness_level"
DEFAULT_BRIGHTNESS="70"

# Ensure panel is awake after unlock, then give it a moment
hyprctl dispatch dpms on >/dev/null 2>&1 || true
sleep 0.6

# Read saved brightness with validation
if [[ -r "${BR_FILE}" ]]; then
  BRIGHTNESS="$(tr -dc '0-9' < "${BR_FILE}")"
else
  BRIGHTNESS=""
fi
if [[ -z "${BRIGHTNESS}" || "${BRIGHTNESS}" -lt 0 || "${BRIGHTNESS}" -gt 100 ]]; then
  BRIGHTNESS="${DEFAULT_BRIGHTNESS}"
fi

# Restore with one retry; quote all expansions
if ! timeout 3 ddcutil ${DDCUTIL_BUS:+$DDCUTIL_BUS} setvcp 0x10 "${BRIGHTNESS}" >/dev/null 2>&1; then
  sleep 0.35
  timeout 3 ddcutil ${DDCUTIL_BUS:+$DDCUTIL_BUS} setvcp 0x10 "${BRIGHTNESS}" >/dev/null 2>&1 || true
fi
