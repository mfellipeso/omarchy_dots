#!/bin/bash

VPN_NAME="Hexa"

if ! nmcli connection show "$VPN_NAME" &>/dev/null; then
    echo '{"text": "󰌾", "tooltip": "VPN Hexa nao encontrada", "class": "missing"}'
    exit 0
fi

if nmcli connection show --active | grep -q "$VPN_NAME"; then
    echo '{"text": "󰌾", "tooltip": "VPN Hexa: Conectada", "class": "connected"}'
else
    echo '{"text": "󰌿", "tooltip": "VPN Hexa: Desconectada", "class": "disconnected"}'
fi
