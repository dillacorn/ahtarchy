Notes From Repo: https://github.com/dillacorn/ahtarchy

### Tip: Use Glorious Egg Roll if you're having trouble with proton experimental (bleeding edge)

### These are unique launch options depending on the game and use case for [hyprland](https://github.com/hyprwm/Hyprland)

## Counter-Strike 2 ~ stretched 1352x1080 240hz
hyprctl keyword monitor "DP-2,1352x1080@240,0x0,1"; gamemoderun %command% -novid +fps_max 0; hyprctl keyword monitor "DP-2,1920x1080@240,0x0,1"
```hyprctl keyword monitor "<name>,<resolution>@<refresh_rate>,<position>,<scale>"```

## The Finals ~ stretched 1352x1080 240hz
hyprctl keyword monitor "DP-2,1352x1080@240,0x0,1"; gamemoderun %command% -novid +fps_max 0 -high -dx12; hyprctl keyword monitor "DP-2,1920x1080@240,0x0,1"

# [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/)
# [lsfg-vk for Linux](https://github.com/PancakeTAS/lsfg-vk)

## The Finals
Launch Options:
```LSFG_PROCESS=TheFinals gamemoderun %command% -novid +fps_max 0 -high -dx12```

lsfg-vk conf.toml
```
[[game]] # override The Finals
exe = "TheFinals"

multiplier = 2
performance_mode = true
experimental_present_mode = "mailbox"
```
cap frame rate to a consistantly achieved value.. for me that's 120fps unfortunantly and I hate how this game preforms but it's a good example.

Ideally I won't be using lossless scaling for this title.

## Elden Ring
(60fps lock multiplied by 4 = 240 fps)

lsfg-vk conf.toml
```
[[game]] # override Elden Ring Nightreign
exe = "nightreign"

multiplier = 4
performance_mode = false
```
