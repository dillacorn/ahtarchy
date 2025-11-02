#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/waytrogen_launcher.sh

# Heals GSettings schema drift only when the binary CHANGES (by SHA), not when the version string changes.
# Copies the packaged schema XML into the user schema dir and compiles it, then launches preferring that dir.
# No sudo. No network.

set -euo pipefail

APP_LOGICAL="waytrogen"                 # logical name for your launch_handler toggle
APP_EXEC="waytrogen"                    # resolved at runtime to waytrogen or waytrogen-bin
LAUNCH_HANDLER="${HOME}/.config/hypr/scripts/launch_handler.sh"

SCHEMA_ID="org.Waytrogen.Waytrogen"
REQUIRED_KEY="hide-changer-options-box"

USR_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/glib-2.0/schemas"
SYS_DIRS=(
  "/usr/share/glib-2.0/schemas"
  "/usr/local/share/glib-2.0/schemas"
)

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waytrogen"
SENTINEL="${STATE_DIR}/last_seen_version"  # legacy name; now stores only SHA
mkdir -p "$STATE_DIR" "$USR_DIR"

log(){ [[ "${WAYTROGEN_VERBOSE:-0}" = "1" ]] && printf 'waytrogen-launcher: %s\n' "$*" >&2 || true; }
warn(){ printf 'waytrogen-launcher: %s\n' "$*" >&2; }

notify_err(){
  local msg="$*"
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl notify 3 3500 "rgb(ff4444)" "$msg" >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -a Waytrogen "$msg" || true
  fi
  printf '%s\n' "$msg" >&2
}

resolve_exec(){
  for cand in waytrogen waytrogen-bin; do
    if command -v "$cand" >/dev/null 2>&1; then
      APP_EXEC="$cand"
      return 0
    fi
  done
  return 1
}

bin_path(){ command -v "$APP_EXEC" 2>/dev/null || true; }

get_sha(){
  local bin; bin="$(bin_path)"
  [[ -n "$bin" ]] || { echo ""; return; }
  sha256sum "$bin" 2>/dev/null | awk '{print $1}'
}

get_ver(){
  local bin ver
  bin="$(bin_path)"; [[ -n "$bin" ]] || { echo "unknown"; return; }
  ver="$("$bin" --version 2>/dev/null || true)"
  # Fallback to pacman if --version is odd
  if [[ -z "$ver" || "$ver" =~ ^unknown$ ]]; then
    if command -v pacman >/dev/null 2>&1; then
      ver="$(pacman -Qi "${APP_EXEC}" 2>/dev/null | awk -F': *' '/^Version/{print $2}')"
    fi
  fi
  echo "${ver:-unknown}"
}

migrate_sentinel_to_sha(){
  # Accept old format "ver:...|sha:HEX" or raw HEX. Write back pure HEX.
  local old="$1" parsed
  if [[ -z "$old" ]]; then
    echo ""
    return
  fi
  if [[ "$old" =~ ^[0-9a-fA-F]{32,64}$ ]]; then
    echo "$old"
    return
  fi
  parsed="$(sed -n 's/.*sha:\([0-9a-fA-F]\{32,64\}\).*/\1/p' <<<"$old" | head -n1)"
  echo "$parsed"
}

duplicate_installs_detected(){
  command -v pacman >/dev/null 2>&1 || return 1
  pacman -Qq waytrogen     >/dev/null 2>&1 && \
  pacman -Qq waytrogen-bin >/dev/null 2>&1
}

find_installed_schema(){
  local p
  for d in "${SYS_DIRS[@]}"; do
    p="${d}/${SCHEMA_ID}.gschema.xml"
    [[ -r "$p" ]] && { printf '%s\n' "$p"; return 0; }
  done
  return 1
}

have_key(){ gsettings list-keys "$SCHEMA_ID" 2>/dev/null | grep -qx "$1"; }

compile_user_if_needed(){
  if compgen -G "${USR_DIR}/*.xml" >/dev/null; then
    glib-compile-schemas "$USR_DIR"
  fi
}

install_user_schema_from_system(){
  local src dst
  src="$(find_installed_schema || true)"
  [[ -n "$src" ]] || return 1
  dst="${USR_DIR}/${SCHEMA_ID}.gschema.xml"
  install -Dm0644 "$src" "$dst"
  compile_user_if_needed
  return 0
}

heal_for_new_binary(){
  log "healing: syncing packaged schema into user dir"
  rm -f "${USR_DIR}/${SCHEMA_ID}.gschema.xml" || true
  if ! install_user_schema_from_system; then
    warn "no system schema XML found to copy; launching with system caches only"
  fi
}

launch(){
  local joined="${USR_DIR}"
  for d in "${SYS_DIRS[@]}"; do joined="${joined}:$d"; done
  if [[ -x "$LAUNCH_HANDLER" ]]; then
    GSETTINGS_SCHEMA_DIR="$joined" "$LAUNCH_HANDLER" "$APP_LOGICAL" "$APP_EXEC"
  else
    GSETTINGS_SCHEMA_DIR="$joined" eval "$APP_EXEC" >/dev/null 2>&1 &
  fi
}

# ---------- main ----------

if ! resolve_exec; then
  notify_err "waytrogen not installed"
  exit 1
fi

if duplicate_installs_detected; then
  warn "both 'waytrogen' and 'waytrogen-bin' installed; binary/schema skew is likely. Continuing."
fi

cur_sha="$(get_sha)"
[[ -n "$cur_sha" ]] || { notify_err "could not hash waytrogen binary"; exit 1; }
cur_ver="$(get_ver)"
log "binary sha=$cur_sha ver=${cur_ver}"

prev_raw="$(cat "$SENTINEL" 2>/dev/null || true)"
prev_sha="$(migrate_sentinel_to_sha "$prev_raw")"

# If we migrated an old sentinel format, overwrite with pure SHA for future runs
if [[ -n "$prev_raw" && "$prev_sha" != "$prev_raw" ]]; then
  printf '%s\n' "$prev_sha" > "$SENTINEL"
fi

# Heal only when SHA changed
if [[ "$cur_sha" != "$prev_sha" ]]; then
  log "detected binary change: ${prev_sha:-<none>} -> $cur_sha"
  heal_for_new_binary
  printf '%s\n' "$cur_sha" > "$SENTINEL"
else
  # Cheap sanity: if required key vanished (user cache got poisoned), heal anyway
  if ! have_key "$REQUIRED_KEY"; then
    log "required key not visible; healing without SHA change"
    heal_for_new_binary
  fi
fi

launch
