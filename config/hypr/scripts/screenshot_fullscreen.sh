#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/screenshot_fullscreen.sh

GEOM=$(slurp -o -r -c '#00000000')
[ -z "$GEOM" ] && exit 1

grim -g "$GEOM" -t ppm - | satty \
  --filename - \
  --fullscreen \
  --output-filename "$HOME/Pictures/Screenshots/$(date +%m%d%Y-%I%p-%S).png"
