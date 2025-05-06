#!/bin/bash

tempfile=$(mktemp --suffix=.png)
grim -g "$(slurp)" "$tempfile"
qr_output=$(zbarimg --quiet "$tempfile" | sed 's/QR-Code://')
rm "$tempfile"

if [[ -n "$qr_output" ]]; then
  echo -n "$qr_output" | wl-copy
  notify-send "QR Code Scanned" "$qr_output"
else
  notify-send "QR Code" "No QR code found."
fi
