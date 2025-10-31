#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/launch_handler.sh
#
# Ultra-light Hyprland toggle for FLOATING utility windows (no tiles touched).
# - If a matching floating client exists on the focused workspace: close one (the most recent).
# - Else if a matching floating client exists on another workspace: close all remote, then launch here.
# - Else launch here.
# Matching: class/initialClass/title (case-insensitive). Fallback: process name from launch command.
#
# Usage:
#   launch_handler.sh <logical-name> "<launch command>"
# Examples:
#   launch_handler.sh wiremix  "alacritty --class wiremix -e wiremix"
#   launch_handler.sh maccel   "alacritty --class maccel -e maccel"
#   launch_handler.sh waytrogen "waytrogen"
#
# Optional overrides:
#   APP_CLASS_OVERRIDE="ExactClass" APP_TITLE_OVERRIDE="ExactTitle" APP_PROC_OVERRIDE="binaryname" launch_handler.sh name "cmd ..."

set -euo pipefail

# -------- args --------
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <logical-name> \"<launch command>\"" >&2
  exit 1
fi
APP_NAME="$1"
LAUNCH_STR="$2"

# -------- match hints --------
APP_CLASS="${APP_CLASS_OVERRIDE:-$APP_NAME}"
APP_TITLE="${APP_TITLE_OVERRIDE:-$APP_NAME}"
read -r __cmd_first __rest <<<"$LAUNCH_STR" || true
__cmd_first="${__cmd_first:-}"
APP_PROC_DEFAULT="${__cmd_first##*/}"
APP_PROC="${APP_PROC_OVERRIDE:-$APP_PROC_DEFAULT}"

# -------- deps / IPC --------
for c in hyprctl jq; do command -v "$c" >/dev/null 2>&1 || { echo "Missing: $c" >&2; exit 1; }; done
hyprctl activeworkspace -j >/dev/null 2>&1 || { echo "Hyprland IPC not available" >&2; exit 1; }

# -------- cache hypr state (single pass) --------
WS_ID="$(hyprctl activeworkspace -j | jq -r '.id // 0')"
CLIENTS_JSON="$(hyprctl clients -j 2>/dev/null || echo '[]')"
jq -e . >/dev/null 2>&1 <<<"$CLIENTS_JSON" || CLIENTS_JSON='[]'

# Floating truthy (bool/int/string)
FLOATING_TRUTHY_JQ='
  (.floating==true) or (.floating==1) or
  ((.floating|type=="string") and ((.floating|ascii_downcase)=="true" or (.floating|ascii_downcase)=="yes" or (.floating|ascii_downcase)=="on"))
'

# Dump candidate clients as TSV: ws_id  pid  address  class  initialClass  title
# Only mapped, not hidden, and floating. This is the only jq over clients.
readarray -t CANDIDATES < <(
  printf '%s' "$CLIENTS_JSON" | jq -r '
    (. // [])[]? |
    select(.mapped==true and .hidden==false) |
    select('"$FLOATING_TRUTHY_JQ"') |
    [( .workspace.id // 0 )
    ,( .pid           // 0 )
    ,( .address       // "" )
    ,( .class         // "" )
    ,( .initialClass  // "" )
    ,( .title         // "" )
    ] | @tsv
  ' 2>/dev/null
)

# -------- helpers --------
to_lc() { awk '{print tolower($0)}'; }

class_or_title_match() {
  # $1 class $2 initialClass $3 title
  local c lc_c="$APP_CLASS" lc_t="$APP_TITLE"
  [[ -n "$1" && "$(printf %s "$1" | to_lc)" == "$(printf %s "$lc_c" | to_lc)" ]] && return 0
  [[ -n "$2" && "$(printf %s "$2" | to_lc)" == "$(printf %s "$lc_c" | to_lc)" ]] && return 0
  [[ -n "$3" && "$(printf %s "$3" | to_lc)" == "$(printf %s "$lc_t" | to_lc)" ]] && return 0
  return 1
}

proc_match_pid() {
  # $1 pid -> 0 if /proc name matches APP_PROC (case-insensitive)
  local pid="$1" want="$(printf %s "$APP_PROC" | to_lc)"
  [[ -z "$pid" || "$pid" == "0" ]] && return 1
  if [[ -r "/proc/$pid/comm" ]]; then
    local comm; comm="$(tr -d '\n' </proc/$pid/comm 2>/dev/null || true)"
    [[ "$(printf %s "$comm" | to_lc)" == "$want" ]] && return 0
  fi
  if [[ -r "/proc/$pid/cmdline" ]]; then
    local cmd first; cmd="$(tr '\0' ' ' </proc/$pid/cmdline 2>/dev/null || true)"
    read -r first _ <<<"$cmd"; first="${first##*/}"
    [[ "$(printf %s "$first" | to_lc)" == "$want" ]] && return 0
    printf ' %s ' "$cmd" | to_lc | grep -q " $want " && return 0
  fi
  return 1
}

close_addr() { local a="$1"; [[ -n "$a" ]] && hyprctl dispatch closewindow "address:$a" >/dev/null 2>&1 || true; }

# -------- classify matches (single pass over candidates) --------
HERE_ADDRS=()
OTHER_ADDRS=()

for line in "${CANDIDATES[@]}"; do
  # shellcheck disable=SC2206
  IFS=$'\t' read -r _ws _pid _addr _class _init _title <<<"$line"
  [[ -z "${_addr:-}" ]] && continue

  if class_or_title_match "$_class" "$_init" "$_title"; then
    :
  elif [[ -n "$APP_PROC" ]] && proc_match_pid "$_pid"; then
    :
  else
    continue
  fi

  if [[ "${_ws}" == "${WS_ID}" ]]; then
    HERE_ADDRS+=("$_addr")
  else
    OTHER_ADDRS+=("$_addr")
  fi
done

# -------- actions --------
# 1) Close one local floating match (toggle off here)
if [[ ${#HERE_ADDRS[@]} -gt 0 ]]; then
  close_addr "${HERE_ADDRS[-1]}"
  exit 0
fi

# 2) Close all remote floating matches, then launch here
if [[ ${#OTHER_ADDRS[@]} -gt 0 ]]; then
  for a in "${OTHER_ADDRS[@]}"; do close_addr "$a"; done
  # tiny gap to let compositor remove the old surfaces
  usleep() { perl -e "select(undef,undef,undef,$1)"; }
  usleep 0.05
  eval "$LAUNCH_STR" >/dev/null 2>&1 &
  exit 0
fi

# 3) Nothing active -> launch here
eval "$LAUNCH_STR" >/dev/null 2>&1 &
