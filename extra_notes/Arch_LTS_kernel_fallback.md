> **Note:** This guide was created using ChatGPT. All steps have been manually verified, but you can't deny the formatting looks good and it's easy to read.

# 🛡️ Installing the LTS Kernel on Arch Linux (as a Failsafe)

Arch Linux is a rolling-release distribution, which means kernel updates are frequent. Occasionally, a new kernel may cause issues such as hardware incompatibility or boot failures. Installing the **Long Term Support (LTS)** kernel alongside your main kernel is a smart safety precaution.

This guide shows how to:

- ✅ Check for available LTS kernels  
- ✅ Install the LTS kernel and headers  
- ✅ Update your bootloader  
- ✅ Boot into the LTS kernel when needed  

---

## 📦 1. Look Up Available Kernels

To check what kernels are available in the official repos:

```bash
pacman -Ss linux-lts
```

Look for entries like:

```bash
core/linux-lts 6.X.X-1
    The LTS Linux kernel and modules
core/linux-lts-headers 6.1.X-1
    Headers and scripts for building modules for the LTS Linux kernel
```

You're specifically looking for `linux-lts` and `linux-lts-headers`.

---

## 🛠️ 2. Install the LTS Kernel

Install the LTS kernel and its headers:

```bash
sudo pacman -S linux-lts linux-lts-headers
```

> 💡 Tip: If you use DKMS modules (like NVIDIA, VirtualBox, etc.), the headers are required.

---

## 🔃 3. Update Your Bootloader

### For GRUB

Regenerate the GRUB config to include the new LTS kernel:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### For systemd-boot

```bash
sudo nano /boot/loader/entries/arch-linux-lts.conf
```

Paste this: (replace UUID with OS drive UUID)

```bash
title   Arch Linux (LTS)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options root=UUID=XXXX-XXXX rw
```

to find your OS drive use
```bash
findmnt -no SOURCE /
```

to find your UUID for your OS drive use
```bash
sudo blkid
```

---

## 🔁 4. Reboot and Select the LTS Kernel

After rebooting, choose the LTS kernel from your bootloader menu. It will usually include "lts" in the name.

If you're using GRUB and don't see the menu:

- Hold **Shift** (for BIOS) or **Esc** (for UEFI) right after BIOS POST to show it.
- You can also edit `/etc/default/grub` and set `GRUB_TIMEOUT_STYLE=menu` to make the menu show always.

---

## ✅ 5. Verify You're Running the LTS Kernel

Once booted:

```bash
uname -r
```

You should see something like:

```bash
6.1.X-lts
```

This confirms you're running the LTS kernel.

---

## 🧼 Optional: Set LTS Kernel as Default

You can reorder boot entries or configure your bootloader to always default to the LTS kernel, especially useful if you're having stability issues.

For GRUB, set `GRUB_DEFAULT=saved` in `/etc/default/grub` and then use:

```bash
sudo grub-set-default "Advanced options for Arch Linux>Arch Linux, with Linux lts"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

(The exact entry name may vary; check it in the GRUB menu.)

---

## 📝 Final Notes

- You can keep both kernels installed side by side with no issue.
- If you later want to remove the LTS kernel:

```bash
sudo pacman -Rs linux-lts linux-lts-headers
```

- The LTS kernel is updated less frequently and is generally more stable, especially for older hardware or critical setups.

---

## 🔐 Why This Matters

By keeping the LTS kernel installed, you always have a **bootable kernel fallback** in case a mainline update breaks your system. This is a lightweight and effective insurance policy for Arch Linux users.

Stay rolling, stay safe.
