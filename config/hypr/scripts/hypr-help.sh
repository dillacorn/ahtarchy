#!/usr/bin/env bash
set -euo pipefail

# mode:
#   --auto  -> show once per session (guarded by /tmp marker)
#   default -> always show (for manual hotkey)
MODE="${1:-manual}"

MARKER="/tmp/wofi_keybinds_shown"
if [[ "$MODE" == "--auto" ]]; then
  [[ -f "$MARKER" ]] && exit 0
  : > "$MARKER"
fi

CONF="$HOME/.config/hypr/hyprland.conf"

# --- dynamic width from focused monitor (hyprctl monitors -j) ---
MARGIN=120
MIN_WIDTH=700
MAX_WIDTH=1800

get_width() {
  local w
  w=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused==true) | .width' || true)
  [ -z "${w:-}" ] && w=$(hyprctl -j monitors 2>/dev/null | jq -r '.[0].width' || true)
  [[ "$w" =~ ^[0-9]+$ ]] || w=1000
  w=$(( w - MARGIN ))
  (( w < MIN_WIDTH )) && w=$MIN_WIDTH
  (( w > MAX_WIDTH )) && w=$MAX_WIDTH
  printf '%d\n' "$w"
}
WIDTH="$(get_width)"

# --- minimal CSS to avoid GTK theme parser warnings; no theming changes ---
STYLE_FILE="$(mktemp --suffix=.css)"
cat > "$STYLE_FILE" <<'EOF'
window {}
EOF

# --- read modifiers ---
mod=$(awk -F= '/^\$mod[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)
super=$(awk -F= '/^\$super[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)
rotate=$(awk -F= '/^\$rotate[[:space:]]*=/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}' "$CONF" || true)

# --- escape for Pango markup ---
escape_pango() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# --- expand hypr vars ---
expand_vars() {
  local smod=${mod//\\/\\\\};   smod=${smod//&/\\&}
  local ssuper=${super//\\/\\\\}; ssuper=${ssuper//&/\\&}
  local srotate=${rotate//\\/\\\\}; srotate=${srotate//&/\\&}
  sed -e "s/\\\$mod\\b/${smod}/g" \
      -e "s/\\\$super\\b/${ssuper}/g" \
      -e "s/\\\$rotate\\b/${srotate}/g"
}

# --- split by commas while respecting quotes ---
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

if [[ -z "${out//[$'\n' ]/}" ]]; then
  wofi --dmenu --prompt "No keybinds found" --width "$WIDTH" --style "$STYLE_FILE"
else
  printf '%s\n' "$out" | wofi --dmenu --allow-markup --prompt "Hyprland Keybinds" --width "$WIDTH" --style "$STYLE_FILE"
fi

rm -f "$STYLE_FILE"
