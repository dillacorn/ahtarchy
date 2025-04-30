# Pre-Archinstall Troubleshooting Guide

This guide addresses common issues that may arise when preparing to run `archinstall`, particularly related to partitioning and ensuring a clean disk environment. Follow these steps before starting `archinstall` to avoid problems during the installation.

## 1. Check for Existing Partitions

If the drive already contains data or partitions, you may encounter errors during the installation. To avoid conflicts, check for existing partitions:

- Run the following command to list all partitions:
  ```bash
  lsblk
  ```

- If there are partitions listed on the target drive, you will need to either delete them or format the drive.

## 2. Deleting Partitions (Using `gdisk` or `fdisk`)

To delete existing partitions and create a clean environment, follow these steps:

1. Open the partitioning tool:
   ```bash
   gdisk /dev/nvme0n1
   ```

   Replace `/dev/nvme0n1` with your target drive.

2. Delete existing partitions:

   - Type `d` and hit `Enter`.
   - When prompted, enter the partition number to delete (e.g., `1`, `2`, etc.). Repeat this step until all partitions are deleted.

3. Confirm there are no partitions:

   - Type `i` to verify there are no partitions remaining.

4. Confirm Changes:

   After deleting all partitions, write the changes to the disk:

   - Type `w` and press `Enter` to write the partition table to the disk.

This will confirm the changes, and the disk will now be clean and ready for partitioning.

## 3. Running `archinstall`

Once you've cleaned up the partitions, run `archinstall`:

```bash
archinstall
```

Configure your disks (that have no partition) within `archinstall`, and your installation should proceed smoothly.
