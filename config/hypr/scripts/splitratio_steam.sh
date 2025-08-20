#!/usr/bin/env bash
# ~/.config/hypr/scripts/splitratio_steam.sh
# Single-run: wait for Steam main + Friends once, ensure Friends is RIGHT, set split, exit.
# Deps: hyprctl, jq
set -euo pipefail

POLL="0.20"       # seconds between checks while waiting
SPLIT="0.35"      # ~65% Steam / 35% Friends
MAX_WAIT="300"    # total seconds to wait before giving up
DEBUG="${DEBUG:-0}"

log() { [ "$DEBUG" -eq 1 ] && printf '[splitratio_steam] %s\n' "$*" >&2 || true; }

get_ids() {
  local steam_id friends_id
  steam_id="$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class=="steam" and .title=="Steam") | .address' | head -n1 || true)"
  friends_id="$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class=="steam" and .title=="Friends List") | .address' | head -n1 || true)"
  printf '%s\n%s\n' "${steam_id:-}" "${friends_id:-}"
}

get_x() {
  hyprctl clients -j 2>/dev/null \
    | jq -r --arg a "$1" '.[] | select(.address==$a) | .at[0]' 2>/dev/null || true
}

same_ws() {
  local a="$1" b="$2" wa wb
  wa="$(hyprctl clients -j 2>/dev/null | jq -r --arg a "$a" '.[] | select(.address==$a) | .workspace.id' || true)"
  wb="$(hyprctl clients -j 2>/dev/null | jq -r --arg b "$b" '.[] | select(.address==$b) | .workspace.id' || true)"
  [[ -n "$wa" && -n "$wb" && "$wa" = "$wb" ]]
}

ensure_tiled_same_ws() {
  local steam_id="$1" friends_id="$2"
  hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
  hyprctl dispatch movewindow workspace active >/dev/null 2>&1 || true
  hyprctl dispatch focuswindow "address:$friends_id" >/dev/null 2>&1 || true
  hyprctl dispatch movewindow workspace active >/dev/null 2>&1 || true

  if ! same_ws "$steam_id" "$friends_id"; then
    hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
    hyprctl dispatch focuswindow "address:$friends_id" >/dev/null 2>&1 || true
    hyprctl dispatch movewindow workspace active >/dev/null 2>&1 || true
  fi
}

ensure_friends_right() {
  local steam_id="$1" friends_id="$2" sx fx i
  for i in {1..5}; do
    sx="$(get_x "$steam_id")"
    fx="$(get_x "$friends_id")"
    [[ -z "$sx" || -z "$fx" ]] && sleep 0.05 && continue

    if (( fx <= sx )); then
      # Try swapsplit (siblings in dwindle)
      hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
      hyprctl dispatch layoutmsg swapsplit >/dev/null 2>&1 || true
      sleep 0.08
      sx="$(get_x "$steam_id")"; fx="$(get_x "$friends_id")"
      if [[ -n "$sx" && -n "$fx" ]] && (( fx > sx )); then return 0; fi

      # Fallback: swap with left neighbor
      hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
      hyprctl dispatch swapwindow l >/dev/null 2>&1 || true
      sleep 0.08
      sx="$(get_x "$steam_id")"; fx="$(get_x "$friends_id")"
      if [[ -n "$sx" && -n "$fx" ]] && (( fx > sx )); then return 0; fi
    else
      return 0
    fi
    sleep 0.05
  done
  return 0
}

apply_once() {
  local steam_id="$1" friends_id="$2"
  [ -n "$steam_id" ] && [ -n "$friends_id" ] || return 1
  ensure_tiled_same_ws "$steam_id" "$friends_id"
  ensure_friends_right "$steam_id" "$friends_id"
  hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
  hyprctl dispatch splitratio "$SPLIT" >/dev/null 2>&1 || true
  return 0
}

main() {
  local start ts elapsed ids steam_id friends_id
  start="$(date +%s)"
  local seen_steam=0

  # Fast path if both present.
  ids="$(get_ids)"
  steam_id="$(printf '%s\n' "$ids" | sed -n '1p')"
  friends_id="$(printf '%s\n' "$ids" | sed -n '2p')"
  if apply_once "$steam_id" "$friends_id"; then exit 0; fi

  # Wait up to MAX_WAIT for both; only allow early exit if Steam was seen and then vanished.
  while :; do
    if pgrep -x steam >/dev/null 2>&1; then
      seen_steam=1
    else
      # If Steam has never been seen yet (startup race), keep waiting.
      if [ "$seen_steam" -eq 1 ]; then
        # Steam started then quit → bail.
        exit 0
      fi
    fi

    ids="$(get_ids)"
    steam_id="$(printf '%s\n' "$ids" | sed -n '1p')"
    friends_id="$(printf '%s\n' "$ids" | sed -n '2p')"

    if [ -n "$steam_id" ] && [ -n "$friends_id" ]; then
      sleep 0.10
      apply_once "$steam_id" "$friends_id" && exit 0
    fi

    sleep "$POLL"
    ts="$(date +%s)"; elapsed="$(( ts - start ))"
    if [ "$elapsed" -ge "$MAX_WAIT" ]; then exit 0; fi
  done
}

main
