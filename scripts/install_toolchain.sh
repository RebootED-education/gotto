#!/usr/bin/env bash

set -euo pipefail

GO_VERSION=${GO_VERSION:-1.22.4}
TINYGO_VERSION=${TINYGO_VERSION:-0.40.1}
PROFILE_FILE="${HOME}/.profile"
SHELL_CONFIGS=("${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.bash_profile" "${HOME}/.zprofile" "${HOME}/.zshrc")
GO_COMPAT_MIN=${GO_COMPAT_MIN:-1.19}
GO_COMPAT_MAX=${GO_COMPAT_MAX:-1.22}
ALLOW_UNSUPPORTED_GO=${ALLOW_UNSUPPORTED_GO:-0}
GOTOOLCHAIN_VALUE="go${GO_VERSION}"
export GOTOOLCHAIN="${GOTOOLCHAIN_VALUE}"
OS_ID=""
OS_LIKE=""

log() {
	printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"
}

append_path_line() {
	local line=$1
	touch "${PROFILE_FILE}"
	for cfg in "${SHELL_CONFIGS[@]}"; do
		[[ -f "${cfg}" ]] || continue
		if grep -qxF "${line}" "${cfg}"; then
			continue
		fi
		log "Adding PATH snippet to ${cfg}"
		echo "${line}" >>"${cfg}"
	done
}

version_minor_code() {
	local version=$1
	local major minor
	IFS='.' read -r major minor _ <<<"${version}"
	if [[ -z "${major}" || -z "${minor}" ]]; then
		echo 0
		return
	fi
	printf "%d%02d" "${major}" "${minor}"
}

ensure_go_version_supported() {
	if [[ "${ALLOW_UNSUPPORTED_GO}" == "1" ]]; then
		return
	fi
	local go_code min_code max_code
	go_code=$(version_minor_code "${GO_VERSION}")
	min_code=$(version_minor_code "${GO_COMPAT_MIN}")
	max_code=$(version_minor_code "${GO_COMPAT_MAX}")
	if (( go_code < min_code || go_code > max_code )); then
		cat >&2 <<-EOF
Go ${GO_VERSION} is outside the supported range (${GO_COMPAT_MIN} - ${GO_COMPAT_MAX}) required by TinyGo ${TINYGO_VERSION}.
Set GO_VERSION to a compatible release or export ALLOW_UNSUPPORTED_GO=1 to bypass this guard.
EOF
		exit 1
	fi
}

create_go_symlinks() {
	local go_bin="/usr/local/go/bin"
	if [[ ! -d "${go_bin}" ]]; then
		return
	fi
	log "Linking Go binaries into /usr/local/bin"
	for tool in go gofmt; do
		if [[ -x "${go_bin}/${tool}" ]]; then
			sudo ln -sf "${go_bin}/${tool}" "/usr/local/bin/${tool}"
		fi
	done
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
	ensure_go_version_supported
	local archive="/tmp/go${GO_VERSION}.linux-amd64.tar.gz"
	log "Downloading Go ${GO_VERSION}"
	wget -qO "${archive}" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
	sudo rm -rf /usr/local/go
	log "Installing Go to /usr/local/go"
	sudo tar -C /usr/local -xzf "${archive}"
	append_path_line 'export PATH=/usr/local/go/bin:$PATH'
	append_path_line "export GOTOOLCHAIN=${GOTOOLCHAIN_VALUE}"
	export GOTOOLCHAIN="${GOTOOLCHAIN_VALUE}"
	create_go_symlinks
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
	log "Installation complete. Restart your shell session or source your shell rc file (~/.profile, ~/.bashrc, ~/.zshrc) to refresh PATH."
}

main "$@"
