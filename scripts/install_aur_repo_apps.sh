#!/bin/bash

# Ensure the script is run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo!"
    exit 1
fi

# Temporarily enable passwordless sudo for the current user
sudo bash -c "echo '$SUDO_USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/temp_sudo_nopasswd"

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;96m'
NC='\033[0m' # No Color

# Check if yay is installed, if not, install it as the normal user
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}'yay' is not installed. Installing yay...${NC}"
    sudo pacman -S --needed --noconfirm git base-devel

    # Temporarily become the non-root user to build yay
    sudo -u "$SUDO_USER" bash <<EOF
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -sirc --noconfirm
        cd ..
        rm -rf /tmp/yay  # Clean up the yay build directory
EOF
fi

# Check if the system is running in a virtual machine
IS_VM=false
if systemd-detect-virt --quiet; then
    IS_VM=true
    echo -e "${CYAN}Running in a virtual machine. Skipping TLPUI installation.${NC}"
fi

# Prompt for package installation
echo -e "\n${CYAN}Do you want to install Dillacorn's chosen Arch AUR Linux applications? [y/n]${NC}"
read -r -n1 -s choice
echo

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
            rm -rf /home/$SUDO_USER/.cache/yay/\$package 
        }

        # List of AUR packages to install with cleanup
        packages=(
            qimgv
            otpclient
            wlogout
            waypaper
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
    ufw allow 48010/tcp
    ufw allow 48000/udp
    ufw allow 48010/udp
    echo -e "${GREEN}Firewall rules for Moonlight configured successfully.${NC}"
else
    echo -e "${YELLOW}Moonlight is not installed. Skipping firewall configuration for Moonlight.${NC}"
fi

# Remove the temporary passwordless sudo entry
sudo rm -f /etc/sudoers.d/temp_sudo_nopasswd

# Print success message after installation
echo -e "\n${GREEN}Successfully installed all of Dillacorn's Arch Linux AUR chosen applications!${NC}"
