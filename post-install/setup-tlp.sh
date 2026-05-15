#!/bin/bash
set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO TLP — edite os valores aqui
# =============================================================================
TLP_DROPIN="/etc/tlp.d/10-custom.conf"
PPD_UNIT="power-profiles-daemon.service"

read -r -d '' TLP_CONTENT <<'EOF' || true
# Gerenciado por omarchy_dots/post-install/setup-tlp.sh

# === Bateria — preservação ===
# ThinkPad L14 Gen 3 suporta start+stop; ciclo só entre 60% e 85%
START_CHARGE_THRESH_BAT0=60
STOP_CHARGE_THRESH_BAT0=85

# === CPU ===
# AC: governor performance pina os cores no boost.
# BAT: amd_pstate active só aceita powersave/performance; EPP controla agressividade.
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_performance
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1

# === Platform profile (ACPI) ===
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=balanced

# === GPU AMD ===
# 'high' define o teto em 1800MHz mas a iGPU ainda faz gating quando ociosa.
# Evita o stutter de ramp-up do 'auto' ao trocar de app/abrir VS Code.
RADEON_DPM_PERF_LEVEL_ON_AC=high
RADEON_DPM_PERF_LEVEL_ON_BAT=high
EOF
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

info "Instalando TLP..."
pacman_install tlp tlp-rdw

info "Verificando $PPD_UNIT..."
ppd_state="$(systemctl is-enabled "$PPD_UNIT" 2>/dev/null || true)"
case "$ppd_state" in
  masked)
    skipped "$PPD_UNIT já mascarado"
    ;;
  not-found|"")
    skipped "$PPD_UNIT não instalado — mascarando mesmo assim para prevenir conflito futuro"
    sudo systemctl mask "$PPD_UNIT"
    ok "$PPD_UNIT mascarado"
    ;;
  *)
    sudo systemctl disable --now "$PPD_UNIT" 2>/dev/null || true
    sudo systemctl mask "$PPD_UNIT"
    ok "$PPD_UNIT mascarado"
    ;;
esac

info "Verificando $TLP_DROPIN..."
sudo mkdir -p "$(dirname "$TLP_DROPIN")"

if [[ -f "$TLP_DROPIN" ]] && sudo cmp -s <(printf '%s\n' "$TLP_CONTENT") "$TLP_DROPIN"; then
  skipped "$TLP_DROPIN já está atualizado"
  dropin_changed=false
else
  printf '%s\n' "$TLP_CONTENT" | sudo tee "$TLP_DROPIN" > /dev/null
  ok "$TLP_DROPIN escrito"
  dropin_changed=true
fi

enable_service tlp.service

if $dropin_changed; then
  info "Reaplicando configuração com tlp start..."
  sudo tlp start > /dev/null
  ok "configuração aplicada"
fi
