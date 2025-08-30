# ~/.config/hypr/scripts/toggle_resize_if_ok.sh
#!/usr/bin/env bash
set -euo pipefail

# Block if no active window
aw="$(hyprctl -j activewindow 2>/dev/null || echo null)"
[[ "$aw" == "null" || -z "$aw" ]] && exit 0

# Block if the active window is fullscreen (covers old/new Hyprland JSON)
# - Some versions expose .fullscreen as bool
# - Others expose .fullscreen as an int (0..3)
# - Newer expose .fullscreenstate.{internal,client}
if printf '%s' "$aw" | jq -e '
  (.fullscreen == true)
  or ((.fullscreen? | numbers) > 0)
  or ((.fullscreenstate?.internal? // 0) > 0)
  or ((.fullscreenstate?.client?   // 0) > 0)
' >/dev/null; then
  exit 0
fi

# Get active workspace id
ws_id="$(hyprctl -j activeworkspace | jq -r '.id')"

# Count windows on the active workspace
count="$(hyprctl -j clients | jq --argjson ws "$ws_id" '[.[] | select(.workspace.id == $ws)] | length')"

# Block if 0 or 1 window present
[[ "${count:-0}" -le 1 ]] && exit 0

# Enter resize submap
hyprctl dispatch submap resize
