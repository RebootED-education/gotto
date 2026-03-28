#!/usr/bin/env bash

set -euo pipefail

REPO_URL=${REPO_URL:-https://github.com/RebootED-education/gotto.git}
TARGET=${TARGET:-nicenano}
PROFILE_FILE="${HOME}/.profile"

log() {
	printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"
}

require_binary() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log "Error: '$1' is not installed or not on PATH."
		exit 1
	fi
}

setup_repo() {
	if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
		if [[ -f "${git_root}/go.mod" ]] && grep -q "github.com/HattoriHanzo031/gotto" "${git_root}/go.mod"; then
			repo_root="${git_root}"
			cleanup=0
			return
		fi
	fi
	tmp_dir=$(mktemp -d)
	cleanup=1
	log "Cloning GOtto repository"
	git clone --depth 1 "${REPO_URL}" "${tmp_dir}/gotto" >/dev/null
	repo_root="${tmp_dir}/gotto"
}

cleanup_repo() {
	if [[ "${cleanup}" == "1" && -n "${tmp_dir:-}" ]]; then
		rm -rf "${tmp_dir}"
	fi
}

flash_demo() {
	pushd "${repo_root}" >/dev/null
	log "Flashing demo to ${TARGET}"
	port_args=()
	if [[ -n "${PORT:-}" ]]; then
		port_args=(-port "${PORT}")
	fi
	tinygo flash -target "${TARGET}" "${port_args[@]}" ./examples/demo
	log "Demo flashed successfully"
	popd >/dev/null
}

main() {
	require_binary git
	require_binary tinygo
	setup_repo
	trap cleanup_repo EXIT
	flash_demo
}

main "$@"
