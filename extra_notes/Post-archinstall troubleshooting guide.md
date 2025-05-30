# 🛠️ Post-Archinstall Troubleshooting Guide

This guide provides step-by-step instructions to troubleshoot common issues encountered after installing Arch Linux, especially around drive mounting and permissions.

---

## 🧭 Step 1: Verify Your Drives

1. **Open a terminal.**
2. **List all drives and their UUIDs** to confirm your M.2 drive is recognized:

   ```bash
   sudo blkid
   ```

   Look for the entry that corresponds to your M.2 drive.
   Example output:
   ```
   /dev/nvme0n1p1: UUID="e9d89909-b5b1-49e5-90b1-279004892fz21" TYPE="btrfs"
   ```

---

## 📝 Step 2: Edit `fstab`

1. **Open `/etc/fstab` for editing:**

   ```bash
   sudo micro /etc/fstab
   ```

2. **Add a line for your secondary drive (e.g., Btrfs partition):**

   ```plaintext
   # Secondary M.2 Drive
   UUID=e9d89909-b5b1-49e5-90b1-279004892fz21    /mnt/M2   btrfs   defaults   0   2
   ```

3. **Save and exit in `micro`:**

   - Press `Ctrl + O` to save.
   - Press `Ctrl + X` to exit.

4. **Reboot to apply changes:**

   ```bash
   sudo reboot
   ```

---

## 🔐 Step 3: Set Permissions for Mount Point

After rebooting, ensure your user has access to the mount point.

### 🧑‍💻 3.1 Change Ownership

```bash
sudo chown <your-username>:<your-username> /mnt/M2
```

### 🔁 3.2 Recursively Change Ownership (if needed)

```bash
sudo chown -R <your-username>:<your-username> /mnt/M2
```

### 🔒 3.3 Adjust Permissions

```bash
sudo chmod -R 755 /mnt/M2
```

---

## ⚙️ Step 4: Set Default ACLs (Optional)

To ensure any new files/directories are accessible to your user:

```bash
sudo setfacl -R -m u:<your-username>:rwx /mnt/M2
sudo setfacl -R -d -m u:<your-username>:rwx /mnt/M2
```

---

## ✅ Final Verification

Check that everything is working properly:

```bash
cd /mnt/M2
```

You should be able to create files, list contents, and navigate freely.

> 📝 **Note:** If you encounter issues booting or mounting after editing `fstab`, boot into a live ISO to revert changes or troubleshoot.
