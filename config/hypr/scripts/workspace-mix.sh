#!/usr/bin/env bash
# FILE: ~/.config/hypr/scripts/workspace-mix.sh
# PURPOSE:
#   - Mix windows from selected Hyprland workspaces into a temporary workspace named by MIX_NAME
#   - Toggle adds/removes live
#   - Restore: return windows to their original workspaces, then refocus last workspace
# DEPS: bash, hyprctl, jq

set -euo pipefail

# ---------- Config ----------
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/workspace-mix"
STATE_FILE="$CACHE_ROOT/state.json"
MIX_NAME=" "   # leading space + Nerd Font glyph
mkdir -p "$CACHE_ROOT"

# ---------- Helpers ----------
err() { printf 'workspace-mix: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

require_deps() {
  local missing=()
  have hyprctl || missing+=("hyprctl")
  have jq      || missing+=("jq")
  if ((${#missing[@]})); then
    err "missing deps: ${missing[*]}"
    exit 1
  fi
}

monitors_json()   { hyprctl -j monitors; }
workspaces_json() { hyprctl -j workspaces; }
clients_json()    { hyprctl -j clients; }

focused_monitor() {
  monitors_json | jq -r '(map(select(.focused==true))[0].name) // (.[0].name) // empty'
}
focused_ws_label() {
  monitors_json | jq -r '(map(select(.focused==true))[0].activeWorkspace.name) // (.[0].activeWorkspace.name) // empty'
}

is_numeric() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }
now_epoch()  { date +%s; }

# Normalize to a workspace label (string). If numeric id, resolve to name if possible.
ws_label_from_arg() {
  local arg="$1"
  if is_numeric "$arg"; then
    local name
    name="$(workspaces_json | jq -r --argjson id "$arg" '([.[]|select(.id==$id).name][0]) // empty')"
    printf '%s' "${name:-$arg}"
  else
    printf '%s' "$arg"
  fi
}

# For "workspace" and "movetoworkspacesilent": accept "name:<label>" or numeric id.
ws_token_for_client_move() {
  local label="$1"
  if is_numeric "$label"; then printf '%s' "$label"; else printf 'name:%s' "$label"; fi
}

empty_state_json() {
  cat <<'JSON'
{
  "selection": [],
  "windows": [],
  "mix_ws": "",
  "monitor": "",
  "prev_ws": "",
  "created": 0
}
JSON
}

load_state() {
  if [[ -s "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    empty_state_json
  fi
}

save_state() {
  local tmp="${STATE_FILE}.tmp"
  cat > "$tmp"
  mv -f "$tmp" "$STATE_FILE"
}

# Move by address to a workspace LABEL
move_addr_to_ws() {
  local addr="$1" label="$2"
  hyprctl dispatch movetoworkspacesilent "$(ws_token_for_client_move "$label"),address:$addr" >/dev/null
}

# Current client addresses (newline-separated)
live_addr_set() { clients_json | jq -r '.[].address' | sort -u; }

# Clients on a given LABEL as [{address, orig_ws}]
clients_from_label_as_moves() {
  local label="$1"
  clients_json | jq -c --arg l "$label" '
    map(select(.workspace.name == $l and .mapped==true))
    | map({address, orig_ws: .workspace.name})
  '
}

# Toggle selection LABEL and apply immediately
apply_toggle_immediate() {
  local label="$1"
  local state mix_ws first_add prev_ws

  state="$(load_state)"
  if [[ "$(jq -r '.mix_ws' <<<"$state")" == "" ]]; then
    local mon
    mon="$(focused_monitor)"
    state="$(empty_state_json | jq --arg m "$mon" --arg mw "$MIX_NAME" --argjson ts "$(now_epoch)" '
      .monitor = $m | .mix_ws = $mw | .created = $ts
    ')"
  fi
  mix_ws="$(jq -r '.mix_ws' <<<"$state")"

  if jq -e --arg l "$label" '.selection | index($l)' <<<"$state" >/dev/null; then
    # Remove label: move back windows whose orig_ws == label
    local to_return live
    to_return="$(jq -c --arg l "$label" '.windows | map(select(.orig_ws == $l))' <<<"$state")"
    live="$(live_addr_set)"
    jq -r '.[].address' <<<"$to_return" | while IFS= read -r addr; do
      [[ -n "$addr" ]] || continue
      if grep -qx "$addr" <<<"$live"; then
        move_addr_to_ws "$addr" "$label" || true
      fi
    done
    # Drop from state
    state="$(jq -c --arg l "$label" '
      .selection -= [$l]
      | .windows = ( .windows | map(select(.orig_ws != $l)) )
    ' <<<"$state")"
  else
    # Add label
    first_add="$(jq -r '((.selection | length) == 0)' <<<"$state")"
    if [[ "$first_add" == "true" ]]; then
      prev_ws="$(focused_ws_label)"
      state="$(jq -c --arg p "${prev_ws:-}" '
        .prev_ws = (if .prev_ws=="" then $p else .prev_ws end)
      ' <<<"$state")"
    fi

    # Move current windows from that label into mix and record
    local moves_to_add
    moves_to_add="$(clients_from_label_as_moves "$label")"

    hyprctl dispatch workspace "$(ws_token_for_client_move "$mix_ws")" >/dev/null
    jq -r '.[].address' <<<"$moves_to_add" | while IFS= read -r addr; do
      [[ -n "$addr" ]] || continue
      move_addr_to_ws "$addr" "$mix_ws"
    done

    state="$(jq -c --arg l "$label" --argjson add "$moves_to_add" '
      .selection += [$l]
      | .windows = (.windows + $add | unique_by(.address))
    ' <<<"$state")"
  fi

  save_state <<<"$state"
}

# ---------- Main ----------
require_deps
cmd="${1:-status}"

case "$cmd" in
  toggle)
    ws_arg="${2:-}"; [[ -n "$ws_arg" ]] || { err "toggle needs a workspace id/name"; exit 1; }
    label="$(ws_label_from_arg "$ws_arg")"
    apply_toggle_immediate "$label"
    ;;

  restore)
    state="$(load_state)"
    mix_ws="$(jq -r '.mix_ws' <<<"$state")"
    prev_ws="$(jq -r '.prev_ws // ""' <<<"$state")"

    # Return each window to its original workspace
    if [[ -n "$mix_ws" ]]; then
      live="$(live_addr_set)"
      jq -c '.windows[]' <<<"$state" | while IFS= read -r w; do
        addr="$(jq -r '.address' <<<"$w")"
        orig_ws="$(jq -r '.orig_ws' <<<"$w")"
        if grep -qx "$addr" <<<"$live"; then
          move_addr_to_ws "$addr" "$orig_ws" || true
        fi
      done
    fi

    # Clear state and refocus the previous workspace
    save_state <<<"$(empty_state_json)"
    if [[ -n "$prev_ws" ]]; then
      hyprctl dispatch workspace "$(ws_token_for_client_move "$prev_ws")" >/dev/null
    fi
    ;;

  focus)
    state="$(load_state)"
    mix_ws="$(jq -r '.mix_ws' <<<"$state")"
    if [[ -z "$mix_ws" ]] || [[ "$mix_ws" == "null" ]]; then
      mon="$(focused_monitor)"
      state="$(empty_state_json | jq --arg m "$mon" --arg mw "$MIX_NAME" --argjson ts "$(now_epoch)" '
        .monitor = $m | .mix_ws = $mw | .created = $ts
      ')"
      save_state <<<"$state"
      mix_ws="$MIX_NAME"
    fi
    hyprctl dispatch workspace "$(ws_token_for_client_move "$mix_ws")" >/dev/null
    ;;

  build) # backward-compat: just focus mixed view
    "$0" focus
    ;;

  status)
    state="$(load_state)"
    printf 'state_file: %s\n' "$STATE_FILE"
    mix="$(jq -r '.mix_ws // ""' <<<"$state")"
    mon="$(jq -r '.monitor // ""' <<<"$state")"
    prev="$(jq -r '.prev_ws // ""' <<<"$state")"
    sel="$(jq -r '.selection | join(",")' <<<"$state")"
    win_count="$(jq -r '.windows | length' <<<"$state")"
    printf 'mix_ws: %s\nmonitor: %s\nprev_ws: %s\nselection: %s\nwindows: %s\n' "$mix" "$mon" "$prev" "$sel" "$win_count"
    ;;

  doctor)
    printf '== PATH ==\n%s\n\n' "$PATH"
    printf '== which hyprctl ==\n'; command -v hyprctl || true; printf '\n'
    printf '== which jq ==\n'; command -v jq || true; printf '\n'
    printf '== hyprctl monitors ==\n'
    monitors_json | jq '. | map({name, focused, "active": .activeWorkspace.name})' || true
    printf '\n== hyprctl clients (first 5) ==\n'
    clients_json | jq '.[0:5] | map({address, class, title, ws: .workspace})' || true
    printf '\n== current state ==\n'
    "$0" status || true
    ;;

  *)
    err "unknown cmd: %s {toggle <ws>|restore|focus|build|status|doctor}" "$cmd"
    exit 2
    ;;
esac
