#!/usr/bin/env bash
# ~/.config/hypr/scripts/cliphist-wofi.sh
# Wofi + cliphist picker with image previews and built-in toggle.
# Second invocation closes the already-open picker instead of launching a new one.

set -euo pipefail

# -------- Tunables (env overrides) --------
WOFI_PROMPT="${WOFI_PROMPT:-Clipboard}"
WOFI_HEIGHT="${WOFI_HEIGHT:-600}"
WOFI_WIDTH="${WOFI_WIDTH:-900}"
LIST_LIMIT="${LIST_LIMIT:-60}"
WOFI_IMAGE_SIZE="${WOFI_IMAGE_SIZE:-64}"
DECODE_TIMEOUT="${DECODE_TIMEOUT:-0.35s}"

# Caches
RUNTIME_BASE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}"
PREVIEW_DIR="${PREVIEW_DIR:-$RUNTIME_BASE/cliphist-wofi/previews}"
LOCKFILE="${LOCKFILE:-$RUNTIME_BASE/cliphist-wofi/preview.lock}"

# Unique signature to identify our Wofi instance for toggling
SIG_KEY="cliphist_wofi_sig"
SIG_VAL="1"
SIG_ARG="--define ${SIG_KEY}=${SIG_VAL}"

SUPPORTED_EXT_REGEX='jpg|jpeg|png|bmp|webp|gif|tiff'

# -------- Preview subcommand (called by wofi per row) --------
if [[ "${1:-}" == "--preview" ]]; then
  entry="${2-}"

  if [[ -z "$entry" ]] || ! grep -Eiq '\[\[\s*binary' <<<"$entry"; then
    printf '%s\n' "$entry"
    exit 0
  fi

  mkdir -p "$PREVIEW_DIR" "$(dirname "$LOCKFILE")"

  hash="$(printf '%s' "$entry" | sha1sum | awk '{print $1}')"
  ext_hint="$(grep -Eio "($SUPPORTED_EXT_REGEX)" <<<"$entry" | head -n1 | tr '[:upper:]' '[:lower:]' || true)"
  [[ "$ext_hint" == "jpeg" ]] && ext_hint="jpg"
  candidate="${PREVIEW_DIR}/${hash}.${ext_hint:-bin}"

  if [[ -s "$candidate" ]]; then
    printf 'img:%s:text:%s\n' "$candidate" "$entry"
    exit 0
  fi

  tmp="${candidate}.tmp"
  rm -f -- "$tmp" 2>/dev/null || true

  if command -v flock >/dev/null 2>&1; then
    if ! flock -w 0.2 "$LOCKFILE" bash -c \
        'printf "%s" "$1" | timeout "$2" cliphist decode >"$3" 2>/dev/null' _ \
        "$entry" "$DECODE_TIMEOUT" "$tmp"; then
      rm -f -- "$tmp" 2>/dev/null || true
      printf '%s\n' "$entry"
      exit 0
    fi
  else
    if ! printf '%s' "$entry" | timeout "$DECODE_TIMEOUT" cliphist decode >"$tmp" 2>/dev/null; then
      rm -f -- "$tmp" 2>/dev/null || true
      printf '%s\n' "$entry"
      exit 0
    fi
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
  printf 'img:%s:text:%s\n' "$final" "$entry"
  (find "$PREVIEW_DIR" -type f -mtime +7 -delete >/dev/null 2>&1 || true) & disown
  exit 0
fi

# -------- Toggle: if our picker is already open, close it and exit --------
if command -v pgrep >/dev/null 2>&1; then
  if pgrep -af "wofi.*${SIG_KEY}=${SIG_VAL}" >/dev/null 2>&1; then
    pkill -f "wofi.*${SIG_KEY}=${SIG_VAL}" || true
    sleep 0.05
    if pgrep -af "wofi.*${SIG_KEY}=${SIG_VAL}" >/dev/null 2>&1; then
      pkill -9 -f "wofi.*${SIG_KEY}=${SIG_VAL}" || true
    fi
    exit 0
  fi
fi

# -------- Main picker --------
for bin in cliphist wl-copy wofi sha1sum timeout; do
  command -v "$bin" >/dev/null 2>&1 || { echo "$bin not found" >&2; exit 1; }
done

SELF="$(readlink -f "$0")"
mkdir -p "$PREVIEW_DIR" "$(dirname "$LOCKFILE")"

WOFI_ARGS=(
  --dmenu
  --allow-images
  --parse-search
  --prompt "$WOFI_PROMPT"
  --height "$WOFI_HEIGHT"
  --width "$WOFI_WIDTH"
  --cache-file=/dev/null
  --define "image_size=${WOFI_IMAGE_SIZE}"
  --define "allow_markup=false"
  --define "pre_display_exec=true"
  $SIG_ARG
  --pre-display-cmd "$SELF --preview %s"
)

choice="$(cliphist list --reverse --max-count "$LIST_LIMIT" | wofi "${WOFI_ARGS[@]}" || true)"
[[ -n "${choice:-}" ]] || exit 0

[[ "$choice" == img:*:text:* ]] && choice="${choice#*text:}"
cliphist decode <<<"$choice" | wl-copy -n
