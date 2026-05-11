#!/bin/bash

MUTED=$(pamixer --default-source --get-mute)
VOLUME=$(pamixer --default-source --get-volume)

if [ "$MUTED" = "true" ]; then
    echo "{\"text\": \"󰍭\", \"tooltip\": \"Microfone: Mutado\", \"class\": \"muted\"}"
else
    echo "{\"text\": \"󰍬\", \"tooltip\": \"Microfone: ${VOLUME}%\", \"class\": \"open\"}"
fi
