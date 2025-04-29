#!/bin/bash

# Ensure the script is run with sudo/root privileges
if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}This script must be run with sudo!${NC}"
    exit 1
fi

# Detect if running in a virtual machine
if systemd-detect-virt -q; then
    echo -e "\033[1;33mRunning in a virtual machine. Skipping GPU-specific configuration.\033[0m"
else
    # Detect GPU type and apply appropriate settings for AMD, Intel, or Nvidia users
    GPU_VENDOR=$(lspci | grep -i 'vga\|3d\|2d' | grep -i 'Radeon\|NVIDIA\|Intel\|Advanced Micro Devices')

    echo -e "\033[1;34mDetecting GPU vendor...\033[0m"

    if [ -z "$GPU_VENDOR" ]; then
        echo -e "\033[1;31mNo AMD, NVIDIA, or Intel GPU detected. Skipping GPU-specific configuration.\033[0m"
        exit 0
    fi

    # Install required GPU dependencies
    echo -e "\033[1;34mInstalling GPU-specific dependencies...\033[0m"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm lib32-mesa lib32-vulkan-icd-loader lib32-libglvnd

    # AMD GPU Configuration
    if echo "$GPU_VENDOR" | grep -iq "Radeon"; then
        echo -e "\033[1;32mAMD GPU detected. Applying AMD-specific settings...\033[0m"

        # Ensure the linux-firmware package is installed for AMD GPUs
        retry_command sudo pacman -S --needed --noconfirm linux-firmware

        # Install AMD video decoding libraries (VA-API and VDPAU)
        retry_command sudo pacman -S --needed --noconfirm libva-mesa-driver mesa-vdpau lib32-mesa-vdpau

        # Check if VA-API tools are available, install if missing
        if ! command -v vainfo &> /dev/null; then
            echo -e "\033[1;34mInstalling libva-utils for VA-API support...\033[0m"
            retry_command sudo pacman -S --needed --noconfirm libva-utils
        fi

        # Validate VA-API support
        echo -e "\033[1;34mValidating hardware acceleration (VA-API)...\033[0m"
        vainfo || echo -e "\033[1;31mVA-API not working properly.\033[0m"

    # NVIDIA GPU Configuration
    elif echo "$GPU_VENDOR" | grep -iq "NVIDIA"; then
        echo -e "\033[1;33mNVIDIA GPU detected. Applying NVIDIA-specific settings...\033[0m"

        # Install NVIDIA proprietary drivers
        if ! pacman -Q | grep -q "nvidia"; then
            echo -e "\033[1;34mInstalling NVIDIA proprietary drivers...\033[0m"
            retry_command sudo pacman -S --noconfirm lib32-nvidia-utils nvidia nvidia-utils nvidia-settings

            # Install video decoding libraries for NVIDIA
            retry_command sudo pacman -S --needed --noconfirm libva-vdpau-driver libvdpau-va-gl
        else
            echo -e "\033[1;32mNVIDIA proprietary drivers already installed.\033[0m"
        fi

    # Intel GPU Configuration
    elif echo "$GPU_VENDOR" | grep -iq "Intel"; then
        echo -e "\033[1;33mIntel GPU detected. Applying Intel-specific settings...\033[0m"

        # Install Intel GPU drivers
        if ! pacman -Q | grep -q "xf86-video-intel"; then
            echo -e "\033[1;34mInstalling Intel GPU driver...\033[0m"
            retry_command sudo pacman -S --noconfirm xf86-video-intel
        else
            echo -e "\033[1;32mIntel driver already installed.\033[0m"
        fi

    else
        echo -e "\033[1;31mNo AMD, NVIDIA, or Intel GPU detected. Skipping GPU-specific configuration.\033[0m"
    fi
fi
