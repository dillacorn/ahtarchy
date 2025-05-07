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

# Capture video with 10-minute timeout
timeout 600 wf-recorder -g "$Coords" -f "$TmpRecordPath" || exit

# Prompt user for save location
SavePath=$(zenity \
	--file-selection \
	--save \
	--confirm-overwrite \
	--file-filter=*.gif \
	--filename="${DefaultSaveDir}/.gif") || exit

# Append .gif if missing
[[ $SavePath =~ \.gif$ ]] || SavePath="${SavePath}.gif"

# Generate color palette
ffmpeg -i "$TmpRecordPath" -filter_complex "palettegen=stats_mode=full" "$TmpPalettePath" -y || exit

# Reset umask to default
umask 022

# Generate final GIF using the palette
ffmpeg -i "$TmpRecordPath" -i "$TmpPalettePath" -filter_complex "paletteuse=dither=sierra2_4a" "$SavePath" -y || exit