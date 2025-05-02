# `arch dilla.hypr.files`

- **Preview Images**: **TO_BE_ADDED**
- **Distro**: [Arch Linux](https://archlinux.org/)
- **Installation Method**: [archinstall](https://github.com/archlinux/archinstall)
- **File System**: ext4 (seperate root and home partition)
- **Repositories**: [core](https://archlinux.org/packages/?sort=&arch=any&repo=Core&q=&maintainer=&flagged=), [extra](https://archlinux.org/packages/?sort=&arch=any&repo=Extra&q=&maintainer=&flagged=), [multilib](https://archlinux.org/packages/?sort=&repo=Multilib&q=&maintainer=&flagged=) & [AUR](https://aur.archlinux.org/packages)
- **Flatpak**: [flathub](https://flathub.org/)
- **Bootloader**: [systemd-boot](https://github.com/ivandavidov/systemd-boot) ~ [configuration_tutorial_modification_guide](https://github.com/dillacorn/arch-hypr-dots/blob/main/extra_notes/install_linux-tkg.md)
- **Wayland**: [hypr-wm](https://github.com/hyprwm/Hyprland) ~ [config directory](https://github.com/dillacorn/arch-hypr-dots/tree/main/config/hypr)
- **Kernel**: [linux-tkg](https://github.com/Frogging-Family/linux-tkg) ~ BORE CPU Schedular + Full Tickless! [tutorial_install_guide](https://github.com/dillacorn/arch-hypr-dots/blob/main/extra_notes/install_linux-tkg.md)
  - [Install linux-tkg on Arch](https://github.com/Frogging-Family/linux-tkg?tab=readme-ov-file#arch--derivatives)

---

## Keybinds: **DWM** Inspired
My keybinds (see [hypr config](https://github.com/dillacorn/arch-hypr-dots/blob/main/config/hypr/hyprland.conf) are heavily inspired by [**suckless DWM**](https://dwm.suckless.org/). Before switching to i3, I used [**DWM Flexipatch**](https://github.com/bakkeby/dwm-flexipatch) by [bakkeby](https://github.com/bakkeby) — DWM was my first window manager and now hyprland is my third.

---

## Wallpapers
- [Gruvbox Wallpapers](https://github.com/AngelJumbo/gruvbox-wallpapers) by [AngelJumbo](https://github.com/AngelJumbo)
- [Aesthetic Wallpapers](https://github.com/D3Ext/aesthetic-wallpapers) by [D3Ext](https://github.com/D3Ext)
- [Wallpapers](https://github.com/michaelScopic/Wallpapers) by [michaelScopic](https://github.com/michaelScopic)

---

## Hypr Keybind Custom Scripts/Commands

Here are some of my custom keybinds from the hyprland configuration:
  
- `mod+shift+g` = **Capture a GIF**  
  - Starts a GIF recording with the `Kooha`
  
- `mod+shift+s` = **grim+slurp screenshot**  
  - Takes a screenshot using grim+slurp and copies to clipboard.
  - `date_time.png` saved in `~/Pictures` directory.

- `mod+ctrl+shift+s` = **Flameshot screenshot**  
  - Takes a screenshot using Flameshot with more customization options.
  - `date_time.png` normally saved in `~/Pictures` directory.

---

## Hypr Navigation

Here are more example keybinds from my hypr config:

- `mod+shift+enter` = **Open Terminal**
  - Launches the terminal (default: Alacritty).

- `mod+p` = **Rofi Application Launcher**
  - Opens the Rofi app launcher for quick access to applications.

- `mod+shift+c` = **Close Window**
  - Closes the focused window.

- `mod+f` = **Toggle Floating**
  - Toggles between tiling and floating window layouts.

- `mod+shift+f` = **Toggle Fullscreen**
  - Toggles app focus ~ fullscreen.

- `mod+arrow_keys` = **Change Focus**
  - Switch between open windows.

- `mod+shift+arrow_keys` = **Move Windows**
  - Move window location within workspace.

- `mod+mouse_1` = **Move Floating Window**
  - Move Floating Window with your mouse.

- `mod+mouse_2` = **Resize Floating Window**
  - Resize Floating Window with your mouse.

- `mod+1` to `mod+9` = **Workspace Switching**  
  - Switches to workspaces 1 through 9.

- `mod+shift+1` to `mod+shift+9` = **Move Focused Window to Workspace**  
  - Moves the currently focused window to the specified workspace.
 
- `mod+ctrl+shift+arrows` = **Move Focused Workspace to Adjacent Monitor**  
  - Moves the currently focused workspace to an adjacent monitor.

---

### Installing Hyprland-WM and Related Applications with Scripts

Install Arch Repo applications using [install script](https://github.com/dillacorn/arch-hypr-dots/blob/main/scripts/install_arch_repo_apps.sh).

Install Arch AUR applications using [install script](https://github.com/dillacorn/arch-hypr-dots/blob/main/scripts/install_aur_repo_apps.sh).

Install Flatpak applications using [install script](https://github.com/dillacorn/arch-hypr-dots/blob/main/scripts/install_flatpak_apps.sh).

- Please feel free to modify scripts to remove and/or add applications of your preference for your own repository.

---

### Browser notes

- [Ungoogled-Chromium](https://github.com/dillacorn/arch-hypr-dots/blob/main/browser_notes/ungoogled-chromium.md)

- [Firefox_Privacy_Focused_Forks](https://github.com/dillacorn/arch-hypr-dots/blob/main/browser_notes/firefox_privacy_focused_forks.md)

- [Redirector_Extension_when_tailscale_magic_DNS_name_is_blocked](https://github.com/dillacorn/arch-hypr-dots/blob/main/browser_notes/redirector_extension_redirect_example.png)

---

### P.S.
My goal is to transition to Hypr (wayland) setup... work in progress clearly

### License
All code and notes are not under any formal license. If you find any of the scripts helpful, feel free to use, modify, publish, and distribute them to your heart's content. See https://unlicense.org/repo
