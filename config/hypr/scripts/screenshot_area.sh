#!/usr/bin/env bash
# ~/.config/hypr/scripts/screenshot_area.sh
# deps: grim slurp satty hyprctl wl-clipboard notify-send (optional)
set -euo pipefail

# Debug: run with DEBUG=1 env to trace
[[ "${DEBUG:-0}" == "1" ]] && set -x
LOG="/tmp/satty_screenshot.log"

# 1) Region select; exit cleanly if cancelled
GEOM="$(slurp -b '#ffffff20' -c '#00000040' 2>>"$LOG" || true)"
[ -z "${GEOM}" ] && exit 0

# 2) Paths
out_dir="$HOME/Pictures/Screenshots"
mkdir -p "$out_dir"
ts="$(date +%m%d%Y-%I%p-%S)"
png_path="$out_dir/${ts}.png"
tmp_png="$(mktemp --suffix=.png)"

# 3) Capture to PNG file (stdin piping can race focus)
grim -g "${GEOM}" -t png "${tmp_png}" 2>>"$LOG"

# 4) Build Satty argv
SATTY_ARGS=(
  --filename "$tmp_png"
  --output-filename "$png_path"
  --default-hide-toolbars
)

# 5) Prefer launching via Hyprland with activation token; hard-escape argv
launch_with_hypr() {
  local token="${XDG_ACTIVATION_TOKEN:-}"
  local cmd=(satty "${SATTY_ARGS[@]}")
  if [[ -n "$token" ]]; then
    cmd=(env XDG_ACTIVATION_TOKEN="$token" "${cmd[@]}")
  fi
  # Quote-safe join for Hyprland exec
  local joined=""
  printf -v joined '%q ' "${cmd[@]}"
  # Hyprland expects a single command string
  if hyprctl dispatch exec "${joined% }" >>"$LOG" 2>&1; then
    return 0
  else
    return 1
  fi
}

# 6) Launch Satty
if ! launch_with_hypr; then
  # Fallback: run directly (e.g., when started outside Hyprland or exec failed)
  ( "${SATTY_ARGS[@]/#/satty }" ) >>"$LOG" 2>&1 || {
    echo "Satty failed to launch. See $LOG" >&2
    rm -f "$tmp_png"
    exit 1
  }
fi

# 7) Wait for Satty to start, then to exit
for _ in $(seq 1 80); do
  pgrep -x satty >/dev/null && break
  sleep 0.05
done
while pgrep -x satty >/dev/null; do sleep 0.1; done

# 8) Clipboard safety net (handles portal/focus quirks)
if ! wl-paste --list-types 2>/dev/null | grep -q '^image/png$'; then
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "${png_path}" && notify-send "Screenshot" "Image copied to clipboard" -i "${png_path}" || true
  fi
fi

# 9) Cleanup
rm -f "${tmp_png}"
