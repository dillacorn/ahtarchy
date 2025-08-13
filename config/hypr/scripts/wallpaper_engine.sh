#!/usr/bin/env bash
set -euo pipefail

# Hard deps
command -v linux-wallpaperengine >/dev/null
command -v hyprctl >/dev/null
command -v jq >/dev/null

# Optional: if your Steam library is nonstandard, set this to .../steamapps/workshop/content/431960
# export WE_WORKSHOP_DIR="/games/SteamLibrary/steamapps/workshop/content/431960"

# Map outputs -> Workshop IDs or paths
declare -A WALLS=(
  ["DP-3"]="3506481306"  # incompatible scenes will simply fail to render
  ["DP-1"]="3506481306"
)

# Kill other background drawers (optional) and stale engine instances (prevents duplicates)
pkill -x swww hyprpaper waypaper 2>/dev/null || true
pkill -x linux-wallpaperengine 2>/dev/null || true

# Build a single linux-wallpaperengine invocation
args=(linux-wallpaperengine --fps 30 --scaling fill)
[[ -n "${WE_WORKSHOP_DIR:-}" ]] && args+=(--workshop-dir "$WE_WORKSHOP_DIR")

while read -r out; do
  id="${WALLS[$out]:-}"
  [[ -n "$id" ]] || continue
  args+=(--screen-root "$out" --bg "$id")
done < <(hyprctl -j monitors | jq -r '.[].name')

exec "${args[@]}"

# To test a wallpaper manually on one output:
# linux-wallpaperengine --fps 30 --scaling fill --screen-root DP-1 --bg 3506481306
