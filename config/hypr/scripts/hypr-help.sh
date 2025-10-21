#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/config/hypr/scripts
# ~/.config/hypr/scripts/hypr-help.sh
set -euo pipefail

# Run modes:
#   --auto  -> show once on first login (creates marker and exits next time)
#   default -> always show (for manual keybind)
MODE="${1:-manual}"

# Marker to prevent repeat in --auto mode
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
mkdir -p "$STATE_DIR"
MARKER="$STATE_DIR/hypr_help_shown"
if [[ "$MODE" == "--auto" ]]; then
  [[ -f "$MARKER" ]] && exit 0
  : > "$MARKER"
fi

CONF="$HOME/.config/hypr/hyprland.conf"

# -------- Width (scale-aware, simple tunables) --------
RIGHT_MARGIN="${WOFI_RIGHT_MARGIN:-120}"
MIN_WIDTH="${WOFI_MIN_WIDTH:-700}"
WIDTH_RATIO_DEFAULT="0.60"  # default = use full logical width minus margin

get_logical_width() {
  local w s L
  read -r w s < <(
    hyprctl -j monitors 2>/dev/null | jq -r '
      (map(select(.focused==true)) | .[0]) // .[0] as $m
      | "\($m.width) \($m.scale)"
    ' || echo "1000 1.0"
  )
  [[ -z "${w:-}" || -z "${s:-}" ]] && { echo 1000; return; }
  L="$(awk -v W="$w" -v S="$s" 'BEGIN{ printf "%d", (W/S)+0.5 }')"
  echo "$L"
}

compute_width() {
  [[ -n "${WOFI_WIDTH:-}" && "$WOFI_WIDTH" =~ ^[0-9]+$ ]] && { echo "$WOFI_WIDTH"; return; }

  local L ratio candidate maxw
  L="$(get_logical_width)"
  ratio="${WOFI_WIDTH_RATIO:-$WIDTH_RATIO_DEFAULT}"
  # clamp ratio to sane bounds
  if ! awk -v r="$ratio" 'BEGIN{exit !(r+0>=0.30 && r+0<=1.00)}'; then
    ratio="$WIDTH_RATIO_DEFAULT"
  fi

  candidate="$(awk -v LL="$L" -v R="$ratio" 'BEGIN{printf "%d", LL*R}')"
  maxw="$(awk -v LL="$L" -v M="$RIGHT_MARGIN" 'BEGIN{m=LL-M; if(m<1)m=1; printf "%d", m}')"

  (( candidate < MIN_WIDTH )) && candidate="$MIN_WIDTH"
  (( candidate > maxw )) && candidate="$maxw"
  echo "$candidate"
}

WIDTH="$(compute_width)"

# -------- Minimal CSS (silences GTK warnings) --------
STYLE_FILE="$(mktemp --suffix=.css)"
trap 'rm -f "$STYLE_FILE"' EXIT
printf 'window {}\n' > "$STYLE_FILE"

# -------- Hypr var reads --------
mod=$(awk -F= '/^\$mod[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)
super=$(awk -F= '/^\$super[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)
rotate=$(awk -F= '/^\$rotate[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)

# -------- Helpers --------
escape_pango() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

expand_vars() {
  local smod=${mod//\\/\\\\};    smod=${smod//&/\\&}
  local ssuper=${super//\\/\\\\}; ssuper=${ssuper//&/\\&}
  local srotate=${rotate//\\/\\\\}; srotate=${srotate//&/\\&}
  sed -e "s/\\\$mod\\b/${smod}/g" \
      -e "s/\\\$super\\b/${ssuper}/g" \
      -e "s/\\\$rotate\\b/${srotate}/g"
}

split_commas() {
  awk '
  function trim(s){sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/,"",s); return s}
  {
    line=$0; q=0; sq=0; field="";
    for(i=1;i<=length(line);i++){
      c=substr(line,i,1)
      if(c=="\"" && sq==0){q=!q; field=field c; continue}
      if(c=="\047" && q==0){sq=!sq; field=field c; continue}
      if(c=="," && q==0 && sq==0){printf "%s\0", trim(field); field=""; continue}
      field=field c
    }
    printf "%s", trim(field)
  }'
}

pretty_cmd() { local d="$1"; shift; [[ "$d" = exec ]] && printf "%s" "$*" || printf "%s %s" "$d" "$*"; }

# -------- Build output from binds --------
generate() {
  local category="" printed=0

  while IFS= read -r raw; do
    raw="${raw#"${raw%%[![:space:]]*}"}"; raw="${raw%"${raw##*[![:space:]]}"}"
    [[ -z "$raw" ]] && continue

    if [[ "$raw" =~ ^#[[:space:]]+(.+) ]]; then
      category="${BASH_REMATCH[1]}"; printed=0; continue
    fi

    if [[ "$raw" =~ ^bind[a-z]*[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      line_expanded=$(printf '%s\n' "${BASH_REMATCH[1]}" | expand_vars)
      mapfile -d '' fields < <(printf '%s\n' "$line_expanded" | split_commas)
      (( ${#fields[@]} >= 3 )) || continue

      mods="${fields[0]}"; key="${fields[1]}"
      rem=$(printf '%s\0' "${fields[@]:2}" | tr '\0' ' ' | sed 's/[[:space:]]\+$//')
      disp=$(printf '%s\n' "$rem" | awk '{print $1}')
      args=$(printf '%s\n' "$rem" | sed 's/^[^[:space:]]\+[[:space:]]*//')

      if [[ -n "$category" && $printed -eq 0 ]]; then
        printf '<span size="16000" weight="bold" foreground="#f38ba8">%s</span>\n' \
          "$(printf '%s' "$category" | escape_pango)"
        printed=1
      fi

      combo_e=$(printf '%s' "${mods// /+}+${key}" | escape_pango)
      shown_e=$(printf '%s' "$(pretty_cmd "$disp" "$args")" | escape_pango)

      printf '<span size="14000" weight="bold" foreground="#f9e2af">%-30s</span> → <span size="14000" foreground="#a6e3a1">%s</span>\n' \
        "$combo_e" "$shown_e"
    fi
  done < "$CONF"
}

out=$(generate || true)

# -------- Render --------
if [[ -z "${out//[$'\n' ]/}" ]]; then
  wofi --dmenu --prompt "No keybinds found" --width "$WIDTH" --style "$STYLE_FILE"
else
  printf '%s\n' "$out" | wofi --dmenu --allow-markup --prompt "Hyprland Keybinds" --width "$WIDTH" --style "$STYLE_FILE"
fi
