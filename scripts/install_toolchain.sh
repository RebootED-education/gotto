#!/usr/bin/env bash

set -euo pipefail

GO_VERSION=${GO_VERSION:-1.22.4}
TINYGO_VERSION=${TINYGO_VERSION:-0.32.0}
PROFILE_FILE="${HOME}/.profile"

log() {
	printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"
}

append_path_line() {
	local line=$1
	if [[ -f "${PROFILE_FILE}" ]] && grep -qxF "${line}" "${PROFILE_FILE}"; then
		return
	fi
	log "Adding PATH snippet to ${PROFILE_FILE}"
	echo "${line}" >>"${PROFILE_FILE}"
}

install_packages() {
	if [[ ! -f /etc/os-release ]]; then
		echo "Cannot detect Linux distribution (missing /etc/os-release)." >&2
		exit 1
	fi
	. /etc/os-release
	local like="${ID_LIKE:-}" id="${ID:-}"
	case "${id} ${like}" in
		*debian*|*ubuntu*|*pop*)
			log "Installing dependencies via apt"
			sudo apt update
			sudo apt install -y build-essential git wget tar clang gcc-arm-none-eabi libnewlib-arm-none-eabi
			;;
		*fedora*)
			log "Installing dependencies via dnf"
			sudo dnf install -y @'Development Tools' git wget tar clang arm-none-eabi-gcc-cs arm-none-eabi-newlib
			;;
		*arch*|*manjaro*|*endeavouros*)
			log "Installing dependencies via pacman"
			sudo pacman -Sy --needed base-devel git wget tar clang arm-none-eabi-gcc arm-none-eabi-newlib
			;;
		*)
			echo "Unsupported distribution: ${id}. Please install dependencies manually." >&2
			exit 1
			;;
	esac
}

install_go() {
	local archive="/tmp/go${GO_VERSION}.linux-amd64.tar.gz"
	log "Downloading Go ${GO_VERSION}"
	wget -qO "${archive}" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
	sudo rm -rf /usr/local/go
	log "Installing Go to /usr/local/go"
	sudo tar -C /usr/local -xzf "${archive}"
	append_path_line 'export PATH=/usr/local/go/bin:$PATH'
	source "${PROFILE_FILE}" >/dev/null 2>&1 || true
	log "$(/usr/local/go/bin/go version) installed"
}

install_tinygo() {
	local archive="/tmp/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"
	log "Downloading TinyGo ${TINYGO_VERSION}"
	wget -qO "${archive}" "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"
	sudo rm -rf /usr/local/tinygo
	log "Installing TinyGo to /usr/local/tinygo"
	sudo tar -C /usr/local -xzf "${archive}"
	append_path_line 'export PATH=/usr/local/tinygo/bin:$PATH'
	source "${PROFILE_FILE}" >/dev/null 2>&1 || true
	log "$(/usr/local/tinygo/bin/tinygo version) installed"
	if [[ -d /usr/local/tinygo/udev ]]; then
		log "Applying TinyGo udev rules"
		sudo cp /usr/local/tinygo/udev/99-tinygo.rules /etc/udev/rules.d/
		sudo udevadm control --reload-rules
		sudo udevadm trigger
	fi
}

main() {
	log "Installing GOtto toolchain (Go ${GO_VERSION}, TinyGo ${TINYGO_VERSION})"
	install_packages
	install_go
	install_tinygo
	log "Installation complete. Restart your shell session or run 'source ${PROFILE_FILE}' to update PATH."
}

main "$@"
