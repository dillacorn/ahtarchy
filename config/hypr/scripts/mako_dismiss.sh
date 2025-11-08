#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/mako_dismiss.sh

# Purpose: dismiss mako without leaving the cursor "stuck" in some games
# Requires: makoctl, jq, hyprctl

set -euo pipefail

# current cursor position
read -r CX CY < <(hyprctl -j cursorpos | jq -r '"\(.x) \(.y)"')

# move cursor to a corner to force a redraw in Hyprland
# https://wiki.hypr.land/Configuring/Dispatchers/ (movecursortocorner) :contentReference[oaicite:0]{index=0}
hyprctl dispatch movecursortocorner 2

# dismiss the last notification
# mako 1.x ships makoctl; if you renamed it, fix this line
makoctl dismiss

# put cursor back where it was
hyprctl dispatch movecursor "$CX" "$CY"
