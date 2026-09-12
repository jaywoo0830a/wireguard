#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-./config}"
SCRIPT_NAME="$(basename "$0")"

# ── helpers ──────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: ./${SCRIPT_NAME} <command> [args]

Commands:
  list                  List all peers and their config files
  show   <peer_number>  Print .conf file content for a peer
  qr     <peer_number>  Print QR code image path for a peer
  export <peer_number> [output_dir]  Copy .conf file to output_dir (default: ./out)

Examples:
  ./${SCRIPT_NAME} list
  ./${SCRIPT_NAME} show 1
  ./${SCRIPT_NAME} export 1 ~/Downloads
EOF
  exit 0
}

# ── peer helpers ─────────────────────────────────────────

resolve_peer_dir() {
  local num="$1"
  local dirs
  dirs=$(find "${CONFIG_DIR}" -maxdepth 1 -type d -name "peer${num}" 2>/dev/null || true)
  [[ -z "${dirs}" ]] && die "peer '${num}' not found under ${CONFIG_DIR}/"
  echo "${dirs}" | head -1
}

find_conf() {
  local peer_dir="$1"
  local conf
  conf=$(find "${peer_dir}" -maxdepth 1 -name "*.conf" 2>/dev/null | head -1)
  [[ -z "${conf}" ]] && die "no .conf file found in ${peer_dir}"
  echo "${conf}"
}

find_png() {
  local peer_dir="$1"
  find "${peer_dir}" -maxdepth 1 -name "*.png" 2>/dev/null | head -1
}

# ── commands ─────────────────────────────────────────────

cmd_list() {
  echo "Peers under ${CONFIG_DIR}/:"
  echo "------------------------------"

  local found=0
  for peer_dir in "${CONFIG_DIR}"/peer*/; do
    [[ -d "${peer_dir}" ]] || continue
    found=1
    local peer_name
    peer_name=$(basename "${peer_dir}")
    local conf_file png_file
    conf_file=$(find "${peer_dir}" -maxdepth 1 -name "*.conf" 2>/dev/null | head -1 || echo "(no .conf)")
    png_file=$(find "${peer_dir}" -maxdepth 1 -name "*.png" 2>/dev/null | head -1 || echo "(no .png)")

    echo "  ${peer_name}:"
    echo "    conf  → ${conf_file}"
    echo "    qr    → ${png_file}"
  done

  if [[ ${found} -eq 0 ]]; then
    echo "  (no peers found)"
  fi
}

cmd_show() {
  local num="${1:?Usage: ./${SCRIPT_NAME} show <peer_number>}"
  local peer_dir conf_file
  peer_dir=$(resolve_peer_dir "${num}")
  conf_file=$(find_conf "${peer_dir}")

  echo "── ${conf_file} ──"
  cat "${conf_file}"
}

cmd_qr() {
  local num="${1:?Usage: ./${SCRIPT_NAME} qr <peer_number>}"
  local peer_dir png_file
  peer_dir=$(resolve_peer_dir "${num}")
  png_file=$(find_png "${peer_dir}")

  if [[ -z "${png_file}" ]]; then
    die "no QR image found for peer ${num}"
  fi
  echo "${png_file}"
}

cmd_export() {
  local num="${1:?Usage: ./${SCRIPT_NAME} export <peer_number> [output_dir]}"
  local out_dir="${2:-./out}"
  local peer_dir conf_file
  peer_dir=$(resolve_peer_dir "${num}")
  conf_file=$(find_conf "${peer_dir}")

  # 출력 디렉터리 유효성 검사
  if [[ ! -d "${out_dir}" ]]; then
    mkdir -p "${out_dir}" || die "cannot create output directory: ${out_dir}"
  fi
  if [[ ! -w "${out_dir}" ]]; then
    die "output directory is not writable: ${out_dir}"
  fi
  local dest="${out_dir}/$(basename "${conf_file}")"
  cp "${conf_file}" "${dest}"
  echo "Exported: ${dest}"

  # QR도 있으면 같이 복사
  local png_file
  png_file=$(find_png "${peer_dir}")
  if [[ -n "${png_file}" ]]; then
    cp "${png_file}" "${out_dir}/"
    echo "Exported: ${out_dir}/$(basename "${png_file}")"
  fi
}

# ── main ─────────────────────────────────────────────────

[[ $# -eq 0 ]] && usage
case "${1:-}" in
  list)   cmd_list;;
  show)   cmd_show "${2:-}";;
  qr)     cmd_qr "${2:-}";;
  export) cmd_export "${2:-}" "${3:-}";;
  -h|--help|help) usage;;
  *)      die "unknown command '${1}'. Run './${SCRIPT_NAME} help'.";;
esac
