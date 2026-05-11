#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# SCRIPTS DE SETUP — adicione novos scripts aqui em ordem de execução
# =============================================================================
SETUP_SCRIPTS=(
  setup-locale.sh
  setup-networkmanager.sh
  setup-ioschedulers.sh
)
# =============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

for script in "${SETUP_SCRIPTS[@]}"; do
  path="$SCRIPT_DIR/$script"
  echo -e "${CYAN}==============================${RESET}"
  echo -e "${CYAN} $script${RESET}"
  echo -e "${CYAN}==============================${RESET}"

  if [[ ! -f "$path" ]]; then
    echo -e "${RED}ERRO: $path não encontrado — pulando${RESET}"
    continue
  fi

  # shellcheck source=/dev/null
  source "$path"

  echo -e "${GREEN} $script concluído${RESET}"
  echo ""
done

echo -e "${GREEN}=============================="
echo -e " Setup completo!"
echo -e "==============================${RESET}"
