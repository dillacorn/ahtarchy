#!/usr/bin/env bash
set -euo pipefail

# Optional: pin a display. Use exactly one token, e.g. "--bus=5"
: "${DDCUTIL_BUS:=}"

BR_FILE="/tmp/brightness_level"

# Save current brightness (best effort)
timeout 2 ddcutil ${DDCUTIL_BUS:+$DDCUTIL_BUS} getvcp 0x10 2>/dev/null \
  | awk -F'current value = ' 'NF>1{print $2}' \
  | awk -F',' '{print $1}' \
  | tr -dc '0-9' > "${BR_FILE}" || true

# Dim to 20 with one retry
if ! timeout 3 ddcutil ${DDCUTIL_BUS:+$DDCUTIL_BUS} setvcp 0x10 20 >/dev/null 2>&1; then
  sleep 0.35
  timeout 3 ddcutil ${DDCUTIL_BUS:+$DDCUTIL_BUS} setvcp 0x10 20 >/dev/null 2>&1 || true
fi
