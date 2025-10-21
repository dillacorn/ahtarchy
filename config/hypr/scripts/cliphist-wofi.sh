#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/cliphist-wofi.sh

# Wofi + cliphist with image previews, toggle, percent geometry.
# Line numbers from `cliphist list` are hidden in the visible list, but selection stays intact.

set -uo pipefail

# --- Percent geometry (native wofi) ---
WOFI_WIDTH_PCT="${WOFI_WIDTH_PCT:-55%}"   # e.g. 55%
WOFI_HEIGHT_PCT="${WOFI_HEIGHT_PCT:-55%}" # e.g. 55%

# --- Behavior ---
WOFI_PROMPT="${WOFI_PROMPT:-Clipboard}"
LIST_LIMIT="${LIST_LIMIT:-60}"
WOFI_IMAGE_SIZE="${WOFI_IMAGE_SIZE:-256}"     # row height; lower for denser list
DECODE_TIMEOUT="${DECODE_TIMEOUT:-0.35s}"

# Layout
WOFI_COLUMNS="${WOFI_COLUMNS:-1}"
WOFI_LINE_WRAP="${WOFI_LINE_WRAP:-off}"     # off|word|char|word_char
WOFI_DYNAMIC_LINES="${WOFI_DYNAMIC_LINES:-false}"
WOFI_HALIGN="${WOFI_HALIGN:-start}"           # fill|start|end|center
WOFI_CONTENT_HALIGN="${WOFI_CONTENT_HALIGN:-start}"

# --- Runtime/cache ---
RUNTIME_BASE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
RUNDIR="$RUNTIME_BASE/cliphist-wofi"
PREVIEW_DIR="${PREVIEW_DIR:-$RUNDIR/previews}"
LOCKFILE="${LOCKFILE:-$RUNDIR/preview.lock}"
mkdir -p "$PREVIEW_DIR" "$(dirname "$LOCKFILE")" "$RUNDIR"

# Toggle signature so second call closes existing picker
SIG_KEY="cliphist_wofi_sig"
SIG_VAL="1"
SIG_DEF=(--define "${SIG_KEY}=${SIG_VAL}")

SUPPORTED_EXT_REGEX='jpg|jpeg|png|bmp|webp|gif|tiff'

# Display helper: strip numeric ID shown by `cliphist list`
strip_id() { sed -E 's/^[[:space:]]*[0-9]+\t//'; }

# ----- Preview/display hook -----
# Shows labels without the leading ID. For images, also shows a thumbnail.
# The ORIGINAL unmodified line is still what wofi returns for selection.
if [[ "${1:-}" == "--preview" ]]; then
  entry="${2-}"
  label="$(printf '%s' "$entry" | strip_id)"

  # Non-binary rows
  if ! grep -Eiq '\[\[\s*binary' <<<"$entry"; then
    printf 'text:%s\n' "$label"
    exit 0
  fi

  # Binary rows: decode to cache, then output thumbnail + label (without ID)
  hash="$(printf '%s' "$entry" | sha1sum | awk '{print $1}')"
  ext_hint="$(grep -Eio "($SUPPORTED_EXT_REGEX)" <<<"$entry" | head -n1 | tr '[:upper:]' '[:lower:]' || true)"
  [[ "$ext_hint" == "jpeg" ]] && ext_hint="jpg"
  candidate="${PREVIEW_DIR}/${hash}.${ext_hint:-bin}"

  if [[ -s "$candidate" ]]; then
    printf 'img:%s:text:%s\n' "$candidate" "$label"
    exit 0
  fi

  tmp="${candidate}.tmp"; rm -f -- "$tmp" 2>/dev/null || true
  exec {lfd}>"$LOCKFILE" || true
  if flock -w 0.2 "$lfd"; then
    if ! timeout "$DECODE_TIMEOUT" cliphist decode >"$tmp" <<<"$entry" 2>/dev/null; then
      rm -f -- "$tmp" 2>/dev/null || true
      printf 'text:%s\n' "$label"
      flock -u "$lfd" || true
      exit 0
    fi
    flock -u "$lfd" || true
  else
    printf 'text:%s\n' "$label"
    exit 0
  fi

  real_ext="${ext_hint:-bin}"
  if command -v file >/dev/null 2>&1; then
    case "$(file -b --mime-type "$tmp" 2>/dev/null || true)" in
      image/jpeg) real_ext="jpg" ;;
      image/png)  real_ext="png" ;;
      image/gif)  real_ext="gif" ;;
      image/webp) real_ext="webp" ;;
      image/bmp)  real_ext="bmp" ;;
      image/tiff) real_ext="tiff" ;;
    esac
  fi
  final="${PREVIEW_DIR}/${hash}.${real_ext}"
  mv -f -- "$tmp" "$final"
  printf 'img:%s:text:%s\n' "$final" "$label"
  (find "$PREVIEW_DIR" -type f -mtime +7 -delete >/dev/null 2>&1 || true) & disown
  exit 0
fi

# ----- Toggle: close existing picker if open -----
if command -v pgrep >/dev/null 2>&1; then
  if pgrep -af "wofi.*${SIG_KEY}=${SIG_VAL}" >/dev/null 2>&1; then
    pkill -f "wofi.*${SIG_KEY}=${SIG_VAL}" || true
    sleep 0.05
    pgrep -af "wofi.*${SIG_KEY}=${SIG_VAL}" >/dev/null 2>&1 && pkill -9 -f "wofi.*${SIG_KEY}=${SIG_VAL}" || true
    exit 0
  fi
fi

# ----- Main picker -----
for bin in cliphist wl-copy wofi sha1sum timeout; do
  command -v "$bin" >/dev/null 2>&1 || { echo "$bin not found" >&2; exit 1; }
done

SELF="$(readlink -f "$0")"

BASE_ARGS=(
  --dmenu
  --prompt "$WOFI_PROMPT"
  --height "$WOFI_HEIGHT_PCT"      # percent, not px
  --width "$WOFI_WIDTH_PCT"        # percent, not px
  --cache-file=/dev/null
  --define "image_size=${WOFI_IMAGE_SIZE}"
  --define "columns=${WOFI_COLUMNS}"
  --define "line_wrap=${WOFI_LINE_WRAP}"
  --define "dynamic_lines=${WOFI_DYNAMIC_LINES}"
  --define "halign=${WOFI_HALIGN}"
  --define "content_halign=${WOFI_CONTENT_HALIGN}"
  --parse-search
  "${SIG_DEF[@]}"
)

# Use our preview hook to: 1) hide IDs; 2) show thumbnails.
PREVIEW_ARGS=()
if wofi --help 2>&1 | grep -q -- '--pre-display-cmd'; then
  PREVIEW_ARGS=(--allow-images --define "pre_display_exec=true" --pre-display-cmd "$SELF --preview %s")
fi

set +e
CHOICE="$(cliphist list --reverse --max-count "$LIST_LIMIT" | wofi "${BASE_ARGS[@]}" "${PREVIEW_ARGS[@]}")"
rc=$?
set -e
[[ $rc -ne 0 ]] && exit 0

# If wofi echoed the hook format, strip back to the original line
[[ "$CHOICE" == img:*:text:* ]] && CHOICE="${CHOICE#*text:}"
[[ "$CHOICE" == text:* ]] && CHOICE="${CHOICE#text:}"
[[ -z "${CHOICE:-}" ]] && exit 0

cliphist decode <<<"$CHOICE" | wl-copy -n
