#!/usr/bin/env bash
# ~/.config/hypr/scripts/wofi-keybinds.sh
set -euo pipefail

# Mode:
#   --auto  -> show once (guarded by persistent marker)
#   default -> always show (for manual hotkey)
MODE="${1:-manual}"

# Persistent per-user marker (XDG_STATE_HOME preferred)
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
mkdir -p "$STATE_DIR"
MARKER="$STATE_DIR/wofi_keybinds_shown"

if [[ "$MODE" == "--auto" ]]; then
  [[ -f "$MARKER" ]] && exit 0
  : > "$MARKER"
fi

CONF="$HOME/.config/hypr/hyprland.conf"

# -----------------------------
# Width calculation (fixes scale)
# -----------------------------
# Uses Hyprland monitor width and scale to compute a LOGICAL pixel width for GTK.
# Defaults:
# - WIDTH is 100% of the focused monitor’s logical width (width / scale)
# - Clamped to [MIN_WIDTH, logical_width - RIGHT_MARGIN]
# Overrides:
# - export WOFI_WIDTH=<int> to force an exact width
# - export WOFI_WIDTH_RATIO=<0.30..0.95> to change the percentage
RIGHT_MARGIN="${WOFI_RIGHT_MARGIN:-120}"    # logical pixels
MIN_WIDTH="${WOFI_MIN_WIDTH:-700}"          # logical pixels
WIDTH_RATIO_DEFAULT="1.00"

get_logical_monowidth() {
  # Output: "<logical_width> <scale>"
  # logical_width = round(width / scale)
  local w s logical
  read -r w s < <(
    hyprctl -j monitors 2>/dev/null | jq -r '
      (map(select(.focused==true)) | .[0]) // .[0] as $m
      | "\($m.width) \($m.scale)"
    '
  )
  # Fallbacks if hyprctl or jq fails
  [[ -z "${w:-}" || -z "${s:-}" ]] && { echo "1000 1.0"; return; }
  # Compute logical width with rounding
  logical="$(awk -v W="$w" -v S="$s" 'BEGIN { printf "%d", (W / S) + 0.5 }')"
  echo "$logical $s"
}

compute_width() {
  # 1) hard override
  if [[ -n "${WOFI_WIDTH:-}" ]]; then
    # sanitize and clamp minimal
    [[ "$WOFI_WIDTH" =~ ^[0-9]+$ ]] || { echo "$MIN_WIDTH"; return; }
    echo "$WOFI_WIDTH"
    return
  fi

  local logical scale ratio candidate maxw
  read -r logical scale < <(get_logical_monowidth)

  # ratio override with sane bounds
  ratio="${WOFI_WIDTH_RATIO:-$WIDTH_RATIO_DEFAULT}"
  # validate float in [0.30, 0.95]
  if ! awk -v r="$ratio" 'BEGIN{exit !(r+0>=0.30 && r+0<=0.95)}'; then
    ratio="$WIDTH_RATIO_DEFAULT"
  fi

  # candidate width from ratio
  candidate="$(awk -v L="$logical" -v R="$ratio" 'BEGIN { printf "%d", L*R }')"

  # dynamic max is monitor logical width minus a right margin
  maxw="$(awk -v L="$logical" -v M="$RIGHT_MARGIN" '
    BEGIN { m = L - M; if (m < 1) m = 1; printf "%d", m }
  ')"

  # clamp
  if (( candidate < MIN_WIDTH )); then
    candidate="$MIN_WIDTH"
  fi
  if (( candidate > maxw )); then
    candidate="$maxw"
  fi

  echo "$candidate"
}

WIDTH="$(compute_width)"

# -----------------------------
# Minimal CSS to silence GTK warnings
# -----------------------------
STYLE_FILE="$(mktemp --suffix=.css)"
trap 'rm -f "$STYLE_FILE"' EXIT
cat > "$STYLE_FILE" <<'EOF'
window {}
EOF

# -----------------------------
# Read modifiers from hyprland.conf
# -----------------------------
mod=$(awk -F= '/^\$mod[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)
super=$(awk -F= '/^\$super[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)
rotate=$(awk -F= '/^\$rotate[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)

# -----------------------------
# Pango escaping
# -----------------------------
escape_pango() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# -----------------------------
# Expand hypr vars
# -----------------------------
expand_vars() {
  local smod=${mod//\\/\\\\};    smod=${smod//&/\\&}
  local ssuper=${super//\\/\\\\}; ssuper=${ssuper//&/\\&}
  local srotate=${rotate//\\/\\\\}; srotate=${srotate//&/\\&}
  sed -e "s/\\\$mod\\b/${smod}/g" \
      -e "s/\\\$super\\b/${ssuper}/g" \
      -e "s/\\\$rotate\\b/${srotate}/g"
}

# -----------------------------
# Split by commas respecting quotes
# -----------------------------
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

pretty_cmd() {  # keep dispatcher unless exec
  local disp="$1"; shift
  if [ "$disp" = "exec" ]; then printf "%s" "$*"; else printf "%s %s" "$disp" "$*"; fi
}

# -----------------------------
# Generate menu content
# -----------------------------
generate() {
  local current_category="" printed=0

  while IFS= read -r raw; do
    raw="${raw#"${raw%%[![:space:]]*}"}"
    raw="${raw%"${raw##*[![:space:]]}"}"
    [ -z "$raw" ] && continue

    # category: only lines starting with "# "
    if [[ "$raw" =~ ^#[[:space:]]+(.+) ]]; then
      current_category="${BASH_REMATCH[1]}"
      printed=0
      continue
    fi

    # bind lines
    if [[ "$raw" =~ ^bind[a-z]*[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      line_expanded=$(printf '%s\n' "${BASH_REMATCH[1]}" | expand_vars)

      # fields
      mapfile -d '' fields < <(printf '%s\n' "$line_expanded" | split_commas)
      [ "${#fields[@]}" -ge 3 ] || continue

      mods="${fields[0]}"
      key="${fields[1]}"
      rem=$(printf '%s\0' "${fields[@]:2}" | tr '\0' ' ' | sed 's/[[:space:]]\+$//')

      disp=$(printf '%s\n' "$rem" | awk '{print $1}')
      args=$(printf '%s\n' "$rem" | sed 's/^[^[:space:]]\+[[:space:]]*//')

      if [ -n "$current_category" ] && [ $printed -eq 0 ]; then
        printf '<span size="16000" weight="bold" foreground="#f38ba8">%s</span>\n' \
          "$(printf '%s' "$current_category" | escape_pango)"
        printed=1
      fi

      combo="${mods// /+}+${key}"
      shown=$(pretty_cmd "$disp" "$args")

      combo_e=$(printf '%s' "$combo" | escape_pango)
      shown_e=$(printf '%s' "$shown" | escape_pango)

      printf '<span size="14000" weight="bold" foreground="#f9e2af">%-30s</span> → <span size="14000" foreground="#a6e3a1">%s</span>\n' \
        "$combo_e" "$shown_e"
    fi
  done < "$CONF"
}

out=$(generate || true)

# -----------------------------
# Render
# -----------------------------
if [[ -z "${out//[$'\n' ]/}" ]]; then
  wofi --dmenu --prompt "No keybinds found" --width "$WIDTH" --style "$STYLE_FILE"
else
  printf '%s\n' "$out" | wofi --dmenu --allow-markup --prompt "Hyprland Keybinds" --width "$WIDTH" --style "$STYLE_FILE"
fi
