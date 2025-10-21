#!/bin/bash
# github.com/dillacorn/awtarchy/tree/main/scripts
# install_GPU_dependencies.sh

# Define colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Retry a command up to 3 times if it fails
retry_command() {
    local retries=3
    local delay=2
    local count=0
    until "$@"; do
        ((count++))
        if [[ $count -ge $retries ]]; then
            echo -e "${RED}Command failed after $retries attempts: $*${NC}"
            return 1
        fi
        echo -e "${YELLOW}Retrying in $delay seconds...${NC}"
        sleep $delay
    done
}

# Safely remove NVIDIA drivers without touching firmware files
clean_nvidia_drivers() {
    echo -e "${BLUE}Checking for NVIDIA drivers...${NC}"
    local nvidia_pkgs
    nvidia_pkgs=$(pacman -Qq | grep -E '^nvidia|^lib32-nvidia|nvidia-settings')

    if [[ -n "$nvidia_pkgs" ]]; then
        echo -e "${YELLOW}Removing NVIDIA packages...${NC}"
        echo -e "${BLUE}Found packages:\n$nvidia_pkgs${NC}"

        IFS=$'\n' read -rd '' -a nvidia_array <<< "$nvidia_pkgs"
        retry_command pacman -Rns --noconfirm "${nvidia_array[@]}"

        # Reinstall linux-firmware to ensure clean state (without forcing overwrites)
        echo -e "${BLUE}Ensuring firmware is in clean state...${NC}"
        retry_command pacman -S --noconfirm --needed linux-firmware
    else
        echo -e "${GREEN}No NVIDIA packages found.${NC}"
    fi
}

# Ensure the script is run with sudo/root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run with sudo!${NC}"
    exit 1
fi

# Detect if running in a virtual machine
if systemd-detect-virt -q; then
    echo -e "${YELLOW}Running in a virtual machine. Skipping GPU-specific configuration.${NC}"
    exit 0
fi

# Detect GPU type and apply appropriate settings for AMD, Intel, or NVIDIA users
GPU_VENDOR=$(lspci | grep -i 'vga\|3d\|2d' | grep -i 'Radeon\|NVIDIA\|Intel\|Advanced Micro Devices')

echo -e "${BLUE}Detecting GPU vendor...${NC}"

if [ -z "$GPU_VENDOR" ]; then
    echo -e "${RED}No AMD, NVIDIA, or Intel GPU detected. Skipping GPU-specific configuration.${NC}"
    exit 0
fi

# Update system and install core GPU dependencies
echo -e "${BLUE}Updating system and installing GPU-specific dependencies...${NC}"
retry_command pacman -Syu --noconfirm
retry_command pacman -S --noconfirm lib32-mesa lib32-vulkan-icd-loader lib32-libglvnd

# AMD GPU Configuration
if echo "$GPU_VENDOR" | grep -iq "Radeon\|Advanced Micro Devices"; then
    echo -e "${GREEN}AMD GPU detected. Applying AMD-specific settings...${NC}"

    # Clean up any existing NVIDIA drivers to avoid conflicts
    clean_nvidia_drivers

    # Install linux-firmware package which includes AMD firmware blobs
    echo -e "${BLUE}Ensuring linux-firmware package is installed...${NC}"
    retry_command pacman -S --needed --noconfirm linux-firmware

    # Install Vulkan RADV driver, 32-bit Vulkan support, and tools
    retry_command pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon vulkan-tools

    # Install AMD video decoding libraries (VA-API and VDPAU)
    retry_command pacman -S --needed --noconfirm libva-mesa-driver mesa-vdpau lib32-mesa-vdpau

    # Install VA-API tools if not present
    if ! command -v vainfo &> /dev/null; then
        echo -e "${BLUE}Installing libva-utils for VA-API support...${NC}"
        retry_command pacman -S --needed --noconfirm libva-utils
    fi

    # Validate VA-API support
    echo -e "${BLUE}Validating hardware acceleration (VA-API)...${NC}"
    if ! vainfo; then
        echo -e "${RED}VA-API not working properly.${NC}"
        echo -e "${YELLOW}You may need to set environment variables:${NC}"
        echo "export LIBVA_DRIVER_NAME=radeonsi"
        echo "export VDPAU_DRIVER=radeonsi"
    fi

# NVIDIA GPU Configuration
elif echo "$GPU_VENDOR" | grep -iq "NVIDIA"; then
    echo -e "${YELLOW}NVIDIA GPU detected. Applying NVIDIA-specific settings...${NC}"

    # Install NVIDIA proprietary drivers if not already installed
    if ! pacman -Qq nvidia &> /dev/null; then
        echo -e "${BLUE}Installing NVIDIA proprietary drivers...${NC}"
        retry_command pacman -S --noconfirm lib32-nvidia-utils nvidia nvidia-utils nvidia-settings

        # Install video decoding libraries for NVIDIA
        retry_command pacman -S --needed --noconfirm libvdpau libvdpau-va-gl
    else
        echo -e "${GREEN}NVIDIA proprietary drivers already installed.${NC}"
    fi

    echo -e "${YELLOW}You may need to set environment variables:${NC}"
    echo "export LIBVA_DRIVER_NAME=vdpau"
    echo "export VDPAU_DRIVER=nvidia"

# Intel GPU Configuration
elif echo "$GPU_VENDOR" | grep -iq "Intel"; then
    echo -e "${YELLOW}Intel GPU detected. Applying Intel-specific settings...${NC}"

    # Install Intel GPU drivers if not installed
    if ! pacman -Qq xf86-video-intel &> /dev/null; then
        echo -e "${BLUE}Installing Intel GPU driver...${NC}"
        retry_command pacman -S --noconfirm xf86-video-intel libva-intel-driver libvdpau-va-gl
    else
        echo -e "${GREEN}Intel driver already installed.${NC}"
    fi

    echo -e "${YELLOW}You may need to set environment variables:${NC}"
    echo "export LIBVA_DRIVER_NAME=i965"
    echo "export VDPAU_DRIVER=va_gl"
fi
