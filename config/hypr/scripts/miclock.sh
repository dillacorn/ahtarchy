#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/miclock.sh

# Keep ONLY the default microphone at 100%. Event-driven. No polling.

set -Eeuo pipefail

# ===== CONFIG =====
TARGET_PERCENT=100     # 0..153 (PipeWire allows >100)
CLAMP_STREAMS=0        # 1 = also force per-app capture streams to 100
# ===================

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }

wait_for_audio() {
  until pactl info >/dev/null 2>&1; do
    sleep 0.5
  done
}

lock_device() {
  pactl set-source-mute   @DEFAULT_SOURCE@ 0 || true
  pactl set-source-volume @DEFAULT_SOURCE@ "${TARGET_PERCENT}%" || true
}

lock_streams() {
  [[ "$CLAMP_STREAMS" -eq 1 ]] || return 0
  pactl list short source-outputs 2>/dev/null | awk '{print $1}' | while read -r id; do
    pactl set-source-output-volume "$id" "${TARGET_PERCENT}%" || true
  done
}

watch_events() {
  # Any source/server/card/source-output change -> reset device (and streams if enabled).
  # shellcheck disable=SC1090,SC2094
  while IFS= read -r line; do
    case "$line" in
      *" on source "*|*" on server"*|*" on card "*|*" on source-output "*)
        lock_device
        lock_streams
        ;;
      *) : ;;
    esac
  done < <(stdbuf -oL -eL pactl subscribe 2>/dev/null)
}

main() {
  trap 'exit 0' INT TERM
  wait_for_audio
  lock_device
  lock_streams
  while true; do
    watch_events || true
    log "event stream ended; restarting"
    sleep 1
  done
}

main
