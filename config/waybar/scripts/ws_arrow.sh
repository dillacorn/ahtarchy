# FILE: ~/.config/waybar/scripts/ws_arrow.sh
#!/usr/bin/env bash
# PURPOSE: Show ONE arrow only when a neighbor monitor exists in that direction.
# STRATEGY: Poll Hyprland every N seconds via Waybar "interval" (very light).
# ROBUST: Uses active workspace -> monitor name; falls back if "focused" flag is missing.

set -euo pipefail

DIR="${1:-}"
case "$DIR" in
  left)  ICON="←"; TIP="Move workspace LEFT"  ;;
  right) ICON="→"; TIP="Move workspace RIGHT" ;;
  up)    ICON="↑"; TIP="Move workspace UP"    ;;
  down)  ICON="↓"; TIP="Move workspace DOWN"  ;;
  *)     printf '{"text":""}\n'; exit 2 ;;
esac

command -v hyprctl >/dev/null 2>&1 || { printf '{"text":"","class":"ws-hidden"}\n'; exit 0; }
command -v jq       >/dev/null 2>&1 || { printf '{"text":"","class":"ws-hidden"}\n'; exit 0; }

MON_JSON="$(hyprctl -j monitors 2>/dev/null || true)"
[[ -n "$MON_JSON" ]] || { printf '{"text":"","class":"ws-hidden"}\n'; exit 0; }

FOCUS_NAME="$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.monitor // empty' || true)"
if [[ -z "${FOCUS_NAME:-}" || "${FOCUS_NAME}" == "null" ]]; then
  FOCUS_NAME="$(jq -r '([.[] | select(.focused==true and .active==true)][0] // empty) | .name // empty' <<<"$MON_JSON" || true)"
fi
if [[ -z "${FOCUS_NAME:-}" || "${FOCUS_NAME}" == "null" ]]; then
  FOCUS_NAME="$(jq -r '([.[] | select(.active==true)][0] // empty) | .name // empty' <<<"$MON_JSON" || true)"
fi
[[ -n "${FOCUS_NAME:-}" && "${FOCUS_NAME}" != "null" ]] || { printf '{"text":"","class":"ws-hidden"}\n'; exit 0; }

read -r FCX FCY <<<"$(
  jq -r --arg name "$FOCUS_NAME" '
    (.[] | select(.name==$name)) as $f
    | "\($f.x + ($f.width/2)) \($f.y + ($f.height/2))"
  ' <<<"$MON_JSON" 2>/dev/null || true
)"
[[ -n "${FCX:-}" && -n "${FCY:-}" ]] || { printf '{"text":"","class":"ws-hidden"}\n'; exit 0; }

EPS=1
COUNT="$(
  jq -r --arg name "$FOCUS_NAME" --arg dir "$DIR" --argjson fcx "$FCX" --argjson fcy "$FCY" --argjson eps "$EPS" '
    def cx(m): (m.x + (m.width/2));
    def cy(m): (m.y + (m.height/2));
    ( .[] | select(.name==$name) ) as $f
    | if $dir=="left"  then [ .[] | select(.name!=$name and cx(.) < ($fcx - $eps)) ] | length
      elif $dir=="right" then [ .[] | select(.name!=$name and cx(.) > ($fcx + $eps)) ] | length
      elif $dir=="up"    then [ .[] | select(.name!=$name and cy(.) < ($fcy - $eps)) ] | length
      elif $dir=="down"  then [ .[] | select(.name!=$name and cy(.) > ($fcy + $eps)) ] | length
      else 0 end
  ' <<<"$MON_JSON"
)"

if [[ "$COUNT" =~ ^[0-9]+$ ]] && (( COUNT > 0 )); then
  printf '{"text":"%s","class":"ws-shown","tooltip":"%s"}\n' "$ICON" "$TIP"
else
  printf '{"text":"","class":"ws-hidden"}\n'
fi
