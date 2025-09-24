#!/usr/bin/env bash
# ~/.config/hypr/scripts/screenshot_area.sh
# deps: grim slurp satty hyprctl (Hyprland)

set -euo pipefail

# Preserve/forward Hyprland activation so Satty gets focus
ACTIVATION_TOKEN="${XDG_ACTIVATION_TOKEN:-}"

# 1) Select region; exit cleanly if cancelled
GEOM="$(slurp -b '#ffffff20' -c '#00000040' || true)"
[ -z "$GEOM" ] && exit 0

# 2) Paths
out_dir="$HOME/Pictures/Screenshots"
mkdir -p "$out_dir"
png_path="$out_dir/$(date +%m%d%Y-%I%p-%S).png"
tmp_ppm="$(mktemp --suffix=.ppm)"

# 3) Capture quickly to file (avoid stdin pipe focus race)
grim -g "$GEOM" -t ppm "$tmp_ppm"

# 4) Hand focus to Satty by spawning via Hyprland; keep Satty at DEFAULT settings.
#    Only hide toolbars on spawn; DO NOT set early-exit or custom keybinds.
[ -n "$ACTIVATION_TOKEN" ] && export XDG_ACTIVATION_TOKEN="$ACTIVATION_TOKEN"
sleep 0.02

hyprctl dispatch exec "satty \
  --filename '$tmp_ppm' \
  --output-filename '$png_path' \
  --default-hide-toolbars"

# 5) Wait for Satty to exit, then clean up temp
while pgrep -x satty >/dev/null; do sleep 0.1; done
rm -f "$tmp_ppm"
