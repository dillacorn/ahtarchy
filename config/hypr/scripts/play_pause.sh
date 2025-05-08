#!/bin/bash

# Ensure we have playerctl installed
PLAYERCTL="/usr/bin/playerctl"

# Check if Spotify is running
spotify_player=$(playerctl -l | grep -i "spotify" | head -n 1)

if [ -n "$spotify_player" ]; then
    # If Spotify is running, send play-pause to it
    $PLAYERCTL -p "$spotify_player" play-pause
else
    # If Spotify isn't running, check for other media players
    other_player=$(playerctl -l | grep -i "chromium\|vlc\|firefox" | head -n 1)
    
    if [ -n "$other_player" ]; then
        # If another media player is found, send play-pause to it
        $PLAYERCTL -p "$other_player" play-pause
    else
        # If no media player is found, send play-pause to the default player
        $PLAYERCTL play-pause
    fi
fi
