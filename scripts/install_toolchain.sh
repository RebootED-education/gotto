#!/usr/bin/env bash

set -euo pipefail

GO_VERSION=${GO_VERSION:-1.22.4}
TINYGO_VERSION=${TINYGO_VERSION:-0.40.1}
PROFILE_FILE="${HOME}/.profile"
OS_ID=""
OS_LIKE=""

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

detect_os() {
	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		OS_ID=${ID:-unknown}
		OS_LIKE=${ID_LIKE:-}
	else
		OS_ID="unknown"
		OS_LIKE=""
	fi
}

install_packages() {
	local os_key="${OS_ID} ${OS_LIKE}"
	case "${os_key}" in
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
		unknown*)
			echo "Unsupported distribution: unable to detect OS. Please install dependencies manually." >&2
			exit 1
			;;
		*)
			echo "Unsupported distribution: ${OS_ID}. Please install dependencies manually." >&2
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

install_tinygo_deb() {
	local deb="/tmp/tinygo_${TINYGO_VERSION}_amd64.deb"
	local url="https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo_${TINYGO_VERSION}_amd64.deb"
	log "Downloading TinyGo ${TINYGO_VERSION} .deb"
	wget -qO "${deb}" "${url}"
	log "Installing TinyGo via dpkg"
	if ! sudo dpkg -i "${deb}" >/dev/null; then
		log "Resolving TinyGo package dependencies"
		sudo apt install -f -y
		sudo dpkg -i "${deb}" >/dev/null
	fi
	rm -f "${deb}"
	log "$(tinygo version) installed"
}

install_tinygo_tar() {
	local archive="/tmp/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"
	log "Downloading TinyGo ${TINYGO_VERSION}"
	wget -qO "${archive}" "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"
	sudo rm -rf /usr/local/tinygo
	log "Installing TinyGo to /usr/local/tinygo"
	sudo tar -C /usr/local -xzf "${archive}"
	append_path_line 'export PATH=/usr/local/tinygo/bin:$PATH'
	source "${PROFILE_FILE}" >/dev/null 2>&1 || true
	local tinygo_bin="/usr/local/tinygo/bin/tinygo"
	if [[ -x "${tinygo_bin}" ]]; then
		log "$("${tinygo_bin}" version) installed"
	else
		log "TinyGo extracted to /usr/local/tinygo"
	fi
	if [[ -d /usr/local/tinygo/udev ]]; then
		log "Applying TinyGo udev rules"
		sudo cp /usr/local/tinygo/udev/99-tinygo.rules /etc/udev/rules.d/
		sudo udevadm control --reload-rules
		sudo udevadm trigger
	fi
}

install_tinygo() {
	local os_key="${OS_ID} ${OS_LIKE}"
	case "${os_key}" in
		*debian*|*ubuntu*|*pop*)
			install_tinygo_deb
			;;
		*)
			install_tinygo_tar
			;;
	esac
}

main() {
	detect_os
	log "Installing GOtto toolchain (Go ${GO_VERSION}, TinyGo ${TINYGO_VERSION})"
	install_packages
	install_go
	install_tinygo
	log "Installation complete. Restart your shell session or run 'source ${PROFILE_FILE}' to update PATH."
}

main "$@"
