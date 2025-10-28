#!/usr/bin/env bash
set -euo pipefail

WM_CLASS="maccel"

command -v hyprctl >/dev/null 2>&1 || { echo "hyprctl not found" >&2; exit 1; }

if ! command -v maccel >/dev/null 2>&1; then
    hyprctl notify -1 5000 "rgb(ff0000)" "maccel not found in PATH"
    exit 1
fi

active_ws="$(hyprctl activeworkspace -j | jq -r '.id')"

# find floating maccel window
addr="$(hyprctl clients -j | jq -r --arg c "$WM_CLASS" --arg ws "$active_ws" '
  .[]? | select((.class==$c or .initialClass==$c) and .floating==true and (.workspace.id | tostring)==$ws) | .address
' | head -n1 || true)"

if [ -z "${addr:-}" ] || [ "$addr" = "null" ]; then
    # no floating maccel on current workspace -> spawn
    alacritty --class maccel -e maccel &
    exit 0
fi

# floating maccel exists on current workspace -> close it
hyprctl dispatch closewindow "address:$addr"
