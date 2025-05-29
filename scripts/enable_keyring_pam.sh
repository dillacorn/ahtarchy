# Create a temporary file with the new contents
TMPFILE=$(mktemp)
sudo cat /etc/pam.d/login > "$TMPFILE"

# Add our lines if they don't exist
if ! grep -q "pam_gnome_keyring.so" "$TMPFILE"; then
    echo -e "\n# GNOME Keyring Integration (added $(date))" >> "$TMPFILE"
    echo "auth       optional     pam_gnome_keyring.so" >> "$TMPFILE"
    echo "session    optional     pam_gnome_keyring.so auto_start" >> "$TMPFILE"
fi

# Verify the changes
echo "=== New file contents ==="
tail -n 5 "$TMPFILE"

# Confirm with user
read -p "Apply these changes to /etc/pam.d/login? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo cp "$TMPFILE" /etc/pam.d/login
    echo "Changes applied successfully!"
else
    echo "Changes cancelled."
fi
rm "$TMPFILE"