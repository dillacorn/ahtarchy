# How to Install Flatpaks Using the `--user` Flag

# Primarily for `EXT4` file systems with seperate `"/home"` paritions

### Assuming flatpak is already installed on your system

# Step 1: Install Flatpak Applications

Use the following command to install a Flatpak application, specifying the `--user` flag to ensure it installs in your `/home` directory partition:

```sh
flatpak --user install flathub <app_name>
```

Replace `<app_name>` with the actual application ID, such as `org.telegram.desktop` or `com.github.IsmaelMartinez.teams_for_linux`

# Step 4: Update Installed Flatpaks

To keep your installed Flatpaks up to date, use:

```sh
flatpak --user update
```

# Tips:

- Always use the --user flag when installing Flatpaks to avoid consuming space in the system directories.

- If you’re unsure of the application ID, you can search for it on the Flathub website.
