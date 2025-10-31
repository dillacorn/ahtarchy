# `awtarchy-shell`

####  See [Release Page](https://github.com/dillacorn/awtarchy/releases/tag/awtarchy-install/latest) for install directions!

---

pronounced: **aw-tar-chee**

**awtarchy** is not a Linux distribution. It is an overlay environment for base Arch Linux.

## Install model
1. Install Arch with `archinstall` and select the Minimal profile.
2. Apply the awtarchy overlay on top of that base system.

## Why this approach
- Flexible: works over any clean Arch install.
- Lightweight: no separate ISO or custom repositories required.
- Low maintenance: relies on Arch’s installer and official repositories.

## Workflow expectations
awtarchy targets users who prefer TTY login and direct shell interaction. It assumes comfort with the command line and manual configuration.

> Note on originality  
> awtarchy is not an Omarchy clone. All code, scripts, and configurations are original and include features not present in Omarchy or similar projects.

---

**Click the image below to see more previews!**

- Note to viewer: previews are out of date.. waybar and fastfetch have changed/improved.

[![overview](https://github.com/dillacorn/awtarchy/raw/main/previews/overview.png)](https://github.com/dillacorn/awtarchy/tree/main/previews.md)

## 🖥️ System Overview

| Component          | Details |
|--------------------|---------|
| **Distro**         | [Arch Linux](https://archlinux.org/) |
| **Installation**   | [archinstall](https://github.com/archlinux/archinstall) |
| **File System**    | [ext4 (separate root/home partitions)](https://man.archlinux.org/man/ext4.5.en) and/or [BTRFS](https://wiki.archlinux.org/title/Btrfs) |
| **Repositories**   | core, extra, multilib, [AUR](https://aur.archlinux.org/), [Flathub](https://flathub.org/) |
| **Terminal**       | [Alacritty](https://github.com/alacritty/alacritty) |
| **Bootloader**     | [systemd-boot](https://man.archlinux.org/man/systemd-boot.7) |
| **Window Manager** | [Hyprland](https://github.com/hyprwm/Hyprland) ([config](https://github.com/dillacorn/awtarchy/tree/main/config/hypr)) |
| **Kernel**         | [linux-tkg](https://github.com/Frogging-Family/linux-tkg) |

## 🎨 Wallpaper Collections
- [dharmx/walls](https://github.com/dharmx/walls)
- [Gruvbox Wallpapers](https://github.com/AngelJumbo/gruvbox-wallpapers)
- [Aesthetic Wallpapers](https://github.com/D3Ext/aesthetic-wallpapers)

## ⚡ Application Install Scripts
- [Arch Repo Apps](scripts/install_arch_repo_apps.sh)
- [AUR Apps](scripts/install_aur_repo_apps.sh)  
- [Flatpak Apps](scripts/install_flatpak_apps.sh)

> ℹ️ Modify scripts to suit your preferences

## 🌐 Browser Notes
- [Firefox Privacy Forks](browser_notes/firefox_privacy_focused_forks.md)
- [Brave](browser_notes/brave.md)
- [Ungoogled-Chromium](browser_notes/ungoogled-chromium.md)
- [Cromite](browser_notes/cromite.md)

## 📦 Optional Packages
- [Optional Packages link](extra_notes/optional_packages.md)











