#!/bin/bash
set -euo pipefail

# =============================================================================
# SSD TRIM (LUKS passthrough + fstrim semanal)
# Workaround temporario ate o Omarchy aplicar isso por padrao.
# Issue: https://github.com/basecamp/omarchy/issues/2229
#
# Sem TRIM, o controlador do SSD nao sabe quais blocos o filesystem liberou.
# Resultado: garbage collection trabalha as cegas, write amplification sobe,
# e SSDs budget (sem DRAM) degradam sustained writes drasticamente.
#
# Este script:
#   1. Persiste --allow-discards no header LUKS (TRIM atravessa a cripto).
#   2. Habilita fstrim.timer (TRIM semanal automatico).
#
# Trade-off de seguranca: --allow-discards revela quanto do disco esta em uso
# (nao revela conteudo). Aceitavel para workstation/notebook pessoal; igual ao
# default de Ubuntu, Fedora, Pop!_OS.
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

mapfile -t LUKS_NAMES < <(
  lsblk -nlpo NAME,TYPE | awk '$2 == "crypt" { print $1 }' | xargs -rn1 basename
)

if [[ ${#LUKS_NAMES[@]} -eq 0 ]]; then
  skipped "nenhum dispositivo LUKS ativo encontrado"
else
  for name in "${LUKS_NAMES[@]}"; do
    info "Verificando TRIM passthrough em '$name'..."

    status="$(sudo cryptsetup status "$name" 2>/dev/null || true)"
    flags_line="$(echo "$status" | awk -F: '/^[[:space:]]*flags:/ { print $2 }' | tr ',' ' ')"

    if grep -qw discards <<<"$flags_line"; then
      skipped "$name ja permite discards"
      continue
    fi

    info "$name sem discards -> aplicando --allow-discards persistente"
    sudo cryptsetup --allow-discards --persistent refresh "$name"
    ok "$name atualizado"
  done
fi

enable_service fstrim.timer
