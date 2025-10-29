#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/scripts
# install_flatpak_apps.sh
# Arch-only. Run as root. Installs Flatpak and a curated set of apps with sane defaults.

set -Eeuo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# CONFIG: edit these
# ──────────────────────────────────────────────────────────────────────────────

# App IDs to install (Flathub IDs). Add/remove here.
FLATPAK_APPS=(
  "com.github.tchx84.Flatseal"
  # "dev.vencord.Vesktop"
  # "com.moonlight_stream.Moonlight"
)

# Scope: "auto" = user if root FS not btrfs, system if btrfs. Or force "user" | "system".
INSTALL_SCOPE="auto"

# Ask before installing. 1 = prompt, 0 = no prompt.
ASK_CONFIRM=1

# Apply Vesktop override (disable X11 socket) if Vesktop is installed in chosen scope.
APPLY_VESKTOP_OVERRIDE=1

# Configure UFW firewall for NDI ports. 1 = enable, 0 = skip. Requires ufw installed.
CONFIGURE_NDI_UFW=1

# If Moonlight (Flatpak) is installed in chosen scope, also open its ports via UFW.
CONFIGURE_MOONLIGHT_UFW=1

# Remote to install from.
FLATPAK_REMOTE_NAME="flathub"
FLATPAK_REMOTE_URL="https://flathub.org/repo/flathub.flatpakrepo"

# ──────────────────────────────────────────────────────────────────────────────
# COLORS
# ──────────────────────────────────────────────────────────────────────────────
CYAN_B=$'\033[1;96m'
CYAN=$'\033[0;36m'
YELLOW=$'\033[0;93m'
RED_B=$'\033[1;31m'
RESET=$'\033[0m'
GREEN=$'\033[0;32m'
PURPLE=$'\033[0;35m'

# ──────────────────────────────────────────────────────────────────────────────
# ROOT CHECK
# ──────────────────────────────────────────────────────────────────────────────
if [[ "${EUID}" -ne 0 ]]; then
  printf '%s\n' "This script must be run as root!" >&2
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────────
# TARGET USER DISCOVERY (for user-scope installs)
# ──────────────────────────────────────────────────────────────────────────────
detect_target_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s' "${SUDO_USER}"
    return 0
  fi
  # Fallback to the first non-system user with UID >= 1000
  local u
  u="$(awk -F: '$3>=1000 && $1!="nobody"{print $1; exit}' /etc/passwd || true)"
  if [[ -n "${u}" ]]; then
    printf '%s' "${u}"
    return 0
  fi
  # Last-ditch attempt: logname (may fail in non-interactive contexts)
  if command -v logname >/dev/null 2>&1; then
    u="$(logname 2>/dev/null || true)"
    if [[ -n "${u}" && "${u}" != "root" ]]; then
      printf '%s' "${u}"
      return 0
    fi
  fi
  printf '%s\n' "Unable to determine a non-root target user for --user Flatpak installs." >&2
  exit 1
}

TARGET_USER="$(detect_target_user)"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  printf '%s\n' "Home directory for ${TARGET_USER} not found." >&2
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────────
# CHOOSE SCOPE
# ──────────────────────────────────────────────────────────────────────────────
ROOT_FS_TYPE="$(df -T / | awk 'NR==2 {print $2}')"
case "${INSTALL_SCOPE}" in
  auto)
    if [[ "${ROOT_FS_TYPE}" == "btrfs" ]]; then
      EFFECTIVE_SCOPE="system"
    else
      EFFECTIVE_SCOPE="user"
    fi
    ;;
  user|system)
    EFFECTIVE_SCOPE="${INSTALL_SCOPE}"
    ;;
  *)
    printf '%s\n' "Invalid INSTALL_SCOPE: ${INSTALL_SCOPE}. Use auto|user|system." >&2
    exit 1
    ;;
esac

