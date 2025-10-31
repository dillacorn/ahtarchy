#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/play_pause.sh
# 
# Priority: Spotify → YouTube Music (Electron via PID→chromium.instance<PID> or metadata) → anything else.
# Deps: playerctl, timeout. Optional: hyprctl, jq.

set -euo pipefail

PLAYERCTL="${PLAYERCTL:-playerctl}"
TIMEOUT_BIN="${TIMEOUT_BIN:-timeout}"

pc() { "$TIMEOUT_BIN" 1s "$PLAYERCTL" "$@" 2>/dev/null || return 1; }
lo() { printf '%s' "${1,,}"; }

command -v "$PLAYERCTL" >/dev/null 2>&1 || { echo "playerctl not found" >&2; exit 1; }
command -v "$TIMEOUT_BIN" >/dev/null 2>&1 || { echo "timeout not found" >&2; exit 1; }

# Resolve Electron YouTube Music to its MPRIS name chromium.instance<PID>, if present
ytm_pid_target=""
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  pid="$(hyprctl -j clients 2>/dev/null | jq -r '
    .[] | select(
      (.class // ""|ascii_downcase|test("youtubemusic|youtube-music|youtube_music|com\\.github\\.th_ch\\.youtube_music")) or
      (.initialClass // ""|ascii_downcase|test("youtubemusic|youtube-music|youtube_music|com\\.github\\.th_ch\\.youtube_music")) or
      (.title // ""|ascii_downcase|test("\\byoutube music\\b"))
    ) | .pid' | head -n1 || true)"
  [[ -n "${pid:-}" ]] && ytm_pid_target="chromium.instance${pid}"
fi

# Enumerate players once
mapfile -t PLAYERS < <(pc -l | sort -u || true)
((${#PLAYERS[@]})) || exit 0

# Best candidate per bucket (prefer one already Playing)
sp_playing=""; sp_first=""
ytm_playing=""; ytm_first=""
ot_playing="";  ot_first=""

for p in "${PLAYERS[@]}"; do
  lp="$(lo "$p")"

  # Spotify bucket
  if [[ "$lp" == spotify* || "$lp" == *spotifyd* || "$lp" == *ncspot* ]]; then
    [[ -z "$sp_first" ]] && sp_first="$p"
    [[ "$(pc -p "$p" status || echo X)" == "Playing" ]] && sp_playing="${sp_playing:-$p}"
    continue
  fi

  # Pull all useful metadata in one call
  IFS=$'\t' read -r ident url de status < <(
    pc -p "$p" metadata --format '{{mpris:identity}}\t{{xesam:url}}\t{{mpris:desktop-entry}}' || echo -e "\t\t\t"
  )
  [[ -z "${status:-}" || "${status:-}" == "Unknown" ]] && status="$(pc -p "$p" status || echo X)"
  li="$(lo "${ident:-}")"; lu="$(lo "${url:-}")"; ld="$(lo "${de:-}")"

  # YouTube Music bucket: PID-mapped Electron or metadata
  is_ytm=0
  if [[ -n "$ytm_pid_target" && "$p" == "$ytm_pid_target" ]]; then
    is_ytm=1
  elif [[ "$li" == *"youtube music"* ]] || [[ -n "$lu" && "$lu" == *"music.youtube.com"* ]] \
     || [[ "$ld" == "youtube-music" || "$ld" == "youtube-music-bin" || "$ld" == "ytmdesktop" || "$ld" == "electron-youtube-music" ]]; then
    is_ytm=1
  fi

  if [[ $is_ytm -eq 1 ]]; then
    [[ -z "$ytm_first" ]] && ytm_first="$p"
    [[ "$status" == "Playing" ]] && ytm_playing="${ytm_playing:-$p}"
    continue
  fi

  # Everything else. Skip plain YouTube tabs if you want to avoid prioritizing them:
  # if [[ -n "$lu" && "$lu" == *"youtube.com"* && "$lu" != *"music.youtube.com"* ]]; then continue; fi

  [[ -z "$ot_first" ]] && ot_first="$p"
  [[ "$status" == "Playing" ]] && ot_playing="${ot_playing:-$p}"
done

# Choose target (prefer Playing in each bucket)
target="${sp_playing:-${sp_first:-}}"
[[ -z "$target" ]] && target="${ytm_playing:-${ytm_first:-}}"
[[ -z "$target" ]] && target="${ot_playing:-${ot_first:-}}"

[[ -n "$target" ]] && pc -p "$target" play-pause || true
exit 0
