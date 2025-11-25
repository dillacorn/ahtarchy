#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/screenshot_area.sh

set -euo pipefail

OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

GEOM="$(slurp -b '#ffffff20' -c '#00000040')" || exit 1
[ -z "$GEOM" ] && exit 1

TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}"
TMPFILE="$(mktemp "$TMP_DIR/satty-shot-XXXXXX.png")"
OUTFILE="$OUTPUT_DIR/$(date +%m%d%Y-%I%p-%S).png"

# 1) Capture selection to a real PNG file
grim -g "$GEOM" "$TMPFILE"

# 2) Immediately copy that image to clipboard
wl-copy --type image/png < "$TMPFILE"

# 3) Open the same image in satty for optional editing / copying
satty \
  --filename "$TMPFILE" \
  --output-filename "$OUTFILE" \
  --default-hide-toolbars

# 4) Clean up temp file after satty closes
rm -f "$TMPFILE"
