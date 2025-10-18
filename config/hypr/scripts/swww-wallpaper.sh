#!/usr/bin/env bash
# ~/.config/hypr/scripts/swww-wallpaper.sh
# Start swww-daemon if needed, then restore the LAST wallpaper chosen via Waytrogen.
# No cache files. No "last_wallpaper". First run uses DEFAULT_WALLPAPER once.

set -euo pipefail

# --- Config ---
FIRST_RUN_FLAG="$HOME/.cache/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/autarchy_geology.png"

mkdir -p "$(dirname "$FIRST_RUN_FLAG")"

# --- Ensure swww-daemon is running (do not touch Wayland sockets) ---
if ! pgrep -x swww-daemon >/dev/null; then
  swww-daemon >/dev/null 2>&1 &
  sleep 0.3
fi

# --- Helpers ---
set_wallpaper() {
  local img="$1"
  [[ -f "$img" ]] || return 1
  # Do not override transitions; let swww/Waytrogen prefs handle that.
  swww img "$img" >/dev/null 2>&1
}

# 1) Waytrogen live state (what it last applied; lightweight and accurate)
pick_from_waytrogen_live() {
  command -v waytrogen >/dev/null || return 1
  local p
  p="$(waytrogen -l 2>/dev/null | sed -n 's/.*"path":"\([^"]\+\)".*/\1/p' | head -n1 || true)"
  [[ -n "$p" && -f "$p" ]] || return 1
  printf '%s\n' "$p"
}

# 2) Waytrogen saved state in dconf (what --restore would use)
pick_from_waytrogen_saved() {
  command -v dconf >/dev/null || return 1
  local raw path
  raw="$(dconf read /org/Waytrogen/Waytrogen/saved-wallpapers 2>/dev/null || true)"
  [[ -n "$raw" ]] || return 1
  raw="${raw#\'}"; raw="${raw%\'}"
  path="$(printf '%s' "$raw" | grep -oE '"path":"[^"]+"' | head -n1 | cut -d'"' -f4 || true)"
  [[ -n "${path:-}" ]] || return 1
  path="${path/#\~/$HOME}"
  [[ -f "$path" ]] || return 1
  printf '%s\n' "$path"
}

# 3) Whatever swww is currently drawing (as a last resort on subsequent runs)
pick_from_swww_current() {
  local cur
  cur="$(swww query 2>/dev/null | sed -n 's/.*currently displaying: image: \(.*\)$/\1/p' | head -n1 || true)"
  [[ -n "${cur:-}" && -f "$cur" ]] || return 1
  printf '%s\n' "$cur"
}

# --- First run: force default once (if present), then stop ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
  [[ -f "$DEFAULT_WALLPAPER" ]] && set_wallpaper "$DEFAULT_WALLPAPER" || true
  : >"$FIRST_RUN_FLAG"
  exit 0
fi

# --- Subsequent runs: Waytrogen → dconf → swww → default ---
if img="$(pick_from_waytrogen_live)"; then
  set_wallpaper "$img" && exit 0
fi

if img="$(pick_from_waytrogen_saved)"; then
  set_wallpaper "$img" && exit 0
fi

if img="$(pick_from_swww_current)"; then
  set_wallpaper "$img" && exit 0
fi

[[ -f "$DEFAULT_WALLPAPER" ]] && set_wallpaper "$DEFAULT_WALLPAPER" || true
exit 0
