#!/usr/bin/env bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

# Set the target user (who invoked the script with sudo)
target_user="${SUDO_USER:-$(logname)}"
target_home="/home/$target_user"

# Flatpak installation and setup script

# Color Variables
CYAN_B='\033[1;96m'
YELLOW='\033[0;93m'
RED_B='\033[1;31m'
RESET='\033[0m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'

# Remote origin to use for installations
flatpak_origin='flathub'

# List of desktop apps to be installed (specified by app ID)
flatpak_apps=(
  'com.valvesoftware.Steam'
  'com.github.IsmaelMartinez.teams_for_linux'
  'dev.vencord.Vesktop'
  'org.telegram.desktop'
  'com.spotify.Client'
  'io.itch.itch'
  'com.heroicgameslauncher.hgl'
  'com.ultimaker.cura'
  'com.dec05eba.gpu_screen_recorder'
  'com.obsproject.Studio'
  'com.obsproject.Studio.Plugin.DistroAV'
  'io.github.libvibrant.vibrantLinux'
  'com.rustdesk.RustDesk'
  'org.localsend.localsend_app'
  'net.davidotek.pupgui2'
  'dev.lizardbyte.app.Sunshine'
  'com.moonlight_stream.Moonlight'
  'net.mullvad.MullvadBrowser'
  'io.github.ungoogled_software.ungoogled_chromium'
  'com.github.tchx84.Flatseal'
  'dev.deedles.Trayscale'
  'com.github.wwmm.easyeffects'
  'io.github.seadve.Kooha'
)

# Detect file system type of the root partition
root_fs_type=$(df -T / | awk 'NR==2 {print $2}')

# Determine whether to use the --user flag
if [[ "$root_fs_type" == "btrfs" ]]; then
  flatpak_user_flag=""
else
  flatpak_user_flag="--user"
fi

# Add Flatpak alias to .bashrc if not using Btrfs
if [[ "$root_fs_type" != "btrfs" ]]; then
  bashrc_path="$target_home/.bashrc"
  alias_line="alias flatpak='flatpak --user'"

  # Append alias only if it doesn't already exist
  if ! grep -Fxq "$alias_line" "$bashrc_path"; then
    echo -e "\n# Automatically apply --user flag for Flatpak on non-Btrfs systems\n$alias_line" >> "$bashrc_path"
    chown "$target_user:$target_user" "$bashrc_path"
    echo -e "${GREEN}Appended Flatpak alias to ${bashrc_path}${RESET}"
  else
    echo -e "${YELLOW}Flatpak alias already present in ${bashrc_path}. Skipping...${RESET}"
  fi
fi

# Check if Flatpak is installed; if not, install it via Pacman
if ! command -v flatpak &> /dev/null; then
  echo -e "${PURPLE}Flatpak is not installed. Installing Flatpak...${RESET}"
  pacman -S --needed --noconfirm flatpak
fi

if [[ -n "$flatpak_user_flag" ]]; then
  echo -e "${GREEN}Ensuring Flathub repository is available for user-level installations...${RESET}"
  runuser -u "$target_user" -- flatpak $flatpak_user_flag remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Prompt the user to proceed with installation
echo -e "${CYAN_B}Would you like to install Dillacorn's chosen Flatpak applications? (y/n)${RESET}"
read -n 1 -r REPLY
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Flatpak setup and install canceled by the user...${RESET}"
  exit 0
fi

# Update currently installed Flatpak apps (as the non-root user)
echo -e "${GREEN}Updating installed Flatpak apps...${RESET}"
runuser -u "$target_user" -- flatpak $flatpak_user_flag update -y

# Retry logic for Flatpak installation
install_flatpak_app() {
  local app="$1"
  local retries=3
  local count=0
  while ! runuser -u "$target_user" -- flatpak $flatpak_user_flag list --app | grep -q "${app}"; do
    if [ $count -ge $retries ]; then
      echo -e "${RED_B}Failed to install ${app} after $retries attempts. Skipping...${RESET}"
      return 1
    fi
    echo -e "${GREEN}Installing ${app} (Attempt $((count + 1))/${retries})...${RESET}"
    
    # Install the Flatpak app as the non-root user
    if runuser -u "$target_user" -- flatpak $flatpak_user_flag install -y "$flatpak_origin" "$app"; then
      echo -e "${GREEN}${app} installed successfully.${RESET}"
      break
    else
      install_status=$?
      if [ "$install_status" -eq 0 ]; then
        echo -e "${YELLOW}${app} is already installed. Skipping...${RESET}"
        break
      else
        echo -e "${RED_B}Failed to install ${app}. Retrying...${RESET}"
        count=$((count + 1))
        sleep 2
      fi
    fi
  done
}

# Install apps from the list (as the non-root user)
echo -e "${GREEN}Installing selected Flatpak apps...${RESET}"
for app in "${flatpak_apps[@]}"; do
  if ! runuser -u "$target_user" -- flatpak $flatpak_user_flag list --app | grep -q "${app}"; then
    install_flatpak_app "${app}"
  else
    echo -e "${YELLOW}${app} is already installed. Skipping...${RESET}"
  fi
done

# Configure firewall rules for NDI (as root, since this requires system-level changes)
echo -e "${CYAN}Configuring firewall rules for NDI...${RESET}"

# Add firewall rules for NDI (ports 5959-5969, 6960-6970, 7960-7970 for TCP and UDP, and 5353 for mDNS)
echo -e "${CYAN}Adding firewall rules...${RESET}"
ufw allow 5353/udp
ufw allow 5959:5969/tcp
ufw allow 5959:5969/udp
ufw allow 6960:6970/tcp
ufw allow 6960:6970/udp
ufw allow 7960:7970/tcp
ufw allow 7960:7970/udp
ufw allow 5960/tcp

echo -e "${GREEN}Firewall rules for NDI configured successfully.${RESET}"

echo -e "${PURPLE}Flatpak setup and installation complete.${RESET}"
