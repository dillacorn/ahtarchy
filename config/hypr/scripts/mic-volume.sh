#!/bin/bash

while true; do
    # Always target the current default microphone
    pactl set-source-volume @DEFAULT_SOURCE@ 100%
    pactl set-source-mute @DEFAULT_SOURCE@ 0
    
    # Optional: Verify the current default mic
    DEFAULT_MIC=$(pactl get-default-source)
    echo "$(date '+%H:%M:%S') - Locking default mic ($DEFAULT_MIC) at 100%"
    
    sleep 2
done
