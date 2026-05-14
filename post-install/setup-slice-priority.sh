#!/bin/bash
set -euo pipefail

# =============================================================================
# PRIORIDADES DE SLICE DO SYSTEMD
# -----------------------------------------------------------------------------
# Dá à sessão GUI (user.slice) prioridade estrutural de CPU/IO sobre todo
# trabalho em segundo plano (system.slice: docker, daemons, cron).
# Documentado em systemd.resource-control(5).
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

USER_SLICE_DIR="/etc/systemd/system/user-.slice.d"
SYSTEM_SLICE_DIR="/etc/systemd/system/system.slice.d"
USER_DROPIN="$USER_SLICE_DIR/desktop-priority.conf"
SYSTEM_DROPIN="$SYSTEM_SLICE_DIR/background-priority.conf"

read -r -d '' USER_CONF <<'EOF' || true
[Slice]
IOWeight=1000
MemoryLow=4G
CPUWeight=200
EOF

read -r -d '' SYSTEM_CONF <<'EOF' || true
[Slice]
IOWeight=100
CPUWeight=100
EOF

# write_dropin <path> <conteúdo>
write_dropin() {
  local path="$1" content="$2"
  if [[ -f "$path" ]] && diff -q <(echo "$content") "$path" &>/dev/null; then
    skipped "$path já no estado desejado"
    return 1
  fi
  sudo mkdir -p "$(dirname "$path")"
  echo "$content" | sudo tee "$path" > /dev/null
  ok "$path escrito"
  return 0
}

changed=0
write_dropin "$USER_DROPIN"   "$USER_CONF"   && changed=1
write_dropin "$SYSTEM_DROPIN" "$SYSTEM_CONF" && changed=1

if (( changed )); then
  info "Recarregando systemd..."
  sudo systemctl daemon-reload
  ok "daemon-reload concluído"
fi

# set-property aplica ao vivo no slice em execução (sem reboot).
# Idempotente: o systemd só atualiza o cgroup se os valores divergirem.
info "Aplicando ao vivo em user.slice..."
sudo systemctl set-property user.slice IOWeight=1000 MemoryLow=4G CPUWeight=200
ok "user.slice atualizado"

info "Aplicando ao vivo em system.slice..."
sudo systemctl set-property system.slice IOWeight=100 CPUWeight=100
ok "system.slice atualizado"

ok "Setup de prioridades de slice concluído."
