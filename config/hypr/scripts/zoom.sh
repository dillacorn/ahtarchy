# FILE: ~/.config/hypr/scripts/zoom.sh
#!/usr/bin/env bash
# + | - | reset | rigid | rigid:on | rigid:off | status
set -euo pipefail

HC="$(command -v hyprctl || echo /usr/bin/hyprctl)"
JQ="$(command -v jq || echo /usr/bin/jq)"
AWK="$(command -v awk || echo /usr/bin/awk)"
NOTIFY="$(command -v notify-send || true)"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-zoom.log"
mkdir -p "$(dirname "$LOG")"

# Resolve option keys
if "$HC" getoption 'cursor:zoom_factor' -j >/dev/null 2>&1; then
  KEY_FACTOR='cursor:zoom_factor'
  KEY_RIGID='cursor:zoom_rigid'
elif "$HC" getoption 'misc:cursor_zoom_factor' -j >/dev/null 2>&1; then
  KEY_FACTOR='misc:cursor_zoom_factor'
  KEY_RIGID='misc:cursor_zoom_rigid'
else
  echo "Zoom options not found"; exit 1
fi

getf() { "$HC" getoption "$KEY_FACTOR" -j | "$JQ" -r '.float // .int // 1'; }
setf() { "$HC" -q keyword "$KEY_FACTOR" "$1"; }
log()  { printf '%s %s\n' "$(date +'%F %T')" "$*" >>"$LOG" || true; }

# Robust boolean read/write (covers true/false, 1/0, on/off)
getrig() {
  "$HC" getoption "$KEY_RIGID" -j 2>/dev/null \
    | "$JQ" -r '
        if .bool? != null then (if .bool then "true" else "false" end)
        elif .int?  != null then (if .int == 1 then "true" else "false" end)
        else "false" end
      ' || echo "false"
}
setrig_val() {
  local key="$1" target="$2" state
  # try native true/false
  "$HC" -q keyword "$key" "$target" || true
  sleep 0.02
  state="$(getrig)"
  [ "$state" = "$target" ] && return 0
  # try numeric
  "$HC" -q keyword "$key" $([ "$target" = "true" ] && echo 1 || echo 0) || true
  sleep 0.02
  state="$(getrig)"
  [ "$state" = "$target" ] && return 0
  # try on/off
  "$HC" -q keyword "$key" $([ "$target" = "true" ] && echo on || echo off) || true
  sleep 0.02
  state="$(getrig)"
  [ "$state" = "$target" ]
}

case "${1:-+}" in
  +)
    cur="$(getf)"; new="$("$AWK" -v c="$cur" 'BEGIN{printf "%.3f", c*1.10}')"
    setf "$new"; echo "zoom_factor: $cur -> $new"; log "factor $cur -> $new"
    ;;
  -)
    cur="$(getf)"; new="$("$AWK" -v c="$cur" 'BEGIN{n=c/1.10; if(n<1)n=1; printf "%.3f", n}')"
    setf "$new"; echo "zoom_factor: $cur -> $new"; log "factor $cur -> $new"
    ;;
  reset)
    setf 1; echo "zoom_factor: 1.000"; log "factor -> 1.000"
    ;;
  rigid)
    before="$(getrig)"
    target=$([ "$before" = "true" ] && echo false || echo true)
    setrig_val "$KEY_RIGID" "$target" || true
    after="$(getrig)"
    echo "zoom_rigid: $before -> $after"; log "rigid $before -> $after"
    [ -n "$NOTIFY" ] && "$NOTIFY" -a "Hypr Zoom" "rigid: $after" || true
    ;;
  rigid:on)
    setrig_val "$KEY_RIGID" true || true
    after="$(getrig)"; echo "zoom_rigid: $after"; log "rigid -> $after"
    [ -n "$NOTIFY" ] && "$NOTIFY" -a "Hypr Zoom" "rigid: $after" || true
    ;;
  rigid:off)
    setrig_val "$KEY_RIGID" false || true
    after="$(getrig)"; echo "zoom_rigid: $after"; log "rigid -> $after"
    [ -n "$NOTIFY" ] && "$NOTIFY" -a "Hypr Zoom" "rigid: $after" || true
    ;;
  status)
    echo "KEY_FACTOR=$KEY_FACTOR"
    echo "KEY_RIGID=$KEY_RIGID"
    echo "zoom_factor=$(getf)"
    echo "zoom_rigid=$(getrig)"
    ;;
  *)
    echo "Usage: zoom.sh {+|-|reset|rigid|rigid:on|rigid:off|status}"; exit 2
    ;;
esac
