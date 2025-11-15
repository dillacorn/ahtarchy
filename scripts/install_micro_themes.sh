#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/scripts
# install_micro_themes.sh
# Purpose: Install Micro editor themes and force-write a valid settings.json on first run.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Preconditions
# ──────────────────────────────────────────────────────────────────────────────
if [[ -z "${SUDO_USER:-}" ]]; then
  echo "Run with sudo so files are owned by the target user."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required."
  exit 1
fi

# Optional but used for verification if present
HAVE_JQ=0
command -v jq >/dev/null 2>&1 && HAVE_JQ=1

# ──────────────────────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────────────────────
REPO_URL1="https://github.com/catppuccin/micro"
REPO_URL2="https://github.com/zyedidia/micro"
TARGET_COLORSCHEME="geany"   # must match a *.micro file name (without extension)

TARGET_USER="${SUDO_USER}"
TARGET_HOME="/home/${TARGET_USER}"
FLATPAK_CONFIG_ROOT="${TARGET_HOME}/.var/app/io.github.zyedidia.micro/config"

# Detect Flatpak Micro without spawning a login shell that triggers dotfiles
if sudo -u "${TARGET_USER}" flatpak info --user io.github.zyedidia.micro >/dev/null 2>&1 || [[ -d "${FLATPAK_CONFIG_ROOT}" ]]; then
  CONFIG_ROOT="${FLATPAK_CONFIG_ROOT}"  # Flatpak location
else
  CONFIG_ROOT="${TARGET_HOME}/.config"  # Native location
fi

MICRO_DIR="${CONFIG_ROOT}/micro"
COLOR_DIR="${MICRO_DIR}/colorschemes"
SETTINGS_JSON="${MICRO_DIR}/settings.json"

# ──────────────────────────────────────────────────────────────────────────────
# Temp dirs and cleanup
# ──────────────────────────────────────────────────────────────────────────────
TMP1="$(mktemp -d)"
TMP2="$(mktemp -d)"
cleanup() { rm -rf "${TMP1}" "${TMP2}"; }
trap cleanup EXIT

umask 022

# ──────────────────────────────────────────────────────────────────────────────
# Clone sources fresh every run
# ──────────────────────────────────────────────────────────────────────────────
echo "Cloning theme sources…"
git clone --depth=1 "${REPO_URL1}" "${TMP1}" >/dev/null
git clone --depth=1 "${REPO_URL2}" "${TMP2}" >/dev/null

# ──────────────────────────────────────────────────────────────────────────────
# Prepare destination and copy themes
# ──────────────────────────────────────────────────────────────────────────────
install -d -m 0755 "${COLOR_DIR}"

# Catppuccin themes layout: repo/themes/*.micro
if compgen -G "${TMP1}/themes/*.micro" >/dev/null; then
  cp -f "${TMP1}/themes/"*.micro "${COLOR_DIR}/"
fi

# Micro runtime themes layout: repo/runtime/colorschemes/*.micro
if compgen -G "${TMP2}/runtime/colorschemes/*.micro" >/dev/null; then
  cp -f "${TMP2}/runtime/colorschemes/"*.micro "${COLOR_DIR}/"
fi

# Ensure ownership
chown -R "${TARGET_USER}:${TARGET_USER}" "${CONFIG_ROOT}"

# ──────────────────────────────────────────────────────────────────────────────
# Force-write settings.json deterministically
# Micro does not create settings.json by itself unless you change a setting.
# We write it now so first run is correct.
# ──────────────────────────────────────────────────────────────────────────────
install -d -m 0755 "${MICRO_DIR}"
cat > "${SETTINGS_JSON}.tmp" <<JSON
{
  "colorscheme": "${TARGET_COLORSCHEME}"
}
JSON

# Basic sanity check on JSON if jq exists
if [[ "${HAVE_JQ}" -eq 1 ]]; then
  jq -e . "${SETTINGS_JSON}.tmp" >/dev/null
fi

mv -f "${SETTINGS_JSON}.tmp" "${SETTINGS_JSON}"
chown "${TARGET_USER}:${TARGET_USER}" "${SETTINGS_JSON}"

# ──────────────────────────────────────────────────────────────────────────────
# Post-verify: settings.json exists and color file present
# ──────────────────────────────────────────────────────────────────────────────
if [[ ! -f "${SETTINGS_JSON}" ]]; then
  echo "Failed to create ${SETTINGS_JSON}"
  exit 1
fi

if [[ ! -f "${COLOR_DIR}/${TARGET_COLORSCHEME}.micro" ]]; then
  echo "Warning: ${TARGET_COLORSCHEME}.micro not found in ${COLOR_DIR}"
  echo "Available schemes:"
  # Use find instead of ls to handle arbitrary filenames (SC2012)
  avail="$(find "${COLOR_DIR}" -maxdepth 1 -type f -name '*.micro' -printf '  - %f\n' | sed 's/\.micro$//')"
  if [[ -n "${avail}" ]]; then
    printf '%s\n' "${avail}"
  else
    echo "  - none"
  fi
fi

echo "Themes installed into: ${COLOR_DIR}"
echo "settings.json written: ${SETTINGS_JSON}"
