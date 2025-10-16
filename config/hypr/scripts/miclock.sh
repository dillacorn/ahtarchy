#!/usr/bin/env bash
# ~/.config/hypr/scripts/miclock.sh
# Keep ONLY the default microphone locked at 100%.
# Event-driven via `pactl subscribe`. No polling. CPU-light.

set -Eeuo pipefail

TARGET_PERCENT=100        # 0..153 (PipeWire allows >100)
DEBOUNCE_MS=120           # ignore our own set-events for this long

now_ms() { date +%s%3N; }
log()    { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }

wait_for_audio() {
  local i=0
  until pactl info >/dev/null 2>&1; do
    (( i++ == 0 )) && log "Waiting for pulse/pipewire..."
    sleep 0.5
  done
}

force_lock() {
  # Always act on the default source token to avoid index/name churn
  pactl set-source-mute   @DEFAULT_SOURCE@ 0 || true
  pactl set-source-volume @DEFAULT_SOURCE@ "${TARGET_PERCENT}%" || true
  log "Mic locked to ${TARGET_PERCENT}%"
}

LAST_SET_MS=0
maybe_lock() {
  local now; now="$(now_ms)"
  if (( now - LAST_SET_MS < DEBOUNCE_MS )); then
    return 0
  fi
  force_lock
  LAST_SET_MS="$(now_ms)"
}

watch_events() {
  # React to: default source switch (server), source volume/prop changes (source),
  # hardware churn (card), and capture stream churn (source-output).
  if command -v stdbuf >/dev/null 2>&1; then
    while IFS= read -r line; do
      case "$line" in
        *" on source "*|*" on server"*|*" on card "*|*" on source-output "*) maybe_lock ;;
        *) : ;;
      esac
    done < <(stdbuf -oL -eL pactl subscribe 2>/dev/null)
  else
    while IFS= read -r line; do
      case "$line" in
        *" on source "*|*" on server"*|*" on card "*|*" on source-output "*) maybe_lock ;;
        *) : ;;
      esac
    done < <(pactl subscribe 2>/dev/null)
  fi
}

main() {
  trap 'exit 0' INT TERM
  wait_for_audio

  # Hard-set once at startup.
  force_lock
  LAST_SET_MS="$(now_ms)"

  # Event loop with auto-restart.
  while true; do
    watch_events || true
    log "Event stream ended; restarting in 1s..."
    sleep 1
  done
}

main
