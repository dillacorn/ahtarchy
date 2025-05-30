````markdown
# ⚠️ Pre-Archinstall Troubleshooting Guide

This guide helps you prepare your system for a smooth `archinstall` process. It focuses on checking and cleaning your target disk to avoid installation issues related to partitioning.

---

## ✅ Step 1: Check for Existing Partitions

Before installing, you should verify if the target drive has any existing partitions:

```bash
lsblk
```

Look for your target drive (e.g., `/dev/nvme0n1`, `/dev/sda`) and see if it lists any partitions (like `/dev/nvme0n1p1`, `/dev/sda1`, etc.).

> If partitions exist, you'll need to delete them to avoid conflicts.

---

## 🧹 Step 2: Deleting Partitions with `gdisk`

To safely wipe existing partitions using `gdisk`:

1. **Launch `gdisk` on your target drive** (replace `/dev/nvme0n1` with your actual drive):

   ```bash
   gdisk /dev/nvme0n1
   ```

2. **Delete all partitions:**

   - Type `d` and press `Enter`.
   - Enter the partition number to delete (e.g., `1`, `2`, etc.).
   - Repeat until all partitions are removed.

3. **Verify deletion:**

   - Type `i` to check the partition list. If none are shown, you're good to go.

4. **Write changes to disk:**

   - Type `w` and press `Enter`.
   - Confirm when prompted. This writes a new partition table and clears the old data.

> Your disk is now clean and ready for `archinstall`.

---

## 💡 Step 3: Run `archinstall`

Once the disk is clean, start the installer:

```bash
archinstall
```

Follow the guided setup to partition and install Arch Linux on your clean drive.

> Pro tip: If the disk is properly cleaned, `archinstall` will have fewer chances of encountering errors.

---

## ✨ Summary

- Use `lsblk` to inspect existing partitions.
- Wipe partitions using `gdisk` before running the installer.
- Start `archinstall` only after confirming the target disk is clean.

Taking these precautions will help ensure a smooth and trouble-free Arch Linux installation.
````
