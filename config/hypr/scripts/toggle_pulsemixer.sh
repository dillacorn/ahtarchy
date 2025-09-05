# ~/.config/hypr/scripts/toggle_pulsemixer.sh
#!/usr/bin/env bash
set -euo pipefail

# Look for a window with class or title "Pulsemixer"
addr="$(hyprctl -j clients | jq -r '.[] | select(.class=="Pulsemixer" or .initialClass=="Pulsemixer" or .title=="Pulsemixer") | .address' | head -n1)"

if [[ -n "$addr" ]]; then
  # Found one → close it
  hyprctl dispatch closewindow "address:$addr"
  exit 0
fi

# Otherwise spawn a new Alacritty running pulsemixer
alacritty \
  --class Pulsemixer \
  --title Pulsemixer \
  -o window.dynamic_title=false \
  -e pulsemixer &
