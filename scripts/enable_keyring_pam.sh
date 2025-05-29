enable_keyring_pam() {
    local pam_file="/etc/pam.d/login"
    
    echo "[DEBUG] Checking $pam_file"
    
    # Verify file exists
    if [ ! -f "$pam_file" ]; then
        echo "[ERROR] $pam_file does not exist!"
        return 1
    fi
    
    # Verify readable
    if [ ! -r "$pam_file" ]; then
        echo "[ERROR] Cannot read $pam_file"
        return 1
    fi
    
    # Check for existing entry
    if grep -q "pam_gnome_keyring.so" "$pam_file"; then
        echo "[INFO] Keyring PAM already configured"
        return 0
    fi
    
    # Attempt to append
    echo "[DEBUG] Attempting to append to $pam_file"
    if ! echo -e "\n# Added by dotfiles setup\nauth optional pam_gnome_keyring.so\nsession optional pam_gnome_keyring.so auto_start" | sudo tee -a "$pam_file" >/dev/null; then
        echo "[ERROR] Failed to write to $pam_file"
        return 1
    fi
    
    echo "[SUCCESS] Updated $pam_file"
    return 0
}