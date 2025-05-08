#!/bin/bash
grim -g "$(slurp -b '##ffffff80' -c '##00000080')" -t ppm - | satty --filename - --output-filename "$HOME/Pictures/Screenshots/$(date +%m%d%Y-%I%p-%S).png"
