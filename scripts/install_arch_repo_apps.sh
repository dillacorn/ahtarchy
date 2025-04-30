#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;96m'
NC='\033[0m' # No Color

# Ensure the script is run with sudo/root privileges
if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}This script must be run with sudo!${NC}"
    exit 1
fi

set -eu -o pipefail # Fail on error and report it, debug all lines

# Check if the multilib repository is enabled in /etc/pacman.conf
if ! grep -q "^\[multilib\]" /etc/pacman.conf || ! grep -q "^Include = /etc/pacman.d/mirrorlist" /etc/pacman.conf; then
    echo -e "${YELLOW}IMPORTANT: Ensure the multilib repository is enabled in /etc/pacman.conf before running this script.${NC}"
    echo -e "${YELLOW}To enable it, uncomment the following lines in your /etc/pacman.conf file:${NC}"
    echo -e "${CYAN}  [multilib]\n  Include = /etc/pacman.d/mirrorlist${NC}"
    echo -e "${YELLOW}Then, run 'sudo pacman -Syu' to update the package list.${NC}"
fi

# Function to install a package if not already installed
install_package() {
    local package="$1"
    if ! pacman -Qi "$package" &>/dev/null; then
        echo -e "${CYAN}Installing $package and its dependencies...${NC}"
        pacman -S --needed --noconfirm "$package"
    else
        echo -e "${YELLOW}$package is already installed. Skipping...${NC}"
    fi
}

# Check if the script is running in a virtual machine
if systemd-detect-virt --quiet; then
    IS_VM=true
    echo -e "${CYAN}Running in a virtual machine. Skipping hardware checks and thermald installation.${NC}"
else
    IS_VM=false
    echo -e "${CYAN}Running on a physical machine.${NC}"
fi

# Forcefully remove jack2 and install pipewire-jack
if pacman -Qi jack2 &>/dev/null; then
    echo -e "${YELLOW}jack2 is installed, which conflicts with pipewire-jack.${NC}"
    echo -e "${CYAN}Forcefully removing jack2 and related dependencies...${NC}"
    pacman -Rdd --noconfirm jack2
fi
install_package "pipewire-jack"

# Prompt for package installation
echo -e "\n${CYAN}Do you want to install Dillacorn's chosen Arch Repo Linux applications? [y/n]${NC}"
read -n1 -s choice
echo

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo -e "\n${GREEN}Proceeding with installation of Dillacorn's chosen Arch Repo Linux applications...${NC}"

    # Update the package list
    echo -e "${CYAN}Updating package list...${NC}"
    pacman -Syu --noconfirm

    # Install Window Management Tools
    echo -e "${CYAN}Installing window management tools...${NC}"
    for pkg in hyprland hyprpaper hyprlock hypridle waybar rofi-wayland swww grim slurp wl-clipboard qt5-wayland qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk mako nwg-look; do
        install_package "$pkg"
    done

    # Install Fonts
    echo -e "${CYAN}Installing fonts...${NC}"
    for pkg in ttf-font-awesome ttf-hack ttf-dejavu ttf-liberation noto-fonts; do
        install_package "$pkg"
    done

    # Install Themes
    echo -e "${CYAN}Installing themes...${NC}"
    for pkg in papirus-icon-theme materia-gtk-theme xcursor-comix; do
        install_package "$pkg"
    done

    # Install Terminal Applications
    echo -e "${CYAN}Installing terminal and CLI apps...${NC}"
    for pkg in micro alacritty fastfetch btop htop curl wget git dos2unix brightnessctl ipcalc cmatrix sl asciiquarium figlet cava; do
        install_package "$pkg"
    done

    # Install Utilities
    echo -e "${CYAN}Installing general utilities...${NC}"
    for pkg in steam polkit-kde-agent lxappearance networkmanager network-manager-applet tailscale bluez bluez-utils blueman pavucontrol pcmanfm gvfs gvfs-smb gvfs-mtp gvfs-afc qbittorrent filelight timeshift flameshot imagemagick pipewire pipewire-pulse pipewire-alsa ufw; do
        install_package "$pkg"
    done

    # Install Multimedia Tools
    echo -e "${CYAN}Installing multimedia tools...${NC}"
    for pkg in ffmpeg avahi mpv cheese exiv2 audacity krita shotcut filezilla gthumb handbrake; do
        install_package "$pkg"
    done

    # Start and enable Avahi daemon
    echo -e "${CYAN}Starting and enabling avahi-daemon...${NC}"
    systemctl enable --now avahi-daemon

    # Install Development Tools
    echo -e "${CYAN}Installing development tools...${NC}"
    for pkg in base-devel archlinux-keyring clang ninja go rust okular bleachbit virt-manager qemu virt-viewer vde2 libguestfs dmidecode gamemode nftables swtpm; do
        install_package "$pkg"
    done

