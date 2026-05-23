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

remove_fw_rules() {
  echo "[down] Removing WireGuard firewall rules"

  local handles
  handles=$(nft -a list chain ${NFT_CHAIN} 2>/dev/null | grep "${RULE_MATCH}" | awk '{print $NF}')

  if [[ -z "${handles}" ]]; then
    echo "[down] No firewall rules to remove"
    return
  fi

  while read -r handle; do
    [[ -n "${handle}" ]] && nft delete rule ${NFT_CHAIN} handle "${handle}"
  done <<< "${handles}"
  echo "[down] Firewall rules removed"
}

main() {
  need_root
  have_cmd docker || { echo "ERROR: docker not found"; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose plugin missing"; exit 1; }

  echo "[down] Stopping WireGuard"
  compose down
  remove_fw_rules || true
  echo "[down] OK"
}

main "$@"
