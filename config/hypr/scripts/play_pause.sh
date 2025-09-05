#!/usr/bin/env bash
# ~/.config/hypr/scripts/play_pause.sh
# Behavior:
# 1) If Spotify is open -> toggle Spotify.
# 2) Else if YouTube Music is open -> toggle YouTube Music (Electron/AUR app or Brave YTM).
#    - Electron app is matched by Hyprland window PID → MPRIS "chromium.instance<PID>".
#    - Brave YTM is matched by metadata (music.youtube.com or identity contains "YouTube Music").
# 3) Else -> toggle the first other media player (includes generic YouTube in Brave, VLC, mpv, etc.).
#
# Deps: playerctl, timeout. Optional for better YTM detection: hyprctl, jq.

set -euo pipefail

PLAYERCTL="${PLAYERCTL:-/usr/bin/playerctl}"
TIMEOUT_BIN="${TIMEOUT_BIN:-/usr/bin/timeout}"
HYPRCTL="${HYPRCTL:-/usr/bin/hyprctl}"
JQ="${JQ:-/usr/bin/jq}"

# ---- sanity ----
[[ -x "$PLAYERCTL" ]]  || { echo "playerctl not found at $PLAYERCTL" >&2; exit 1; }
[[ -x "$TIMEOUT_BIN" ]]|| { echo "timeout not found at $TIMEOUT_BIN" >&2; exit 1; }

pc() { "$TIMEOUT_BIN" 1.0s "$PLAYERCTL" "$@" 2>/dev/null || return 1; }
lc() { printf '%s' "${1,,}"; }

pick_playing_else_first() {
  local first="" p
  for p in "$@"; do
    [[ -z "$first" ]] && first="$p"
    [[ "$(pc -p "$p" status || echo X)" == "Playing" ]] && { printf '%s' "$p"; return 0; }
  done
  printf '%s' "$first"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Try to resolve the YouTube Music Electron app via Hyprland PID → "chromium.instance<PID>"
resolve_ytm_via_pid() {
  have_cmd "$HYPRCTL" && have_cmd "$JQ" || return 1
  local pid name
  pid="$("$HYPRCTL" -j clients 2>/dev/null | "$JQ" -r '
      .[] | select(
        (.class // ""|ascii_downcase|test("youtubemusic|youtube-music|youtube_music|com\\.github\\.th_ch\\.youtube_music"))
        or (.initialClass // ""|ascii_downcase|test("youtubemusic|youtube-music|youtube_music|com\\.github\\.th_ch\\.youtube_music"))
        or (.title // ""|ascii_downcase|test("\\byoutube music\\b"))
      ) | .pid' | head -n1)"
  [[ -n "${pid:-}" ]] || return 1
  name="chromium.instance${pid}"
  pc -l | grep -qx "$name" || return 1
  printf '%s' "$name"
}

# Metadata-based YTM detection (Brave YTM or wrappers that actually set metadata)
resolve_ytm_via_metadata() {
  local p id url de idl urll del
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    id="$(pc -p "$p" metadata mpris:identity || true)"
    url="$(pc -p "$p" metadata xesam:url || true)"
    de="$(pc -p "$p" metadata mpris:desktop-entry || true)"
    idl="$(lc "${id:-}")"; urll="$(lc "${url:-}")"; del="$(lc "${de:-}")"
    # reject plain youtube if url says youtube.com but not music.youtube.com
    if [[ -n "$urll" && "$urll" == *"youtube.com"* && "$urll" != *"music.youtube.com"* ]]; then
      continue
    fi
    if [[ "$idl" == *"youtube music"* ]] || [[ -n "$urll" && "$urll" == *"music.youtube.com"* ]] \
       || [[ "$del" == "youtube-music" || "$del" == "youtube-music-bin" || "$del" == "ytmdesktop" || "$del" == "electron-youtube-music" ]]; then
      printf '%s' "$p"
      return 0
    fi
  done < <(pc -l | sort -u)
  return 1
}

# ---- enumerate all players once ----
mapfile -t ALL < <(pc -l | sort -u || true)

# ---- 1) Spotify family first ----
declare -a SPOTIFY=()
for p in "${ALL[@]}"; do
  np="$(lc "$p")"
  if [[ "$np" == spotify* || "$np" == *spotifyd* || "$np" == *ncspot* ]]; then
    SPOTIFY+=("$p")
  else
    # double-check identity/desktop-entry for odd clients
    id="$(pc -p "$p" metadata mpris:identity || true)"
    de="$(pc -p "$p" metadata mpris:desktop-entry || true)"
    il="$(lc "${id:-}")"; dl="$(lc "${de:-}")"
    [[ "$il" == *spotify* || "$dl" == *spotify* || "$dl" == *ncspot* || "$dl" == *spotifyd* ]] && SPOTIFY+=("$p")
  fi
done

if ((${#SPOTIFY[@]} > 0)); then
  tgt="$(pick_playing_else_first "${SPOTIFY[@]}")"
  pc -p "$tgt" play-pause && exit 0 || exit 1
fi

# ---- 2) YouTube Music next ----
ytm_target=""
# Prefer rock-solid PID binding (Electron app)
ytm_target="$(resolve_ytm_via_pid || true)"
# Else metadata path (Brave YTM etc.)
[[ -z "$ytm_target" ]] && ytm_target="$(resolve_ytm_via_metadata || true)"

if [[ -n "$ytm_target" ]]; then
  pc -p "$ytm_target" play-pause && exit 0 || exit 1
fi

# ---- 3) Fallback: any other media player (includes Brave generic YouTube, VLC, mpv, etc.) ----
# Exclude anything we might have already considered (Spotify names and YTM target).
declare -a FALLBACK=()
for p in "${ALL[@]}"; do
  np="$(lc "$p")"
  # skip spotify-like already handled
  if [[ "$np" == spotify* || "$np" == *spotifyd* || "$np" == *ncspot* ]]; then
    continue
  fi
  # skip exact YTM target if set
  [[ -n "$ytm_target" && "$p" == "$ytm_target" ]] && continue
  FALLBACK+=("$p")
done

if ((${#FALLBACK[@]} > 0)); then
  tgt="$(pick_playing_else_first "${FALLBACK[@]}")"
  pc -p "$tgt" play-pause && exit 0 || exit 1
fi

# Nothing to control
exit 0
