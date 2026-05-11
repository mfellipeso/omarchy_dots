#!/bin/bash
pamixer --default-source -t
swayosd-client --input-volume mute-toggle
pkill -RTMIN+11 waybar
