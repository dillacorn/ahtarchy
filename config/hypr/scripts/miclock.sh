#!/usr/bin/env bash
# ~/.config/hypr/scripts/miclock.sh
#
# Event-driven mic volume lock for PipeWire/PulseAudio via pactl.
# No polling. Reacts only to server/source/source-output events.
#
# Hyprland:
#   exec-once = ~/.config/hypr/scripts/miclock.sh &
#
# Dependencies:
#   - pactl (from pulseaudio-utils or pipewire-pulse clients)
#
# Verify default source:
#   pactl get-default-source
# List sources:
#   pactl list short sources

set -Eeuo pipefail

# ===== CONFIG =====
# Global fallback percent if no per-device rule matches. Integer 0..153.
DEFAULT_PERCENT=100

# Also set per-stream capture volumes to match the device percent. 0=off, 1=on.
NORMALIZE_STREAMS=0

# Debounce window to ignore cascaded events after we set volume (milliseconds).
DEBOUNCE_MS=200

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

now_ms() { date +%s%3N; }

clamp_percent() {
  # Clamp to 0..153 (PipeWire allows >100, PulseAudio caps at 100)
  local p="$1"
  (( p < 0 )) && p=0
  (( p > 153 )) && p=153
  printf '%s\n' "$p"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

get_default_source() {
  # Prefer modern pactl
  if have_cmd pactl && pactl --help 2>&1 | grep -q 'get-default-source'; then
    pactl get-default-source 2>/dev/null || true
    return
  fi
  # Fallback: parse pactl info
  pactl info 2>/dev/null | awk -F': ' '/Default Source:/{print $2; exit}'
}

enforce_device_volume() {
  local src pct
  src="$(get_default_source)"
  if [[ -z "$src" ]]; then
    log "No default source detected."
    return 0
  fi
  pct="$(pick_percent "$src")"
  pct="$(clamp_percent "$pct")"

  # Best-effort unmute then set volume
  pactl set-source-mute   "$src" 0 || true
  pactl set-source-volume "$src" "${pct}%"

  log "Locked mic: $src -> ${pct}%"
}

normalize_source_outputs() {
  [[ "$NORMALIZE_STREAMS" == "1" ]] || return 0
  local src pct
  src="$(get_default_source)"
  [[ -n "$src" ]] || return 0
  pct="$(pick_percent "$src")"
  pct="$(clamp_percent "$pct")"

  # Align active capture streams with target percent (best-effort)
  pactl list short source-outputs 2>/dev/null | awk '{print $1}' | while read -r soid; do
    pactl set-source-output-volume "$soid" "${pct}%" || true
  done
}

wait_for_audio() {
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
  #
  # Only standard output is read. stdbuf keeps it line-buffered.
  stdbuf -oL -eL pactl subscribe 2>/dev/null \
  | grep --line-buffered -Ei "^(Event '.+' on (server|source|source-output))" \
  | while IFS= read -r line; do
      on_event "$line"
    done
}

# Debounce bookkeeping
LAST_SET_MS=0
mark_set() { LAST_SET_MS="$(now_ms)"; }
recent_set() {
  local t_now t_last
  t_now="$(now_ms)"
  t_last="${LAST_SET_MS:-0}"
  (( t_now - t_last < DEBOUNCE_MS ))
}

on_event() {
  local line="$1"
  # If we just set volumes, ignore immediate cascaded events
  if recent_set; then
    return 0
  fi
  case "$line" in
    *"on source-output"*)
      normalize_source_outputs
      ;;
    *)
      enforce_device_volume
      normalize_source_outputs
      ;;
  esac
  mark_set
}

main() {
  trap 'exit 0' INT TERM
  wait_for_audio

  # Initial enforcement at startup
  enforce_device_volume
  normalize_source_outputs
  mark_set

  # Keep the event watcher alive, auto-restart if it ever exits
  while true; do
    watch_events || true
    log "Event stream ended; restarting in 1s..."
    sleep 1
  done
}

main
