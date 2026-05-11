#!/bin/bash
set -euo pipefail

# =============================================================================
# CONFIGURAR DNS (IPv4 + IPv6) EM UMA CONEXÃO DO NETWORKMANAGER
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

need_cmd nmcli "instale NetworkManager primeiro" || _finish 1

# --- 1. Listar conexões -------------------------------------------------------
mapfile -t CONNS < <(nmcli -t -f NAME,TYPE,DEVICE connection show)

if [[ ${#CONNS[@]} -eq 0 ]]; then
  err "nenhuma conexão encontrada"
  _finish 1
fi

info "Conexões disponíveis:"
for i in "${!CONNS[@]}"; do
  IFS=: read -r name type device <<<"${CONNS[$i]}"
  printf "  ${CYAN}[%d]${RESET} %-30s %-20s %s\n" $((i+1)) "$name" "$type" "${device:-—}"
done

# --- 2. Selecionar conexão ----------------------------------------------------
read -rp "$(echo -e "${CYAN}Escolha o número da conexão: ${RESET}")" conn_num
if ! [[ "$conn_num" =~ ^[0-9]+$ ]] || (( conn_num < 1 || conn_num > ${#CONNS[@]} )); then
  err "seleção inválida"
  _finish 1
fi

IFS=: read -r CONN_NAME _ _ <<<"${CONNS[$((conn_num-1))]}"
ok "selecionado: $CONN_NAME"

# --- 3. Selecionar provedor DNS -----------------------------------------------
info "Provedores DNS:"
echo -e "  ${CYAN}[1]${RESET} Cloudflare (1.1.1.1 / 2606:4700:4700::1111)"
echo -e "  ${CYAN}[2]${RESET} Google     (8.8.8.8 / 2001:4860:4860::8888)"
read -rp "$(echo -e "${CYAN}Escolha o provedor: ${RESET}")" dns_num

case "$dns_num" in
  1)
    PROVIDER="Cloudflare"
    IPV4_DNS="1.1.1.1 1.0.0.1"
    IPV6_DNS="2606:4700:4700::1111 2606:4700:4700::1001"
    ;;
  2)
    PROVIDER="Google"
    IPV4_DNS="8.8.8.8 8.8.4.4"
    IPV6_DNS="2001:4860:4860::8888 2001:4860:4860::8844"
    ;;
  *)
    err "seleção inválida"
    _finish 1
    ;;
esac

ok "provedor: $PROVIDER"

# --- 4. Aplicar ---------------------------------------------------------------
info "Aplicando DNS em '$CONN_NAME'..."
sudo nmcli connection modify "$CONN_NAME" \
  ipv4.dns "$IPV4_DNS" \
  ipv4.ignore-auto-dns yes \
  ipv6.dns "$IPV6_DNS" \
  ipv6.ignore-auto-dns yes
ok "DNS configurado"

# --- 5. Reiniciar conexão -----------------------------------------------------
info "Reiniciando conexão..."
sudo nmcli connection down "$CONN_NAME" &>/dev/null || true
sudo nmcli connection up "$CONN_NAME"
ok "conexão reiniciada"

# --- 6. Mostrar resultado -----------------------------------------------------
echo ""
nmcli -f ipv4.dns,ipv4.ignore-auto-dns,ipv6.dns,ipv6.ignore-auto-dns connection show "$CONN_NAME"
