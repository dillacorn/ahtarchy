#!/bin/bash

GEOM=$(slurp -b '#ffffff20' -c '#00000040')
[ -z "$GEOM" ] && exit 1

grim -g "$GEOM" -t ppm - | satty --filename - --output-filename "$HOME/Pictures/Screenshots/$(date +%m%d%Y-%I%p-%S).png"
