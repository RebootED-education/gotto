#!/usr/bin/env bash

set -euo pipefail

REPO_URL=${REPO_URL:-https://github.com/RebootED-education/gotto.git}
TARGET=${TARGET:-nicenano}
PROFILE_FILE="${HOME}/.profile"
INSTALLER_URL=${INSTALLER_URL:-https://raw.githubusercontent.com/RebootED-education/gotto/main/scripts/install_toolchain.sh}

repo_root=""
tmp_dir=""
cleanup=0

log() {
	printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"
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

ensure_tinygo() {
	if command -v tinygo >/dev/null 2>&1; then
		return
	fi

	log "TinyGo not found; installing GOtto toolchain (requires sudo)"
	local installer_path="${repo_root}/scripts/install_toolchain.sh"
	local installer_hint="bash ${repo_root}/scripts/install_toolchain.sh"
	local tmp_installer=""
	if [[ ! -f "${installer_path}" ]]; then
		tmp_installer=$(mktemp)
		curl -fsSL "${INSTALLER_URL}" -o "${tmp_installer}"
		installer_path="${tmp_installer}"
		installer_hint="curl -fsSL ${INSTALLER_URL} | bash"
	fi
	bash "${installer_path}"
	if [[ -n "${tmp_installer}" ]]; then
		rm -f "${tmp_installer}"
	fi

	export PATH="/usr/local/go/bin:/usr/local/tinygo/bin:${PATH}"
	if ! command -v tinygo >/dev/null 2>&1; then
		log "TinyGo installation failed or PATH not updated. Please run: ${installer_hint}"
		exit 1
	fi
}

main() {
	if ! command -v git >/dev/null 2>&1; then
		log "Error: 'git' is required. Please install git and re-run."
		exit 1
	fi
	setup_repo
	trap cleanup_repo EXIT
	ensure_tinygo
	flash_demo
}

main "$@"
