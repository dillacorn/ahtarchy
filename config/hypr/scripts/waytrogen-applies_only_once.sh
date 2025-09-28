#!/usr/bin/env bash
# ~/.config/hypr/scripts/waytrogen-applies_only_once.sh
# Write Waytrogen prefs once and apply via swww if running.
# Optionally require Waytrogen to be installed.

set -euo pipefail

# Behavior: set to "true" to require Waytrogen; "false" to skip the check
DO_REQUIRE_WAYTROGEN="true"

IMG="$HOME/Pictures/wallpapers/arch_geology.png"
DIR="$HOME/Pictures/wallpapers"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waytrogen"
SENTINEL="${STATE_DIR}/defaults_applied"
mkdir -p "$STATE_DIR"
[[ -f "$SENTINEL" ]] && exit 0

command -v dconf >/dev/null || { echo "dconf not found"; exit 1; }
[[ $DO_REQUIRE_WAYTROGEN == "true" ]] && command -v waytrogen >/dev/null || true
[[ -f "$IMG" ]] || { echo "Image not found: $IMG"; exit 1; }

# Write prefs to dconf (Waytrogen reads these later)
dconf write /org/Waytrogen/Waytrogen/wallpaper-folder "'$DIR'"
dconf write /org/Waytrogen/Waytrogen/changer 'uint32 1'   # 1 = Swww on your build
dconf write /org/Waytrogen/Waytrogen/monitor 'uint32 0'   # 0 = All

RAW_JSON=$(cat <<EOF
[{"monitor":"All","path":"$IMG","changer":{"Swww":["Crop",{"red":0.0,"green":0.0,"blue":0.0},"Nearest","Any",90,1,60,45,{"position":"center"},false,{"p0":0.99,"p1":0.99,"p2":0.99,"p3":0.99},{"width":200,"height":200}]}}]
EOF
)
dconf write /org/Waytrogen/Waytrogen/saved-wallpapers "'$RAW_JSON'"

# Optional mirrors (no daemon control)
dconf write /org/Waytrogen/Waytrogen/swww-scaling-filter       'uint32 0' || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-type      'uint32 11' || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-step      '90.0'      || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-duration  '1.0'       || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-fps       'uint32 60' || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-angle     '45.0'      || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-position  "'center'"  || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-wave-width  '200.0'   || true
dconf write /org/Waytrogen/Waytrogen/swww-transition-wave-height '200.0'   || true
dconf write /org/Waytrogen/Waytrogen/swww-invert-y             'false'     || true

# Apply now ONLY if swww is already running. Never start/stop it here.
if pgrep -x swww-daemon >/dev/null; then
  SW_HELP="$(swwww img --help 2>&1 || true)"  # tolerate typo on some builds
  SW_HELP="$(swww img --help 2>&1 || echo)"
  has(){ grep -qi -- "$1" <<<"$SW_HELP"; }

  args=()
  has '--resize'          && args+=(--resize crop)
  has '--fill'            && args+=(--fill crop)
  has '--filter'          && args+=(--filter nearest)
  has '--scaling-filter'  && args+=(--scaling-filter nearest)
  has '--transition-type'     && args+=(--transition-type any)
  has '--transition-step'     && args+=(--transition-step 90)
  has '--transition-duration' && args+=(--transition-duration 1)
  has '--transition-fps'      && args+=(--transition-fps 60)
  has '--transition-angle'    && args+=(--transition-angle 45)
  has '--transition-pos'      && args+=(--transition-pos center)
  has '--transition-position' && args+=(--transition-position center)

  mapfile -t OUTS < <(swww query 2>/dev/null | awk -F: '/: [A-Z0-9-]+:/{print $2}' | awk '{print $1}')
  if ((${#OUTS[@]} > 0)) && grep -qi -- '--output' <<<"$SW_HELP"; then
    for o in "${OUTS[@]}"; do
      swww img --output "$o" "${args[@]}" "$IMG" >/dev/null 2>&1 || true
    done
  else
    swww img "${args[@]}" "$IMG" >/dev/null 2>&1 || true
  fi
fi

: > "$SENTINEL"
exit 0