# Only proceed with hardware checks if not in a virtual machine
if [ "$IS_VM" = false ]; then
    # Prompt user to specify if this is a laptop or desktop
    echo -e "${CYAN}Is this system a laptop or desktop? [l/d]${NC}"
    read -n1 -s user_choice
    echo

    if [[ "$user_choice" == "l" || "$user_choice" == "L" ]]; then
        IS_LAPTOP=true
        echo -e "${CYAN}User specified: Laptop.${NC}"
    elif [[ "$user_choice" == "d" || "$user_choice" == "D" ]]; then
        IS_LAPTOP=false
        echo -e "${CYAN}User specified: Desktop.${NC}"
    else
        echo -e "${RED}Invalid input. Please enter 'l' for laptop or 'd' for desktop.${NC}"
        exit 1
    fi

    # Check if CPU is Intel to decide whether to install thermald
    if grep -q "Intel" /proc/cpuinfo; then
        IS_INTEL=true
        echo -e "${CYAN}Intel processor detected.${NC}"
    else
        IS_INTEL=false
        echo -e "${CYAN}Non-Intel processor detected. Skipping thermald installation.${NC}"
    fi

    # Install thermald only if the processor is Intel and the system is a laptop
    if [[ "$IS_INTEL" == true && "$IS_LAPTOP" == true ]]; then
        echo -e "${CYAN}Installing and enabling thermald for Intel laptop...${NC}"
        install_package "thermald"
        systemctl enable --now thermald
    else
        echo -e "${YELLOW}Skipping thermald installation.${NC}"
    fi
        
    # Install TLP for laptops only (both Intel and AMD)
    if [ "$IS_LAPTOP" = true ]; then
        echo -e "${CYAN}Installing and enabling TLP for power management on laptop...${NC}"
        install_package "tlp"
        systemctl enable --now tlp
        echo -e "${GREEN}TLP installed and enabled successfully.${NC}"
    else
        echo -e "${YELLOW}Skipping TLP installation as this is a desktop system.${NC}"
    fi
fi

    # Disable and stop unbound if it's running
    if systemctl is-active --quiet unbound; then
        echo -e "${CYAN}Disabling and stopping unbound service...${NC}"
        systemctl disable --now unbound
    else
        echo -e "${YELLOW}Unbound service is not active. Skipping disable and stop for unbound.${NC}"
    fi
    
    # Enable systemd-resolved to handle DNS
    echo -e "${CYAN}Enabling and starting systemd-resolved...${NC}"
    systemctl enable --now systemd-resolved
    
    # Ensure standalone dnsmasq service is not running
    echo -e "${CYAN}Ensuring standalone dnsmasq service is stopped...${NC}"
    systemctl stop dnsmasq || true
    systemctl disable dnsmasq || true
    pkill dnsmasq || true

    for pkg in wireguard-tools wireplumber openssh iptables systemd-resolvconf bridge-utils qemu-guest-agent dnsmasq dhcpcd inetutils openbsd-netcat; do
        install_package "$pkg"
    done

    echo -e "${CYAN}Enabling and starting NetworkManager...${NC}"
    systemctl enable --now NetworkManager

    echo -e "${CYAN}Killing any existing instances of libvirtd and dnsmasq...${NC}"
    pkill libvirtd || true
    pkill dnsmasq || true
    
    echo -e "${CYAN}Enabling and starting libvirtd...${NC}"
    systemctl enable --now libvirtd

    # Wait until libvirtd is fully active
    echo -e "${CYAN}Waiting for libvirtd to become active...${NC}"
    until systemctl is-active --quiet libvirtd; do
        sleep 1
    done

    # Proceed with the network setup
    virsh net-destroy default || true
    virsh net-start default
    virsh net-autostart default

    # Apply UFW rules
    echo -e "${CYAN}Configuring UFW rules for libvirt networking...${NC}"
    ufw allow in on virbr0
    ufw allow out on virbr0
    ufw allow out to any port 53
    ufw allow out to any port 80
    ufw allow out to any port 443
    ufw default allow routed
    ufw reload

    # Enable and start Bluetooth service
    if pacman -Qi bluez &>/dev/null && pacman -Qi bluez-utils &>/dev/null; then
        install_package "bluez"
        install_package "bluez-utils"
        systemctl enable --now bluetooth.service
        echo -e "${GREEN}Bluetooth service started successfully.${NC}"
    else
        echo -e "${RED}Bluetooth service could not be enabled. bluez or bluez-utils is missing.${NC}"
    fi

    # Print success message after installation
    echo -e "\n${GREEN}Successfully installed all of Dillacorn's Arch Linux chosen applications!${NC}"
else
    echo -e "\n${YELLOW}Skipping installation of Dillacorn's chosen Arch Repo Linux applications.${NC}"
fi