# ──────────────────────────────────────────────────────────────────────────────
# FLATPAK + UFW AVAILABILITY
# ──────────────────────────────────────────────────────────────────────────────
if ! command -v flatpak >/dev/null 2>&1; then
  printf '%s\n' "${PURPLE}Flatpak is not installed. Installing Flatpak...${RESET}"
  pacman -S --needed --noconfirm flatpak
fi

UFW_AVAILABLE=0
if command -v ufw >/dev/null 2>&1; then
  UFW_AVAILABLE=1
fi

# ──────────────────────────────────────────────────────────────────────────────
# RUN HELPERS
# ──────────────────────────────────────────────────────────────────────────────
# Wrapper to run Flatpak in the correct scope as the correct user.
run_flatpak() {
  if [[ "${EFFECTIVE_SCOPE}" == "user" ]]; then
    # Always add --user for consistency
    runuser -u "${TARGET_USER}" -- flatpak --user "$@"
  else
    flatpak "$@"
  fi
}

# Check if an app ID is installed in the chosen scope.
is_installed() {
  local app_id="$1"
  # Use exact column match to avoid false positives
  run_flatpak list --app --columns=application | grep -Fxq "${app_id}"
}

# ──────────────────────────────────────────────────────────────────────────────
# REMOTE SETUP
# ──────────────────────────────────────────────────────────────────────────────
ensure_remote() {
  # Add flathub in chosen scope if missing
  if ! run_flatpak remotes --columns=name | grep -Fxq "${FLATPAK_REMOTE_NAME}"; then
    run_flatpak remote-add --if-not-exists "${FLATPAK_REMOTE_NAME}" "${FLATPAK_REMOTE_URL}"
  fi
}
ensure_remote

# ──────────────────────────────────────────────────────────────────────────────
# OPTIONAL SHELL ALIAS: force user installs on non-btrfs systems
# ──────────────────────────────────────────────────────────────────────────────
if [[ "${EFFECTIVE_SCOPE}" == "user" ]]; then
  alias_line='alias flatpak="flatpak --user"'
  for shell_rc in ".bashrc" ".zshrc"; do
    rc_path="${TARGET_HOME}/${shell_rc}"
    if [[ -f "${rc_path}" ]]; then
      if ! grep -Fxq "${alias_line}" "${rc_path}"; then
        {
          printf '\n# Automatically apply --user flag for Flatpak on non-Btrfs or user-scope systems\n'
          printf '%s\n' "${alias_line}"
        } >> "${rc_path}"
        chown "${TARGET_USER}:${TARGET_USER}" "${rc_path}"
        printf '%s\n' "${GREEN}Appended Flatpak alias to ${rc_path}${RESET}"
      else
        printf '%s\n' "${YELLOW}Flatpak alias already present in ${rc_path}. Skipping...${RESET}"
      fi
    fi
  done
fi

# ──────────────────────────────────────────────────────────────────────────────
# CONFIRM
# ──────────────────────────────────────────────────────────────────────────────
if [[ "${ASK_CONFIRM}" -eq 1 ]]; then
  printf '%s' "${CYAN_B}Install selected Flatpak applications in ${EFFECTIVE_SCOPE} scope? (y/n) ${RESET}"
  read -r -n 1 REPLY
  printf '\n'
  if [[ ! "${REPLY}" =~ ^[Yy]$ ]]; then
    printf '%s\n' "${YELLOW}Canceled by user.${RESET}"
    exit 0
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# UPDATE EXISTING APPS IN CHOSEN SCOPE
# ──────────────────────────────────────────────────────────────────────────────
printf '%s\n' "${GREEN}Updating installed Flatpak apps in ${EFFECTIVE_SCOPE} scope...${RESET}"
run_flatpak update -y || true

