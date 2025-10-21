#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/waytrogen-toggle.sh

# Toggle only the FLOATING Waytrogen window. Never kills tiled windows.
# Logic:
#   - If a FLOATING Waytrogen is on the current workspace: close just that window.
#   - Else if FLOATING Waytrogen exists elsewhere/hidden: close those windows, then launch a fresh one here.
#   - Else: launch a fresh one here.

set -euo pipefail

# Matchers (cover common class/title variants)
CLASS_CANDIDATES=(
  "Waytrogen"
  "waytrogen"
  "org.Waytrogen.Waytrogen"
  "org.waytrogen.Waytrogen"
)
TITLE_REGEX="Waytrogen"

# --- Requirements ---
command -v hyprctl >/dev/null 2>&1 || { echo "hyprctl not found"; exit 1; }
command -v jq      >/dev/null 2>&1 || { echo "jq not found"; exit 1; }

# --- Helpers ---
launch_new() {
  setsid waytrogen >/dev/null 2>&1 < /dev/null &
}

# Build jq OR expression for class/title matching
jq_match_expr() {
  local expr=""
  for c in "${CLASS_CANDIDATES[@]}"; do
    expr+="(.class==\"$c\") or (.initialClass==\"$c\") or "
  done
  expr+="(.title|tostring|test(\"$TITLE_REGEX\"))"
  printf '%s' "$expr"
}

MATCH_EXPR="$(jq_match_expr)"

# Snapshot state
WS_ID="$(hyprctl activeworkspace -j 2>/dev/null | jq -r 'try .id // 0')"
CLIENTS_JSON="$(hyprctl clients -j 2>/dev/null || printf '[]')"

# Collect floating Waytrogen window ADDRESSES (not PIDs) for precise close
HERE_FLOAT_ADDRS="$(
  printf '%s' "$CLIENTS_JSON" | jq -r --argjson ws "$WS_ID" "
    .[]?
    | select( ($MATCH_EXPR)
              and (.mapped//true)
              and ((.floating//false)==true)
              and ((.hidden//false)==false)
              and ((.workspace.id//-1)==\$ws) )
    | .address
  "
)"

ELSEWHERE_FLOAT_ADDRS="$(
  printf '%s' "$CLIENTS_JSON" | jq -r --argjson ws "$WS_ID" "
    .[]?
    | select( ($MATCH_EXPR)
              and (.mapped//true)
              and ((.floating//false)==true)
              and ( ((.workspace.id//-1)!=\$ws) or ((.hidden//false)==true) ) )
    | .address
  "
)"

# Close helper: close specific windows by address (avoids killing other Waytrogen windows)
close_by_addresses() {
  local addr
  while IFS= read -r addr; do
    [ -n "$addr" ] || continue
    hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1 || true
  done
}

# Actions
if [ -n "$HERE_FLOAT_ADDRS" ]; then
  printf '%s\n' "$HERE_FLOAT_ADDRS" | close_by_addresses
  exit 0
fi

if [ -n "$ELSEWHERE_FLOAT_ADDRS" ]; then
  printf '%s\n' "$ELSEWHERE_FLOAT_ADDRS" | close_by_addresses
  launch_new
  exit 0
fi

launch_new
