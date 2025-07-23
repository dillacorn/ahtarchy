#!/bin/bash

PLAYERCTL="/usr/bin/playerctl"

# 1. Check for Spotify
spotify_player=$($PLAYERCTL -l 2>/dev/null | grep -i "^spotify" | head -n 1)

if [ -n "$spotify_player" ]; then
    $PLAYERCTL -p "$spotify_player" play-pause
    exit 0
fi

# 2. Check for YouTube Music by player name (not by track title)
for player in $($PLAYERCTL -l 2>/dev/null); do
    # Skip Spotify explicitly
    if [[ "$player" =~ [Ss]potify ]]; then
        continue
    fi

    # Check if player name matches YouTube Music (case insensitive)
    if [[ "$player" =~ [Yy]outube.*[Mm]usic ]]; then
        $PLAYERCTL -p "$player" play-pause
        exit 0
    fi
done

# 3. Fallback: Control default player if one exists
$PLAYERCTL play-pause 2>/dev/null
