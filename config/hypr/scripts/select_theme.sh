#!/bin/bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/select_theme.sh

THEME_DIR="$HOME/.config/hypr/themes"

# Find executable files (not directories), get their names only, send list to wofi menu
THEME=$(find "$THEME_DIR" -maxdepth 1 -type f -executable -exec basename {} \; | wofi --dmenu -i -p "Choose theme")

# If user picked something (non-empty), run it
if [ -n "$THEME" ]; then
    "$THEME_DIR/$THEME"
fi
