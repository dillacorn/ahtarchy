#!/bin/bash

echo "Attempting to close wofi..."

# Try gentle kill first
pkill -x wofi
sleep 0.3

# Wait for wofi to fully exit, max 15 seconds
timeout=150
interval=0.1
count=0
while pgrep -x wofi >/dev/null; do
    sleep $interval
    count=$((count + 1))
    if [ $count -ge $timeout ]; then
        echo "Timeout waiting for wofi to exit, forcing kill..."
        pkill -9 -x wofi
        sleep 0.3
        # Try kill again just in case
        pkill -9 -x wofi
        break
    fi
done

echo "Launching hyprpicker..."
setsid hyprpicker >/dev/null 2>&1 &

# Wait a bit for hyprpicker to start
sleep 1

# Double-check if wofi popped back, kill again if needed
if pgrep -x wofi >/dev/null; then
    echo "wofi reappeared, killing again..."
    pkill -9 -x wofi
fi

echo "Done."
