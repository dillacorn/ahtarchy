Notes From Repo: https://github.com/dillacorn/arch-hypr-dots

# If you're having a difficult time launching a game (that should work)

### or it's crashing on launch when it should be working here's something you can try.

- Install flatpak steam

If you're using EXT4 file system (install to sudo users "/home" partition as to not fill up "/" (root partition)

```
flatpak --user install flathub com.valvesoftware.Steam
```

on BTRFS file system remove "--user" (BTRFS file system dynamically allocates subvolume space so it's not an issue to install on root)

```
flatpak install flathub com.valvesoftware.Steam
```

- Launch steam flatpak (use any method you prefer)

- Launch game with similar configuration...aka correct Proton version

- If the game successfully launches now close it.

- reboot computer!

- launch Steam from multilib arch repo

- Launch game with correct proton version.. I.E. GloriousEggrole or Bleeding Edge Proton Experimental

# congrats for some reason the game works now...

## P.S.
yeah this kind of solution sucks.. but it's really the developers fault if this is the solution you have to use... I assume if this is a solution you have to resort to it's because the developer, developed for flatpak steam version and didn't consider other versions of steam.. no idea to be frank...
