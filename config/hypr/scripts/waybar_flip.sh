#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/waybar_flip.sh

set -euo pipefail

cfg="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config"

if [ ! -f "$cfg" ]; then
  echo "waybar_flip: config not found: $cfg" >&2
  exit 1
fi

# Toggle "position": "top" <-> "position": "bottom"
if grep -q '"position": *"top"' "$cfg"; then
  sed -i 's/"position": *"top"/"position": "bottom"/' "$cfg"
elif grep -q '"position": *"bottom"' "$cfg"; then
  sed -i 's/"position": *"bottom"/"position": "top"/' "$cfg"
else
  echo "waybar_flip: no position key found in $cfg" >&2
  exit 1
fi

pkill -x waybar 2>/dev/null || true
nohup waybar >/dev/null 2>&1 &
