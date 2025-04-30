# 📡 Connecting to Wi-Fi in Arch Linux (Live ISO)

Follow these steps to connect to a wireless network using `iwctl` in the Arch Linux live environment.

## 🔹 Step 1: Start `iwctl`
```sh
iwctl
## Step 2: List Available Devices
device list
### Look for your Wi-Fi device (e.g., wlan0).
## Step 3: Scan for Networks
station wlan0 scan
station wlan0 get-networks
### If you see available networks, proceed to Step 4. If no networks appear, troubleshoot below.

## 🛠 Troubleshooting: No Networks Found
### ✅ Restart Wireless Power
device wlan0 set-property Powered off
device wlan0 set-property Powered on
### or  
adapter phy0 set-property Powered on

### 🔄 Retry Scanning for Networks
station wlan0 scan
station wlan0 get-networks

### ❌ "Operation Not Permitted" Error?
### If your laptop has a physical switch or function key to enable Wi-Fi, ensure it is turned on.

## 🔹 Step 4: Connect to a Network
station wlan0 connect "SSID_Name"
### Enter your Wi-Fi password when prompted.

## ✅ Test Internet Connection
ping archlinux.org
### If you receive responses, you are connected to the internet!
