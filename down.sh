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

# host_fw 테이블/체인이 없으면 자동 생성 (규칙 제거 전 참조 안전)
ensure_fw_chain() {
  local table="inet host_fw"
  local chain="inet host_fw input"
  if ! nft list table ${table} >/dev/null 2>&1; then
    echo "[down] Creating nftables table: ${table}"
    nft add table ${table}
  fi
  if ! nft list chain ${chain} >/dev/null 2>&1; then
    echo "[down] Creating nftables chain: ${chain}"
    nft "add chain ${chain} { type filter hook input priority 0; policy accept; }"
  fi
}

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

  ensure_fw_chain

  echo "[down] Stopping WireGuard"
  compose down
  remove_fw_rules || true
  echo "[down] OK"
}

main "$@"
