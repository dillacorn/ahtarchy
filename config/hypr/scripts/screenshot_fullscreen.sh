#!/bin/bash
grim -g "$(slurp -o -r -c '##ff0000ff')" -t ppm - | satty --filename - --fullscreen --output-filename "$HOME/Pictures/Screenshots/$(date +%m%d%Y-%I%p-%S).png"