# ──────────────────────────────────────────────────────────────────────────────
# INSTALL APPS
# ──────────────────────────────────────────────────────────────────────────────
install_with_retries() {
  local app="$1" retries=3 count=0
  while ! is_installed "${app}"; do
    if (( count >= retries )); then
      printf '%s\n' "${RED_B}Failed to install ${app} after ${retries} attempts. Skipping...${RESET}"
      return 1
    fi
    printf '%s\n' "${GREEN}Installing ${app} (Attempt $((count + 1))/${retries})...${RESET}"
    if run_flatpak install -y "${FLATPAK_REMOTE_NAME}" "${app}"; then
      printf '%s\n' "${GREEN}${app} installed successfully.${RESET}"
      return 0
    fi
    printf '%s\n' "${RED_B}Install failed for ${app}. Retrying...${RESET}"
    ((count++))
    sleep 2
  done
  return 0
}

printf '%s\n' "${GREEN}Installing selected Flatpak apps...${RESET}"
for app in "${FLATPAK_APPS[@]}"; do
  if is_installed "${app}"; then
    printf '%s\n' "${YELLOW}${app} is already installed. Skipping...${RESET}"
  else
    install_with_retries "${app}" || true
  fi
done

# ──────────────────────────────────────────────────────────────────────────────
# OPTIONAL: VESKTOP OVERRIDE
# ──────────────────────────────────────────────────────────────────────────────
if (( APPLY_VESKTOP_OVERRIDE == 1 )); then
  if is_installed "dev.vencord.Vesktop"; then
    printf '%s\n' "${CYAN}Applying Flatpak override for Vesktop to disable X11 socket...${RESET}"
    run_flatpak override --nosocket=x11 dev.vencord.Vesktop || true
  else
    printf '%s\n' "${YELLOW}Vesktop not installed in ${EFFECTIVE_SCOPE} scope. Skipping X11 override.${RESET}"
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# OPTIONAL: UFW RULES FOR NDI AND MOONLIGHT
# ──────────────────────────────────────────────────────────────────────────────
if (( CONFIGURE_NDI_UFW == 1 )); then
  if (( UFW_AVAILABLE == 1 )); then
    printf '%s\n' "${CYAN}Configuring UFW rules for NDI...${RESET}"
    ufw allow 5353/udp            || true  # mDNS discovery
    ufw allow 5959:5969/tcp       || true  # Core NDI (TCP)
    ufw allow 5959:5969/udp       || true  # Core NDI (UDP)
    ufw allow 6960:6970/tcp       || true  # WAN streaming (TCP)
    ufw allow 6960:6970/udp       || true  # WAN streaming (UDP)
    ufw allow 7960:7970/tcp       || true  # Metadata/audio/etc (TCP)
    ufw allow 7960:7970/udp       || true  # Metadata/audio/etc (UDP)
    ufw allow 5960/tcp            || true  # Optional explicit NDI Remote port
    printf '%s\n' "${GREEN}UFW rules for NDI configured.${RESET}"
  else
    printf '%s\n' "${YELLOW}ufw not installed. Skipping NDI firewall configuration.${RESET}"
  fi
fi

if (( CONFIGURE_MOONLIGHT_UFW == 1 )); then
  if (( UFW_AVAILABLE == 1 )); then
    if is_installed "com.moonlight_stream.Moonlight"; then
      printf '%s\n' "${CYAN}Moonlight detected. Configuring UFW rules for Moonlight...${RESET}"
      ufw allow 48010/tcp || true
      ufw allow 48000/udp || true
      ufw allow 48010/udp || true
      printf '%s\n' "${GREEN}UFW rules for Moonlight configured.${RESET}"
    else
      printf '%s\n' "${YELLOW}Moonlight not installed in ${EFFECTIVE_SCOPE} scope. Skipping Moonlight firewall rules.${RESET}"
    fi
  else
    printf '%s\n' "${YELLOW}ufw not installed. Skipping Moonlight firewall configuration.${RESET}"
  fi
fi

printf '%s\n' "${PURPLE}Flatpak setup and installation complete.${RESET}"
