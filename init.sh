#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-./compose.yaml}"
ENV_FILE="${ENV_FILE:-./.env}"
[[ -f "$ENV_FILE" ]] && { set -a; . "$ENV_FILE"; set +a; }
WG_PORT="${WG_SERVERPORT:-51820}"
NFT_CHAIN="inet host_fw input"
RULE_MATCH="managed-by=wireguard;udp:${WG_PORT}"

need_root() {
  [[ $EUID -eq 0 ]] || { echo "ERROR: run as root (sudo)"; exit 1; }
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }
compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

add_fw_rule() {
  echo "[init] Ensuring UDP ${WG_PORT} allowed in host_fw"

  if nft list chain ${NFT_CHAIN} 2>/dev/null | grep -q "${RULE_MATCH}"; then
    echo "[init] Firewall rule already exists (matched: ${RULE_MATCH})"
    return
  fi

  nft add rule ${NFT_CHAIN} \
    udp dport ${WG_PORT} ct state new accept \
    comment "\"${RULE_MATCH}\""
  echo "[init] Firewall rule added"
}

main() {
  need_root
  have_cmd docker || { echo "ERROR: docker not found"; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose plugin missing"; exit 1; }
  have_cmd nft || { echo "ERROR: nft not installed"; exit 1; }

  echo "[init] Loading WireGuard kernel module"
  if ! modprobe wireguard 2>/dev/null; then
    # modprobe 실패: 이미 로드되었거나 호스트에 모듈이 없는 경우
    if ! lsmod | grep -q wireguard; then
      echo "[init] WARNING: wireguard kernel module not loaded and modprobe failed."
      echo "[init] The container may still work if the host kernel has wireguard built-in."
    else
      echo "[init] wireguard module already loaded (modprobe reported error but lsmod confirms it)"
    fi
  else
    echo "[init] wireguard module loaded successfully"
  fi

  add_fw_rule

  echo "[init] Starting WireGuard container"
  compose up -d

  echo
  echo "OK."
  echo "UDP ${WG_PORT} open."
  echo "Client configs: ./config/"
}

main "$@"
