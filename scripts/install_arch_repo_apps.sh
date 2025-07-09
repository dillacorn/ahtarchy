#!/bin/bash

# =============================================
# COLOR DEFINITIONS
# =============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;96m'
NC='\033[0m' # No Color

# =============================================
# SCRIPT INITIALIZATION
# =============================================
set -eu -o pipefail # Fail on error and report it, debug all lines

# Ensure the script is run with sudo/root privileges
if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}This script must be run with sudo!${NC}"
    exit 1
fi

# =============================================
# FUNCTION DEFINITIONS
# =============================================
install_package() {
    local package="$1"
    if ! pacman -Qi "$package" &>/dev/null; then
        echo -e "${CYAN}Installing $package...${NC}"
        if ! pacman -S --needed --noconfirm "$package"; then
            echo -e "${RED}Failed to install $package!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}$package already installed. Skipping...${NC}"
    fi
}

# =============================================
# SYSTEM CHECKS
# =============================================
# Check if running in a virtual machine
if systemd-detect-virt --quiet; then
    IS_VM=true
    echo -e "${CYAN}Running in virtual machine. Skipping hardware checks.${NC}"
else
    IS_VM=false
    echo -e "${CYAN}Running on physical hardware.${NC}"
fi

# Verify multilib repository is enabled
if ! grep -q "^\[multilib\]" /etc/pacman.conf || ! grep -q "^Include = /etc/pacman.d/mirrorlist" /etc/pacman.conf; then
    echo -e "${RED}ERROR: Multilib repository not enabled!${NC}"
    echo -e "${YELLOW}Required for many packages. Please uncomment in /etc/pacman.conf:${NC}"
    echo -e "${CYAN}[multilib]\nInclude = /etc/pacman.d/mirrorlist${NC}"
    echo -e "${YELLOW}Then run: sudo pacman -Syu${NC}"
    exit 1
fi

# =============================================
# PACKAGE MANAGEMENT
# =============================================
# Handle pipewire-jack installation
if pacman -Qi jack2 &>/dev/null; then
    echo -e "${YELLOW}Removing conflicting jack2 package...${NC}"
    if ! pacman -Rdd --noconfirm jack2; then
        echo -e "${RED}Failed to remove jack2! Manual removal required.${NC}"
        exit 1
    fi
fi
install_package "pipewire-jack"

# =============================================
# MAIN INSTALLATION PROMPT
# =============================================
echo -e "\n${CYAN}Install Dillacorn's Arch applications? [y/n]${NC}"
read -r -n1 -s choice
echo

if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

echo -e "\n${GREEN}Starting installation...${NC}"

# =============================================
# SYSTEM UPDATE
# =============================================
echo -e "${CYAN}Updating system...${NC}"
if ! pacman -Syu --noconfirm; then
    echo -e "${RED}System update failed! Resolve conflicts and try again.${NC}"
    exit 1
fi

# =============================================
# PACKAGE INSTALLATION
# =============================================
declare -a pkg_groups=(
    "Window Management:hyprland hyprpaper hyprlock hypridle hyprpicker waybar wofi swww grim satty slurp wl-clipboard zbar wf-recorder zenity qt5ct qt5-wayland kvantum-qt5 qt6ct qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk mako nwg-look"
    "Fonts:ttf-font-awesome otf-font-awesome ttf-hack ttf-dejavu ttf-liberation ttf-noto-nerd noto-fonts-emoji"
    "Themes:papirus-icon-theme materia-gtk-theme xcursor-comix kvantum-theme-materia"
    "Terminal Apps:nano micro alacritty fastfetch btop htop curl wget git dos2unix brightnessctl ipcalc cmatrix sl asciiquarium figlet cava man-db man-pages unzip xarchiver octave ncdu"
    "Utilities:steam polkit-gnome gnome-keyring networkmanager network-manager-applet tailscale bluez bluez-utils blueman pavucontrol pcmanfm-qt gvfs gvfs-smb gvfs-mtp gvfs-afc qbittorrent speedcrunch timeshift imagemagick pipewire pipewire-pulse pipewire-alsa ufw jq earlyoom"
    "Multimedia:ffmpeg avahi mpv cheese exiv2 audacity qpwgraph krita shotcut filezilla gthumb handbrake zathura zathura-pdf-poppler"
    "Development:base-devel archlinux-keyring clang ninja go rust virt-manager qemu qemu-hw-usb-host virt-viewer vde2 libguestfs dmidecode gamemode nftables swtpm"
    "Network Tools:wireguard-tools wireplumber openssh iptables systemd-resolvconf bridge-utils qemu-guest-agent dnsmasq dhcpcd inetutils openbsd-netcat"
)

for group in "${pkg_groups[@]}"; do
    IFS=':' read -r group_name packages <<< "$group"
    echo -e "\n${CYAN}Installing $group_name...${NC}"
    for pkg in $packages; do
        if ! install_package "$pkg"; then
            echo -e "${YELLOW}Continuing despite package failure...${NC}"
        fi
    done
done

# =============================================
# SYSTEM CONFIGURATION
# =============================================
echo -e "\n${CYAN}Configuring system services...${NC}"

# Avahi
systemctl enable --now avahi-daemon

# DNS Services
if systemctl is-active --quiet unbound; then
    systemctl disable --now unbound
fi
systemctl enable --now systemd-resolved
systemctl stop dnsmasq.service || true
systemctl disable dnsmasq.service || true

# NetworkManager
systemctl enable --now NetworkManager

# =============================================
# HARDWARE-SPECIFIC CONFIGURATION
# =============================================
if [ "$IS_VM" = false ]; then
    # Device type detection
    echo -e "\n${CYAN}Is this a laptop or desktop? [l/d]${NC}"
    read -r -n1 -s device_type
    echo
    
    case "$device_type" in
        [lL]) IS_LAPTOP=true ;;
        [dD]) IS_LAPTOP=false ;;
        *)
            echo -e "${RED}Invalid input. Exiting.${NC}"
            exit 1
            ;;
    esac

    # Intel-specific setup
    if grep -qi "Intel" /proc/cpuinfo; then
        if [ "$IS_LAPTOP" = true ]; then
            echo -e "${CYAN}Setting up Intel laptop power management...${NC}"
            install_package "thermald" && systemctl enable --now thermald
        fi
    fi

    # Laptop power management
    if [ "$IS_LAPTOP" = true ]; then
        echo -e "${CYAN}Configuring laptop power savings...${NC}"
        install_package "tlp" && systemctl enable --now tlp
    fi
fi

# =============================================
# VIRTUALIZATION SETUP
# =============================================
if [ "$IS_VM" = false ]; then
    echo -e "\n${CYAN}Configuring virtualization...${NC}"
    systemctl enable --now libvirtd
    
    echo -e "${CYAN}Waiting for libvirtd...${NC}"
    while ! systemctl is-active --quiet libvirtd; do
        sleep 1
    done

    virsh net-destroy default || true
    virsh net-start default
    virsh net-autostart default

    ufw allow in on virbr0
    ufw allow out on virbr0
    ufw reload
fi

# =============================================
# MEMORY SAFETY: EARLYOOM SETUP
# =============================================
if pacman -Qi earlyoom &>/dev/null; then
    echo -e "${CYAN}Enabling earlyoom service...${NC}"
    systemctl enable --now earlyoom
else
    echo -e "${YELLOW}earlyoom not installed — skipping service enable.${NC}"
fi

# =============================================
# BLUETOOTH
# =============================================
# Bluetooth
if pacman -Qi bluez &>/dev/null; then
    systemctl enable --now bluetooth.service
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Note: Some changes may require reboot.${NC}"
