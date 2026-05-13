#!/bin/bash
set -euo pipefail

# =============================================================================
# LUKS PERFORMANCE TUNING
# Workaround temporario ate o Omarchy aplicar essas configuracoes por padrao.
# Issue: https://github.com/basecamp/omarchy/issues/2229
#
# Aplica nos dispositivos LUKS ativos (persistido no header):
#   --perf-no_read_workqueue    -> bypass da workqueue de leitura
#   --perf-no_write_workqueue   -> bypass da workqueue de escrita
#
# Em SSD com AES-NI o overhead da workqueue do dm-crypt eh maior que o custo
# da propria criptografia, entao bypass = ganho grande de IOPS e latencia.
#
# Cryptsetup pode pedir a passphrase para autorizar a alteracao do header.
# As flags so ficam totalmente ativas apos reboot.
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

DESIRED_FLAGS=(no-read-workqueue no-write-workqueue)

mapfile -t LUKS_NAMES < <(
  lsblk -nlpo NAME,TYPE | awk '$2 == "crypt" { print $1 }' | xargs -rn1 basename
)

if [[ ${#LUKS_NAMES[@]} -eq 0 ]]; then
  skipped "nenhum dispositivo LUKS ativo encontrado"
  _finish 0
fi

needs_reboot=false

for name in "${LUKS_NAMES[@]}"; do
  info "Verificando LUKS device '$name'..."

  status="$(sudo cryptsetup status "$name" 2>/dev/null || true)"
  flags_line="$(echo "$status" | awk -F: '/^[[:space:]]*flags:/ { print $2 }' | tr ',' ' ')"

  missing=()
  for f in "${DESIRED_FLAGS[@]}"; do
    grep -qw "$f" <<<"$flags_line" || missing+=("$f")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    skipped "$name ja tem: ${DESIRED_FLAGS[*]}"
    continue
  fi

  info "$name esta sem: ${missing[*]} -> aplicando refresh persistente"
  sudo cryptsetup \
    --perf-no_read_workqueue \
    --perf-no_write_workqueue \
    --persistent \
    refresh "$name"
  ok "$name atualizado (efeito completo apos reboot)"
  needs_reboot=true
done

if $needs_reboot; then
  echo ""
  info "Flags LUKS so entram em vigor apos reboot. Considere reiniciar."
fi
