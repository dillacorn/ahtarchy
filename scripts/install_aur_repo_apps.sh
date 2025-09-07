#!/bin/bash
set -euo pipefail

# Initialize variables for cleanup targets
TMP_SUDOERS=""
YAY_TMP_DIR=""

cleanup() {
    echo -e "${CYAN}Cleaning up temporary files...${NC}"
    # Remove sudoers file if it exists
    sudo rm -f "/etc/sudoers.d/temp_sudo_nopasswd" 2>/dev/null || true
    # Remove yay temp directory if it exists
    [[ -n "$YAY_TMP_DIR" ]] && sudo rm -rf "$YAY_TMP_DIR" 2>/dev/null || true
    # Remove sudoers temp file if it exists
    [[ -n "$TMP_SUDOERS" ]] && sudo rm -f "$TMP_SUDOERS" 2>/dev/null || true
}
trap cleanup EXIT

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;96m'
NC='\033[0m' # No Color

# Ensure the script is run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo!"
    exit 1
fi

if [ ! -d "/home/$SUDO_USER" ]; then
    echo -e "${RED}Error: Home directory for $SUDO_USER not found!${NC}"
    exit 1
fi

# Create and validate temporary sudoers file
echo -e "${CYAN}Creating temporary sudo permissions...${NC}"
TMP_SUDOERS=$(sudo mktemp /tmp/temp_sudoers.XXXXXX) || exit 1
echo "${SUDO_USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee "$TMP_SUDOERS" > /dev/null

# Validate syntax before installing
if ! sudo visudo -c -f "$TMP_SUDOERS"; then
    echo -e "${RED}Error: Generated sudoers file is invalid!${NC}" >&2
    sudo rm -f "$TMP_SUDOERS"
    exit 1
fi

# Install with proper permissions
sudo install -m 0440 "$TMP_SUDOERS" /etc/sudoers.d/temp_sudo_nopasswd
sudo rm -f "$TMP_SUDOERS"
echo -e "${GREEN}Temporary sudo permissions created successfully.${NC}"

# Check if yay is installed, if not, install it as the normal user
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}'yay' not found. Installing...${NC}"
    YAY_TMP_DIR=$(sudo -u "$SUDO_USER" mktemp -d -t yay-XXXXXX) || exit 1
    sudo -u "$SUDO_USER" bash <<EOF
        git clone https://aur.archlinux.org/yay.git "$YAY_TMP_DIR"
        cd "$YAY_TMP_DIR"
        makepkg -sirc --noconfirm
        rm -rf "$YAY_TMP_DIR"
EOF
fi

# Check if the system is running in a virtual machine
IS_VM=false
if systemd-detect-virt --quiet; then
    IS_VM=true
    echo -e "${CYAN}Running in a virtual machine. Skipping TLPUI installation.${NC}"
fi

# Prompt for package installation
read -r -n1 -t 30 -s -p "$(echo -e "\n${CYAN}Install Dillacorn's AUR apps? [y/n]${NC}") " choice || {
    echo -e "\n${YELLOW}No input. Skipping installations.${NC}"
    choice="n"
}

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo -e "\n${GREEN}Proceeding with installation of Dillacorn's chosen Arch AUR Linux applications...${NC}"
    
    # Temporarily become the non-root user to run yay for package installation
    sudo -u "$SUDO_USER" bash <<EOF
        # Update system and AUR packages
        yay -Syu --noconfirm

        # Function to install a package and clean up its build directory
        install_package() {
            local package="\$1"
            if yay -Qi "\$package" > /dev/null; then
                echo -e "${YELLOW}\$package is already installed. Skipping...${NC}"
            else
                echo -e "${CYAN}Installing \$package...${NC}"
                yay -S --needed --noconfirm "\$package"
                echo -e "${GREEN}\$package installed successfully!${NC}"
            fi
            # Clean up the build directory for this package
            rm -rf "/home/$SUDO_USER/.cache/yay/\$package"
        }

        # List of AUR packages to install with cleanup
        packages=(
            qimgv-git
            otpclient
            wlogout
            waypaper
            sunshine-bin
            gpu-screen-recorder
        )

        # Install each package and clean up afterward
        for package in "\${packages[@]}"; do
            install_package "\$package"
        done

        # Clean the package cache to free up space
        yay -Sc --noconfirm
EOF

    echo -e "\n${GREEN}Installation complete and disk space optimized!${NC}"

else
    echo -e "\n${YELLOW}Skipping installation of Dillacorn's chosen Arch AUR Linux applications.${NC}"
    exit 0
fi

# Prompt user to specify if the system is a laptop or a desktop
echo -e "\n${CYAN}Is this system a laptop or a desktop? [l/d]${NC}"
read -r -n1 -s system_type
echo

if [[ "$system_type" == "l" || "$system_type" == "L" ]]; then
    IS_LAPTOP=true
    echo -e "${CYAN}User specified this system is a laptop.${NC}"
else
    IS_LAPTOP=false
    echo -e "${CYAN}User specified this system is a desktop.${NC}"
fi

# Conditionally install tlpui if on a laptop and not in a VM
if [ "$IS_LAPTOP" = true ] && [ "$IS_VM" = false ]; then
    echo -e "${CYAN}Installing tlpui for laptop power management...${NC}"
    sudo -u "$SUDO_USER" yay -S --needed --noconfirm tlpui
    echo -e "${GREEN}TLPUI installed successfully.${NC}"
fi

# Check if Moonlight is installed via yay (from AUR)
if yay -Qs moonlight-qt-bin > /dev/null; then
    echo -e "${CYAN}Moonlight detected! Configuring firewall rules for Moonlight...${NC}"
    if command -v ufw &> /dev/null; then
        sudo ufw allow 48010/tcp
        sudo ufw allow 48000/udp
        sudo ufw allow 48010/udp
        echo -e "${GREEN}Firewall rules for Moonlight configured successfully.${NC}"
    else
        echo -e "${YELLOW}UFW is not installed. Skipping firewall configuration.${NC}"
    fi
fi

# Print success message after installation
echo -e "\n${GREEN}Successfully installed all of Dillacorn's Arch Linux AUR chosen applications!${NC}"
