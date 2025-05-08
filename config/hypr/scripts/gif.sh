#!/usr/bin/env bash

# If an instance of wf-recorder is running under this user, kill it with SIGINT and exit
pkill --euid "$USER" --signal SIGINT wf-recorder && exit

# Define paths
DefaultSaveDir="$HOME/Videos/Gifs"
TmpPathPrefix="/tmp/gif-record"
TmpRecordPath="${TmpPathPrefix}-cap.mp4"
TmpPalettePath="${TmpPathPrefix}-palette.png"

# Create save directory if it doesn't exist
mkdir -p "$DefaultSaveDir"

# Trap for cleanup on exit
OnExit() {
	[[ -f "$TmpRecordPath" ]] && rm -f "$TmpRecordPath"
	[[ -f "$TmpPalettePath" ]] && rm -f "$TmpPalettePath"
}
trap OnExit EXIT

# Set umask so tmp files are only accessible to the user
umask 177

# Get selection and honor escape key
Coords=$(slurp) || exit

# Notify user that recording is starting
notify-send "GIF Recording" "Recording started."

# Capture video with 10-minute timeout
timeout 600 wf-recorder -g "$Coords" -f "$TmpRecordPath" || exit

# Create a timestamp-based filename like 05072025-033245PM.gif
Timestamp=$(date "+%m%d%Y-%I%M%p-%S")
SavePath="${DefaultSaveDir}/${Timestamp}.gif"

# Generate color palette
ffmpeg -i "$TmpRecordPath" -filter_complex "palettegen=stats_mode=full" "$TmpPalettePath" -y || exit

# Reset umask to default
umask 022

# Generate final GIF using the palette
ffmpeg -i "$TmpRecordPath" -i "$TmpPalettePath" -filter_complex "paletteuse=dither=sierra2_4a" "$SavePath" -y || exit

# Notify user that the GIF has been saved and where
notify-send "GIF Saved" "Your GIF has been saved to $SavePath"
