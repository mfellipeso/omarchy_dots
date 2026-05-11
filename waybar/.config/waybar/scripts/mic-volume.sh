#!/bin/bash
pamixer --default-source "$@"
pkill -RTMIN+11 waybar
