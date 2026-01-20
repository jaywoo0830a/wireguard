#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-./compose.yaml}"
WG_PORT="${WG_PORT:-51820}"
NFT_CHAIN="inet host_fw input"
RULE_MATCH="managed-by=wireguard;udp:${WG_PORT}"

need_root() {
  [[ $EUID -eq 0 ]] || { echo "ERROR: run as root (sudo)"; exit 1; }
}

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

remove_fw_rules() {
  echo "[down] Removing WireGuard firewall rules"

  nft -a list chain ${NFT_CHAIN} | \
    grep "${RULE_MATCH}" | \
    awk '{print $NF}' | \
    while read -r handle; do
      nft delete rule ${NFT_CHAIN} handle "${handle}"
    done
}

main() {
  need_root
  echo "[down] Stopping WireGuard"
  compose down
  remove_fw_rules || true
  echo "[down] OK"
}

main "$@"
