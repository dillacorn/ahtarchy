#!/usr/bin/env bash
# github.com/dillacorn/awtarchy/tree/main/scripts
# install_flatpak_apps.sh

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
  'com.github.tchx84.Flatseal'
)

# Detect file system type of the root partition
root_fs_type=$(df -T / | awk 'NR==2 {print $2}')

# Determine whether to use the --user flag
if [[ "$root_fs_type" == "btrfs" ]]; then
  flatpak_user_flag=""
else
  flatpak_user_flag="--user"
fi

# Add Flatpak alias to .bashrc and .zshrc if not using Btrfs
if [[ "$root_fs_type" != "btrfs" ]]; then
  alias_line="alias flatpak='flatpak --user'"

  for shell_rc in ".bashrc" ".zshrc"; do
    rc_path="$target_home/$shell_rc"
    if [[ -f "$rc_path" ]]; then
      if ! grep -qFx "$alias_line" "$rc_path"; then
        echo -e "\n# Automatically apply --user flag for Flatpak on non-Btrfs systems\n$alias_line" >> "$rc_path"
        chown "$target_user:$target_user" "$rc_path"
        echo -e "${GREEN}Appended Flatpak alias to ${rc_path}${RESET}"
      else
        echo -e "${YELLOW}Flatpak alias already present in ${rc_path}. Skipping...${RESET}"
      fi
    fi
  done
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

# Apply Vesktop override only if Vesktop is installed
if runuser -u "$target_user" -- flatpak $flatpak_user_flag list --app | grep -q 'dev.vencord.Vesktop'; then
  echo -e "${CYAN}Applying Flatpak override for Vesktop to disable X11 socket...${RESET}"
  runuser -u "$target_user" -- flatpak $flatpak_user_flag override --nosocket=x11 dev.vencord.Vesktop
else
  echo -e "${YELLOW}Vesktop is not installed. Skipping X11 override.${RESET}"
fi

# Configure firewall rules for NDI (as root, since this requires system-level changes)
echo -e "${CYAN}Configuring firewall rules for NDI...${NC}"

# Add firewall rules for NDI (ports 5959–5969, 6960–6970, 7960–7970 for TCP and UDP, and 5353 for mDNS)
echo -e "${CYAN}Adding firewall rules...${NC}"
ufw allow 5353/udp                            # mDNS discovery
ufw allow 5959:5969/tcp                       # Core NDI (TCP)
ufw allow 5959:5969/udp                       # Core NDI (UDP)
ufw allow 6960:6970/tcp                       # WAN streaming (TCP)
ufw allow 6960:6970/udp                       # WAN streaming (UDP)
ufw allow 7960:7970/tcp                       # Metadata/audio/etc (TCP)
ufw allow 7960:7970/udp                       # Metadata/audio/etc (UDP)
ufw allow 5960/tcp                            # Optional explicit NDI Remote control port

# Check if Moonlight (Flatpak) is installed
if flatpak list --app | grep -q com.moonlight_stream.Moonlight; then
    echo -e "${CYAN}Moonlight Flatpak detected! Configuring firewall rules for Moonlight...${NC}"
    ufw allow 48010/tcp
    ufw allow 48000/udp
    ufw allow 48010/udp
    echo -e "${GREEN}Firewall rules for Moonlight configured successfully.${NC}"
else
    echo -e "${YELLOW}Moonlight is not installed via Flatpak. Skipping firewall configuration for Moonlight.${NC}"
fi

echo -e "${GREEN}Firewall rules for NDI configured successfully.${RESET}"

echo -e "${PURPLE}Flatpak setup and installation complete.${RESET}"
