#!/usr/bin/env bash
# ~/.config/hypr/scripts/splitratio_steam.sh
# Wait for Steam main + Friends once, apply split, exit.
# Deps: hyprctl, jq
set -euo pipefail

POLL="1.0"       # seconds between checks while waiting
SPLIT="0.35"      # ~65% Steam / 35% Friends
MAX_WAIT="300"    # total seconds to wait before giving up
DEBUG="${DEBUG:-0}"

log() { [ "$DEBUG" -eq 1 ] && printf '[splitratio_steam] %s\n' "$*" >&2 || true; }

get_ids() {
  # stdout: steam_id\nfriends_id (or empty lines)
  local steam_id friends_id
  steam_id="$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class=="steam" and .title=="Steam") | .address' | head -n1 || true)"
  friends_id="$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class=="steam" and .title=="Friends List") | .address' | head -n1 || true)"
  printf '%s\n%s\n' "${steam_id:-}" "${friends_id:-}"
}

apply_once() {
  local steam_id="$1" friends_id="$2"
  [ -n "$steam_id" ] && [ -n "$friends_id" ] || return 1
  log "apply: focus Steam=$steam_id split=$SPLIT then focus Friends=$friends_id move right"
  hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
  hyprctl dispatch splitratio "$SPLIT"           >/dev/null 2>&1 || true
  hyprctl dispatch focuswindow "address:$friends_id" >/dev/null 2>&1 || true
  hyprctl dispatch movewindow workspace active   >/dev/null 2>&1 || true
  hyprctl dispatch movewindow right              >/dev/null 2>&1 || true
  return 0
}

main() {
  local start ts elapsed ids steam_id friends_id
  start="$(date +%s)"

  # Optional: if both windows already exist, act immediately.
  ids="$(get_ids)"; steam_id="$(printf '%s\n' "$ids" | sed -n '1p')"; friends_id="$(printf '%s\n' "$ids" | sed -n '2p')"
  if apply_once "$steam_id" "$friends_id"; then exit 0; fi

  # Wait up to MAX_WAIT for both windows, then apply and exit. No re-arm.
  while :; do
    ids="$(get_ids)"
    steam_id="$(printf '%s\n' "$ids" | sed -n '1p')"
    friends_id="$(printf '%s\n' "$ids" | sed -n '2p')"

    if [ -n "$steam_id" ] && [ -n "$friends_id" ]; then
      sleep 0.10  # settle
      apply_once "$steam_id" "$friends_id" && exit 0
    fi

    sleep "$POLL"
    ts="$(date +%s)"; elapsed="$(( ts - start ))"
    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
      log "timeout after ${MAX_WAIT}s; exiting"
      exit 0
    fi
  done
}

main
