#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-./compose.yaml}"

need_root() {
  [[ $EUID -eq 0 ]] || { echo "ERROR: run as root (sudo)"; exit 1; }
}

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

main() {
  need_root
  echo "[up] Starting WireGuard"
  compose up -d
  echo "[up] OK"
}

main "$@"
