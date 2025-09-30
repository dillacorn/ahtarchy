#!/usr/bin/env bash
# ~/.config/hypr/scripts/swww-wallpaper.sh
# Start swww-daemon if needed, then set the wallpaper.
# First boot: apply DEFAULT_WALLPAPER once and record it.
# Later boots: restore from last cache; else from Waytrogen; else from current swww; else fallback to DEFAULT.

set -euo pipefail

# --- Config ---
CACHE_DIR="$HOME/.cache"
LAST_CACHE="$CACHE_DIR/last_wallpaper"
FIRST_RUN_FLAG="$CACHE_DIR/swww_first_run"
DEFAULT_WALLPAPER="$HOME/Pictures/wallpapers/arch_geology.png"

mkdir -p "$CACHE_DIR"

# --- Ensure swww-daemon is running (do not touch Wayland sockets) ---
if ! pgrep -x swww-daemon >/dev/null; then
  swww-daemon >/dev/null 2>&1 &
  sleep 0.3
fi

# --- Helpers ---
set_wallpaper() {
  local img="$1"
  [[ -f "$img" ]] || return 1
  # Do not override transitions here; let swww/Waytrogen prefs handle that.
  swww img "$img" >/dev/null 2>&1 || return 1
  printf '%s\n' "$img" >"$LAST_CACHE"
  return 0
}

pick_from_waytrogen() {
  # Use Waytrogen’s saved-wallpapers (first .path) if present
  command -v dconf >/dev/null || return 1
  local raw path
  raw="$(dconf read /org/Waytrogen/Waytrogen/saved-wallpapers 2>/dev/null || true)"
  [[ -n "$raw" ]] || return 1
  raw="${raw#\'}"; raw="${raw%\'}"                      # trim surrounding single quotes
  path="$(printf '%s' "$raw" | grep -oE '"path":"[^"]+"' | head -n1 | cut -d'"' -f4 || true)"
  [[ -n "${path:-}" ]] || return 1
  path="${path/#\~/$HOME}"                              # expand ~
  [[ -f "$path" ]] || return 1
  printf '%s\n' "$path"
}

pick_from_swww_current() {
  # Whatever swww says it is currently showing
  local cur
  cur="$(swww query 2>/dev/null | sed -n 's/.*currently displaying: image: \(.*\)$/\1/p' | head -n1 || true)"
  [[ -n "${cur:-}" && -f "$cur" ]] || return 1
  printf '%s\n' "$cur"
}

# --- First run logic ---
if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
  if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    set_wallpaper "$DEFAULT_WALLPAPER" || true
  fi
  : >"$FIRST_RUN_FLAG"
  exit 0
fi

# --- Subsequent runs: priority chain ---
# 1) last_wallpaper cache
if [[ -s "$LAST_CACHE" ]]; then
  last="$(<"$LAST_CACHE")"
  if set_wallpaper "$last"; then
    exit 0
  fi
fi

# 2) Waytrogen saved-wallpapers (dconf)
if img="$(pick_from_waytrogen)"; then
  if set_wallpaper "$img"; then
    exit 0
  fi
fi

# 3) Whatever swww is currently showing
if img="$(pick_from_swww_current)"; then
  if set_wallpaper "$img"; then
    exit 0
  fi
fi

# 4) Fallback to default (only if it exists)
[[ -f "$DEFAULT_WALLPAPER" ]] && set_wallpaper "$DEFAULT_WALLPAPER" || true
exit 0
