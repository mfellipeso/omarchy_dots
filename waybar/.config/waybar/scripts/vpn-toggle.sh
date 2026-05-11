#!/bin/bash

VPN_NAME="Hexa"

# Verify the connection exists
if ! nmcli connection show "$VPN_NAME" &>/dev/null; then
    notify-send "VPN" "Conexao '$VPN_NAME' nao encontrada" --icon=dialog-error
    exit 1
fi

# Toggle: if active, disconnect; if inactive, connect
if nmcli connection show --active | grep -q "$VPN_NAME"; then
    nmcli connection down "$VPN_NAME"
else
    nmcli connection up "$VPN_NAME"
fi
