# 🔐 AirVPN WireGuard Setup on Linux

This guide shows how to configure and use **AirVPN with WireGuard** on any Linux system using the terminal.

---

## 📥 1. Generate WireGuard Config

1. Go to: [https://airvpn.org/generator/](https://airvpn.org/generator/)
2. Choose:
   - **Protocol:** WireGuard
   - **Device name:** (e.g. `linux-client`)
   - **Port:** (443 is good for stealth)
   - **Server or Country** of your choice
   - Click "Create" to generate keys
3. Download the `.conf` file (e.g. `AirVPN-Server.conf`)

---

## ⚙️ 2. Bring Up the VPN

Run the following command pointing directly to your config file (e.g., in Downloads):

```bash
sudo wg-quick up ~/Downloads/AirVPN-Server.conf
```

To stop it:
```bash
sudo wg-quick down ~/Downloads/AirVPN-Server.conf
```

> **Note:** Once `wg-quick up` is run, the WireGuard interface will appear in your Network Manager applet for easier management.
