#!/usr/bin/env bash
# miclock.sh — event-driven mic volume lock for PipeWire/PulseAudio (no systemd)
# Launch from Hyprland:
#   exec-once = ~/.config/hypr/scripts/miclock.sh &
#
# Dependencies: pactl (pipewire-pulse or pulseaudio clients)
# Verify default source name: pactl get-default-source
# List sources:              pactl list short sources

set -Eeuo pipefail

# ===== CONFIG =====
# Global fallback percent if no per-device rule matches. Integer 0..153.
DEFAULT_PERCENT=100

# Optional periodic enforcement (seconds). 0 disables.
POLL_SEC=0

# Also set per-stream capture volumes to match the device percent. 0=off, 1=on.
NORMALIZE_STREAMS=0

# Map default source NAME to a percent. First match wins.
pick_percent() {
  local src="$1"
  case "$src" in
    # Examples. Uncomment and edit as needed:
    # *usb-Blue_Snowball*) echo 85; return ;;     # 85% for Blue Snowball
    # *analog-stereo*)     echo 100; return ;;    # 100% for onboard analog
    # *usb-Scarlett*)      echo 90; return ;;
    *) echo "$DEFAULT_PERCENT"; return ;;
  esac
}
# ===================

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; } >&2

clamp_percent() {
  # Clamp to 0..153 (PipeWire allows >100, PulseAudio caps at 100)
  local p="$1"
  (( p < 0 )) && p=0
  (( p > 153 )) && p=153
  printf '%s\n' "$p"
}

enforce_device_volume() {
  local src pct
  src="$(pactl get-default-source 2>/dev/null || true)"
  if [[ -z "$src" ]]; then
    log "No default source detected."
    return 0
  fi
  pct="$(pick_percent "$src")"
  pct="$(clamp_percent "$pct")"

  # Ensure unmuted then set volume
  pactl set-source-mute   "$src" 0 || true
  pactl set-source-volume "$src" "${pct}%"

  log "Locked mic: $src -> ${pct}%"
}

normalize_source_outputs() {
  [[ "$NORMALIZE_STREAMS" == "1" ]] || return 0
  local src pct
  src="$(pactl get-default-source 2>/dev/null || true)"
  [[ -n "$src" ]] || return 0
  pct="$(pick_percent "$src")"
  pct="$(clamp_percent "$pct")"

  # Align active capture streams with target percent (best-effort)
  pactl list short source-outputs 2>/dev/null | awk '{print $1}' | while read -r soid; do
    pactl set-source-output-volume "$soid" "${pct}%" || true
  done
}

wait_for_audio() {
  # Wait until the server is ready
  local i=0
  until pactl info >/dev/null 2>&1; do
    (( i++ == 0 )) && log "Waiting for pulse/pipewire..."
    sleep 0.5
  done
}

watch_events() {
  # React to:
  #  - server/change     -> default source switch
  #  - source/new/change -> device plug or prop change
  #  - source-output/*   -> app capture streams (optional normalization)
  stdbuf -oL -eL pactl subscribe 2>/dev/null \
  | grep --line-buffered -Ei '^(Event .+ on (server|source|source-output))' \
  | while IFS= read -r line; do
      case "$line" in
        *source-output*) normalize_source_outputs ;;
        *)               enforce_device_volume ;;
      esac
    done
}

poller() {
  # Optional periodic enforcement as a safety net
  [[ "$POLL_SEC" -gt 0 ]] || return 0
  while sleep "$POLL_SEC"; do
    enforce_device_volume
    normalize_source_outputs
  done
}

main() {
  trap 'exit 0' INT TERM
  wait_for_audio
  enforce_device_volume
  normalize_source_outputs

  # Keep the event watcher alive, auto-restart if it ever exits
  poller & local POLLER_PID=$!
  while true; do
    watch_events || true
    log "Event stream ended; restarting in 1s..."
    sleep 1
  done
  wait "$POLLER_PID"
}

main
