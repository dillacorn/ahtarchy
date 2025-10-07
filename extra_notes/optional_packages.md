# manual_install.md

## 🧰 Optional Utilities Collection

### 📁 File Management
#### TUI File Manager Suite
Modern terminal-based file management with image previews:
```bash
sudo pacman -S ueberzugpp yazi chafa
```
- **ueberzugpp** – Image previews in terminal  
- **yazi** – Fast terminal file manager  
- **chafa** – Terminal graphics rendering library

#### Drag & Drop Utility
```bash
yay -S dragon-drop
```
Simple GUI drag-and-drop from terminal.

---

### 🔊 Audio Control
#### Advanced Audio Mixer
```bash
sudo pacman -S pavucontrol
```
PulseAudio Volume Control GUI for fine-tuned device and stream management.

---

### 🎵 Media
#### YouTube Music Desktop Client
```bash
yay -S youtube-music-bin
```
Unofficial YouTube Music client with native UI.

---

### 🎥 Recording & Streaming
#### OBS Studio (Official Repo)
```bash
sudo pacman -S obs-studio
```
Full-featured video recording and live-streaming suite.

#### GPU Screen Recorder (AUR)
```bash
yay -S gpu-screen-recorder
```
Hardware-accelerated screen recording with minimal overhead.

#### Optional AUR Recording Tools
Choose one option:

**Option A – DroidCam (Android phone as webcam):**
```bash
yay -S droidcam v4l2loopback-dc-dkms obs-vkcapture
```
- **droidcam** – Android phone webcam  
- **v4l2loopback-dc-dkms** – Virtual camera kernel module  
- **obs-vkcapture** – Vulkan/OpenGL game capture for OBS  

**Option B – DistroAV (alternative virtual capture):**
```bash
yay -S distroav-bin obs-vkcapture
```
- **distroav-bin** – Lightweight A/V capture tool  
- **obs-vkcapture** – Vulkan/OpenGL capture integration  

**Usage Example:**
```bash
OBS_VKCAPTURE=1 gamemoderun %command%
```

---

### 🎮 Game Streaming
#### Sunshine (Game Streaming Server)
```bash
yay -S sunshine-bin
```
Host your desktop for Moonlight clients (NVIDIA Gamestream-compatible).

#### Moonlight (Client)
```bash
sudo pacman -S moonlight-qt
```
Connect to a Sunshine server from another PC or device.

---

### 🔐 Authentication & VPN
#### OTP Client
```bash
yay -S otpclient
```
Simple FOSS desktop 2FA/OTP client.

#### VPN Client
```bash
sudo pacman -S tailscale
```
Mesh VPN with zero-config networking and secure access control.

---

### 🎮 Gaming
#### Steam (Game Store)
```bash
sudo pacman -S steam
```
Official Steam client for Linux gaming.

#### Flatpak Gaming Utilities
```bash
flatpak install flathub com.heroicgameslauncher.hgl
```
- **Heroic Games Launcher** – Epic, GOG, and Amazon game management

---

### 📦 Torrenting
#### Torrent Client
```bash
sudo pacman -S qbittorrent
```
Qt-based torrent client with simple interface.

---

### 💾 System Backup
#### Timeshift (Snapshot Tool)
```bash
sudo pacman -S timeshift
```
System restore utility using rsync or Btrfs snapshots.

---

### 🖼️ GIF / Screen Capture
#### Kooha (GIF & Screen Recording)
```bash
sudo pacman -S kooha
```
Simple GNOME-style screen recorder supporting GIF and video formats.

---

### 🧩 Remote & Local Tools
#### Flatpak Networking Utilities
```bash
flatpak install flathub com.rustdesk.RustDesk
flatpak install flathub org.localsend.localsend_app
flatpak install flathub net.davidotek.pupgui2
```
- **RustDesk** – Open-source remote desktop  
- **LocalSend** – Cross-platform local file sharing  
- **ProtonUp-Qt** – Install and manage Proton-GE builds for Steam and Lutris

---

### 🎨 Multimedia Tools (Optional Bundle)
```bash
sudo pacman -S qpwgraph krita shotcut filezilla gthumb handbrake audacity
```
- **qpwgraph** – PipeWire patchbay visualizer  
- **krita** – Professional digital painting  
- **shotcut** – Open-source video editor  
- **filezilla** – FTP client  
- **gthumb** – Image viewer and manager  
- **handbrake** – Video transcoder  
- **audacity** – Audio editing suite
