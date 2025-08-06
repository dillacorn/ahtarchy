#!/bin/bash
ddcutil getvcp 10 | grep -oP 'current value =\s*\K[0-9]+' > /tmp/brightness_level
