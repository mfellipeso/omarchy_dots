#!/bin/bash
set -euo pipefail

# =============================================================================
# NETWORKMANAGER — substitui iwd com suporte a 802.1X (eduroam)
# =============================================================================

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

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

info()    { echo -e "${CYAN}==> $*${RESET}"; }
ok()      { echo -e "${GREEN}    ok: $*${RESET}"; }
skipped() { echo -e "${YELLOW}    --: $*${RESET}"; }

# --- 1. Pacotes ---------------------------------------------------------------
info "Verificando pacotes NetworkManager..."
to_install=()
for pkg in "${PACKAGES[@]}"; do
  if pacman -Q "$pkg" &>/dev/null; then
    skipped "$pkg já instalado"
  else
    to_install+=("$pkg")
  fi
done

if [[ ${#to_install[@]} -gt 0 ]]; then
  sudo pacman -S --noconfirm "${to_install[@]}"
  ok "pacotes instalados"
fi

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

# --- 3. Habilitar wpa_supplicant ----------------------------------------------
info "Verificando serviço wpa_supplicant..."
if systemctl is-enabled --quiet wpa_supplicant && systemctl is-active --quiet wpa_supplicant; then
  skipped "wpa_supplicant já habilitado e ativo"
else
  sudo systemctl enable --now wpa_supplicant
  ok "wpa_supplicant habilitado e iniciado"
fi

# --- 4. Habilitar NetworkManager ----------------------------------------------
info "Verificando serviço NetworkManager..."
if systemctl is-enabled --quiet NetworkManager && systemctl is-active --quiet NetworkManager; then
  skipped "NetworkManager já habilitado e ativo"
else
  sudo systemctl enable --now NetworkManager
  ok "NetworkManager habilitado e iniciado"
fi

ok "Setup do NetworkManager concluído."
