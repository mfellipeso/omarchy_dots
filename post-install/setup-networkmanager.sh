#!/bin/bash
set -euo pipefail

# =============================================================================
# NETWORKMANAGER — substitui iwd com suporte a 802.1X (eduroam)
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

PACKAGES=(
  networkmanager
  wpa_supplicant
  network-manager-applet
  nm-connection-editor
  networkmanager-l2tp
  strongswan
)

# Serviços que devem ser desabilitados (conflitam com NetworkManager)
DISABLE_SERVICES=(iwd systemd-networkd)

# --- 1. Pacotes ---------------------------------------------------------------
info "Pacotes NetworkManager..."
pacman_install "${PACKAGES[@]}"

# --- 2. Desabilitar serviços conflitantes -------------------------------------
info "Verificando serviços conflitantes..."
for svc in "${DISABLE_SERVICES[@]}"; do
  if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
    sudo systemctl disable --now "$svc"
    ok "$svc desabilitado e parado"
  else
    skipped "$svc já desabilitado"
  fi
done

# --- 3. Habilitar serviços ----------------------------------------------------
enable_service wpa_supplicant
enable_service NetworkManager

ok "Setup do NetworkManager concluído."
