#!/bin/sh
# Persistent runner. One split per Steam run. Re-arms only after Steam fully exits.
# Dependencies: hyprctl, jq

set -eu

POLL="1.0"   # seconds
SPLIT="0.35"  # matches your working script

get_ids() {
  # echoes two lines: steam_id\nfriends_id
  local steam_id friends_id
  steam_id="$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class=="steam" and .title=="Steam") | .address' | head -n1 || true)"
  friends_id="$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class=="steam" and .title=="Friends List") | .address' | head -n1 || true)"
  printf '%s\n%s\n' "${steam_id:-}" "${friends_id:-}"
}

any_steam_present() {
  # 0 = yes, 1 = no
  hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class=="steam")' >/dev/null 2>&1 || return 1
  return 0
}

apply_once() {
  local steam_id="$1" friends_id="$2"

  # Do NOT togglefloating; your working script didn’t and it kept tiling correct.
  hyprctl dispatch focuswindow "address:$steam_id" >/dev/null 2>&1 || true
  hyprctl dispatch splitratio "$SPLIT" >/dev/null 2>&1 || true

  hyprctl dispatch focuswindow "address:$friends_id" >/dev/null 2>&1 || true
  hyprctl dispatch movewindow workspace active >/dev/null 2>&1 || true
  hyprctl dispatch movewindow right >/dev/null 2>&1 || true
}

# --- daemon loop ---
handled=0

while :; do
  if [ "$handled" -eq 0 ]; then
    # Arm: wait until BOTH Steam main and Friends exist, then apply exactly once.
    while [ "$handled" -eq 0 ]; do
      ids="$(get_ids)"
      steam_id="$(printf '%s\n' "$ids" | sed -n '1p')"
      friends_id="$(printf '%s\n' "$ids" | sed -n '2p')"

      if [ -n "$steam_id" ] && [ -n "$friends_id" ]; then
        apply_once "$steam_id" "$friends_id"
        handled=1
        break
      fi

      # If Steam not even present, just idle and keep polling (runner stays alive).
      sleep "$POLL"
    done
  else
    # Disarm: do nothing until ALL Steam windows are gone, then re-arm.
    while [ "$handled" -eq 1 ]; do
      if ! any_steam_present; then
        handled=0
        break
      fi
      sleep "$POLL"
    done
  fi
done
