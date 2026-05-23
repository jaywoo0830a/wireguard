#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-./compose.yaml}"

need_root() {
  [[ $EUID -eq 0 ]] || { echo "ERROR: run as root (sudo)"; exit 1; }
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

main() {
  need_root
  have_cmd docker || { echo "ERROR: docker not found"; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose plugin missing"; exit 1; }

  echo "[up] Starting WireGuard"
  compose up -d
  echo "[up] OK"
}

main "$@"
