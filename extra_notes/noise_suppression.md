## Directions from Werman
#### [Werman's README - PipeWire Instructions](https://github.com/werman/noise-suppression-for-voice?tab=readme-ov-file#pipewire)

---

## My Instructions (Using Terminal)

# 1. Change Current Directory to `/Downloads`
```sh
cd ~/Downloads/
```

# 2. Download the Latest Version
```sh
wget $(curl -s https://api.github.com/repos/werman/noise-suppression-for-voice/releases/latest | jq -r '.assets[] | select(.name=="linux-rnnoise.zip") | .browser_download_url')
```

# 3. Unzip the Downloaded File
```sh
unzip linux-rnnoise.zip
```

# 4. Create the PipeWire Configuration Directory
```sh
mkdir -p ~/.config/pipewire/pipewire.conf.d
```

# 5. Create and Edit `.conf` File
```sh
nano ~/.config/pipewire/pipewire.conf.d/99-input-denoising.conf
```

# 6. Paste the Following Configuration in `99-input-denoising.conf`
# **Notice!** - Change `"plugin = /home/dillacorn"` to your username.

```sh
context.modules = [
{   name = libpipewire-module-filter-chain
    args = {
        node.description =  "Noise Canceling source"
        media.name =  "Noise Canceling source"
        filter.graph = {
            nodes = [
                {
                    type = ladspa
                    name = rnnoise
                    plugin = /home/dillacorn/.config/pipewire/librnnoise_ladspa.so
                    label = noise_suppressor_mono
                    control = {
                        "VAD Threshold (%)" = 50.0
                        "VAD Grace Period (ms)" = 200
                        "Retroactive VAD Grace (ms)" = 0
                    }
                }
            ]
        }
        capture.props = {
            node.name =  "capture.rnnoise_source"
            node.passive = true
            audio.rate = 48000
        }
        playback.props = {
            node.name =  "rnnoise_source"
            media.class = Audio/Source
            audio.rate = 48000
        }
    }
}
]
```

# 7. Copy the Plugin to the Configuration Directory
```sh
cp ~/Downloads/linux-rnnoise/ladspa/librnnoise_ladspa.so ~/.config/pipewire
```

# 8. Restart PipeWire (Ensure Config Is Correct before execution)
```sh
systemctl restart --user pipewire.service
```

![noise_suppression](https://raw.githubusercontent.com/dillacorn/arch-hypr-dots/refs/heads/main/extra_notes/screenshots_for_guides/werman_noise_suppression/noise_suppression.png)

# done, enjoy!