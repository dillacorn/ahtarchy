# manual_install.md

## 📁 File Management
### TUI File Manager Suite
Modern terminal-based file management
```bash
sudo pacman -S ueberzugpp yazi chafa
```
Includes:
- ueberzugpp - Image preview in terminal
- yazi - Blazing fast terminal file manager
- chafa - Terminal graphics library

### Drag & Drop Utility
```bash
yay -S dragon-drop
```
Simple drag-and-drop tool

## 🔊 Audio Control
### Advanced Audio Control Panel
```bash
sudo pacman -S pavucontrol
```
PulseAudio Volume Control - GUI mixer for advanced audio management.

## 🎵 Media
### YouTube Music Client
```bash
yay -S youtube-music-bin
```
Unofficial desktop client for YouTube Music with native feel.

## 🎥 Recording & Streaming
### OBS Studio (Arch Linux repo)
```bash
sudo pacman -S obs-studio
```

### Optional AUR Recording Tools
Choose one option:

**Option A: DroidCam (Android phone as webcam):**
```bash
yay -S droidcam v4l2loopback-dc-dkms obs-vkcapture
```
- droidcam - Use Android phone as webcam
- v4l2loopback-dc-dkms - Required for droidcam virtual camera
- obs-vkcapture - Vulkan/OpenGL capture for OBS

**Option B: DistroAV (alternative recording solution):**
```bash
yay -S distroav-bin obs-vkcapture
```
- distroav-bin - Recording utility (can replace droidcam functionality)
- obs-vkcapture - Vulkan/OpenGL capture for OBS

#### Using obs-vkcapture
Launch options for games:
```bash
OBS_VKCAPTURE=1 gamemoderun %command%
```