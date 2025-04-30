Notes From Repo: https://github.com/dillacorn/arch-hypr-dots

### Edit grub config

```sh
sudo micro /etc/default/grub
```

### add and/or edit last boot kernel selection (primarily for linux-tkg)
```sh
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
```

### if you have a high refresh rate display
```sh
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet amdgpu.dc=1 video=1920x1080@240"
GRUB_GFXMODE=1920x1080x32
```

### run this command to sync the changes
```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
