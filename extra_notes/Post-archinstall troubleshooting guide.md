# Post-archinstall Troubleshooting Guide

This guide provides step-by-step instructions to troubleshoot common issues encountered after installing Arch Linux, specifically related to drive mounts and permissions.

## Step 1: Verify Your Drives

1. **Open a Terminal.**
2. **List all drives and their UUIDs** to confirm your M.2 drive is recognized:
   ```bash
   sudo blkid
   ```
   - Look for the entry corresponding to your M.2 drive (e.g., `UUID=e9d89909-b5b1-49e5-90b1-279004892fz21`).

## Step 2: Edit `fstab`

1. **Open the `fstab` file** for editing:
   ```bash
   sudo micro /etc/fstab
   ```

2. **Add a new line for your Btrfs partition** at the end of the file. This line should include your UUID, the mount point, filesystem type, and options. For example:
   ```plaintext
   # Secondary M.2 Drive
   UUID=e9d89909-b5b1-49e5-90b1-279004892fz21    /mnt/M2   btrfs   defaults   0   2
   ```

3. **Save your changes** in `micro` by pressing `Ctrl + O`, then exit with `Ctrl + X`.

4. **Reboot your system** to apply the changes:
   ```bash
   sudo reboot
   ```

## Step 3: Set Permissions for Mount Points

After rebooting, you may need to set the appropriate permissions for your mount point.

### 3.1 Change Ownership

1. **Open a Terminal.**

2. **Change the ownership of the mount point** to your user:
   ```bash
   sudo chown <your-username>:<your-username> /mnt/M2
   ```

### 3.2 Recursively Change Ownership (if needed)

If you have files already in `/mnt/M2` and want to ensure access to them as well:

1. **Run the following command**:
   ```bash
   sudo chown -R <your-username>:<your-username> /mnt/M2
   ```

### 3.3 Adjust Permissions

1. **Set the permissions** to ensure your user can read, write, and execute:
   ```bash
   sudo chmod -R 755 /mnt/M2
   ```

## Step 4: Set Default ACLs (Optional)

To make sure any new files or directories created in `/mnt/M2` are automatically accessible to your user, you can set default ACLs:

1. **Run these commands**:
   ```bash
   sudo setfacl -R -m u:<your-username>:rwx /mnt/M2
   sudo setfacl -R -d -m u:<your-username>:rwx /mnt/M2
   ```

## Final Verification

After making these changes, verify that you can access and write to the mount point:

1. **Navigate to the Directory:**
   ```bash
   cd /mnt/M2
   ```

### Note

If you encounter any issues after modifying `fstab` or changing permissions, you may need to boot into recovery mode to revert changes or troubleshoot further.
