enable_keyring_pam() {
    # Handle both console and graphical logins
    local pam_files=("/etc/pam.d/login" "/etc/pam.d/gdm-password" "/etc/pam.d/lightdm")
    
    for pam_file in "${pam_files[@]}"; do
        if [ -f "$pam_file" ]; then
            if ! grep -q "pam_gnome_keyring.so" "$pam_file"; then
                echo -e "\n# Unlock GNOME Keyring (added by dotfiles setup)\nauth       optional     pam_gnome_keyring.so\nsession    optional     pam_gnome_keyring.so auto_start" | sudo tee -a "$pam_file" >/dev/null
                echo "[OK] Added keyring PAM to ${pam_file}"
            else
                echo "[SKIP] Keyring PAM already exists in ${pam_file}"
            fi
        fi
    done
}