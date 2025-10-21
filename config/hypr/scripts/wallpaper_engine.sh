#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/wallpaper_engine.sh

set -euo pipefail

command -v linux-wallpaperengine >/dev/null
command -v hyprctl >/dev/null
command -v jq >/dev/null

# Map outputs -> Workshop IDs or absolute paths
declare -A WALLS=(
  ["DP-3"]="3506463892"
  ["DP-1"]="3506481306"
  # ["DP-3"]="3493652949"  # only if actually downloaded
)

# Optional override if you know it:
# export WE_WORKSHOP_DIR="/games/SteamLibrary/steamapps/workshop/content/431960"

# --- locate workshop dir for app 431960 ---
find_workshop_dir() {
  # explicit override
  if [[ -n "${WE_WORKSHOP_DIR:-}" ]]; then
    [[ -d "$WE_WORKSHOP_DIR" ]] && { echo "$WE_WORKSHOP_DIR"; return 0; }
  fi

  # fast candidates
  local c=(
    "$HOME/.local/share/Steam/steamapps/workshop/content/431960"
    "$HOME/.steam/steam/steamapps/workshop/content/431960"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
    "/games/SteamLibrary/steamapps/workshop/content/431960"
  )
  for p in "${c[@]}"; do
    [[ -d "$p" ]] && { echo "$p"; return 0; }
  done

  # broader search
  local bases=(
    "$HOME/.local/share/Steam"
    "$HOME/.steam/steam"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
    "/games/SteamLibrary"
    "/run/media/$USER"
    "/media/$USER"
    "/mnt"
  )
  for b in "${bases[@]}"; do
    [[ -d "$b" ]] || continue
    local d
    d="$(find "$b" -maxdepth 5 -type d -path '*/steamapps/workshop/content/431960' 2>/dev/null | head -n1 || true)"
    [[ -n "$d" ]] && { echo "$d"; return 0; }
  done

  return 1
}

WORKSHOP_DIR="$(find_workshop_dir || true)"

# Kill other drawers and stale instances (optional)
pkill -x swww hyprpaper waypaper 2>/dev/null || true
pkill -x linux-wallpaperengine 2>/dev/null || true

# Build single-process args
args=(linux-wallpaperengine --fps 30 --scaling fill)
[[ -n "$WORKSHOP_DIR" ]] && args+=(--workshop-dir "$WORKSHOP_DIR")

# Append each configured output
while read -r out; do
  id="${WALLS[$out]:-}"
  [[ -z "$id" ]] && continue

  # If numeric ID, ensure it exists when we know WORKSHOP_DIR
  if [[ -n "$WORKSHOP_DIR" && "$id" =~ ^[0-9]+$ ]]; then
    if [[ ! -d "$WORKSHOP_DIR/$id" ]]; then
      echo "ERROR: $id not found under $WORKSHOP_DIR (output $out). Make sure it’s downloaded." >&2
      exit 1
    fi
  fi

  args+=(--screen-root "$out" --bg "$id")
done < <(hyprctl -j monitors | jq -r '.[].name')

echo "Running with: ${args[*]}"
exec "${args[@]}"
