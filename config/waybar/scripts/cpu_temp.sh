# ~/.config/waybar/scripts/cpu_temp.sh
#!/usr/bin/env bash
# CPU temp for Waybar custom module with icon on the right side
# Prints: "<temp>°<icon>"

set -euo pipefail
export LC_ALL=C

PREF_CHIPS=(k10temp coretemp zenpower cpu_thermal x86_pkg_temp)

trim() { sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//'; }

pick_hwmon_dir() {
  for d in /sys/class/hwmon/*; do
    [[ -r "$d/name" ]] || continue
    name="$(<"$d/name")"
    for want in "${PREF_CHIPS[@]}"; do
      [[ "$name" == "$want" ]] && { echo "$d"; return 0; }
    done
  done
  return 1
}

read_hwmon_celsius() {
  local d="$1"
  declare -A map=()
  shopt -s nullglob
  local f lbl inp val

  for f in "$d"/temp*_label; do
    lbl="$(tr -d '\0\r' < "$f" | trim)"
    inp="${f/_label/_input}"
    [[ -r "$inp" ]] || continue
    map["$lbl"]="$inp"
  done

  local prefs=("Tdie" "Tctl/Tdie" "Package id 0" "Package" "CPU Temp" "Core 0" "Tctl")
  local p
  for p in "${prefs[@]}"; do
    if [[ -n "${map[$p]:-}" ]]; then
      val="$(<"${map[$p]}")"
      [[ "$val" =~ ^[0-9]+$ ]] && { printf '%d\n' "$((val/1000))"; return 0; }
    fi
  done

  for inp in "$d"/temp*_input; do
    [[ -r "$inp" ]] || continue
    val="$(<"$inp")"
    [[ "$val" =~ ^[0-9]+$ ]] && { printf '%d\n' "$((val/1000))"; return 0; }
  done
  return 1
}

get_temp() {
  local d
  if d="$(pick_hwmon_dir)"; then
    read_hwmon_celsius "$d" && return 0
  fi
  for d in /sys/class/thermal/thermal_zone*; do
    local t="$d/temp"
    [[ -r "$t" ]] || continue
    local v
    v="$(<"$t")"
    [[ "$v" =~ ^[0-9]+$ ]] || continue
    if (( v >= 1000 )); then
      printf '%d\n' "$((v/1000))"
      return 0
    else
      printf '%d\n' "$v"
      return 0
    fi
  done
  printf 'N/A\n'
  return 0
}

main() {
  local temp
  temp="$(get_temp)"
  if [[ "$temp" == "N/A" ]]; then
    echo "N/A"
    exit 0
  fi

  local icon
  if (( temp < 40 )); then
    icon=""
  elif (( temp < 70 )); then
    icon=""
  else
    icon=""
  fi

  # icon on the right
  echo "$temp°$icon"
}

main
