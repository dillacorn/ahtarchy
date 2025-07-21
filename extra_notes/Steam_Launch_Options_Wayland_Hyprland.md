Notes From Repo: https://github.com/dillacorn/arch-hypr-dots

### Tip: Use Glorious Egg Roll if you're having trouble with proton experimental (bleeding edge)

### These are unique launch options depending on the game and use case for [hyprland](https://github.com/hyprwm/Hyprland)

## Counter-Strike 2 ~ stretched 1352x1080 240hz
hyprctl keyword monitor "DP-2,1352x1080@240,0x0,1"; gamemoderun %command% -novid +fps_max 0; hyprctl keyword monitor "DP-2,1920x1080@240,0x0,1"
```hyprctl keyword monitor "<name>,<resolution>@<refresh_rate>,<position>,<scale>"```

## The Finals ~ stretched 1352x1080 240hz
hyprctl keyword monitor "DP-2,1352x1080@240,0x0,1"; gamemoderun %command% -novid +fps_max 0 -high -dx12; hyprctl keyword monitor "DP-2,1920x1080@240,0x0,1"

# Lossless Scaling Enabled

## The Finals
[note to disable lossless scaling commenting out for games that also show up in btop as "GameThread"]
```[[game]] # override GameThread
exe = "GameThread"

multiplier = 2
flow_scale = 0.7
performance_mode = true
experimental_present_mode = "mailbox"
```
