#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="ninja"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${NINJA_VERSION}"

log "Installing Ninja ${NINJA_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "Ninja ${NINJA_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${NINJA_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/ninja-linux.zip"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${NINJA_URL}" "${ARCHIVE}" "Ninja ${NINJA_VERSION}" "${TOOL_NAME}"
fi

mkdir -p "${INSTALL_PREFIX}/bin"

log "Extracting Ninja"
run_command "${TOOL_NAME}" "extract" "unzip -q '${ARCHIVE}' -d '${INSTALL_PREFIX}/bin'"

# Make ninja executable
chmod +x "${INSTALL_PREFIX}/bin/ninja"

create_versioned_install "${TOOL_NAME}" "${NINJA_VERSION}"

if "${INSTALL_PREFIX}/bin/ninja" --version &> /dev/null; then
    log "✓ Ninja ${NINJA_VERSION} installed successfully"
else
    error "Ninja installation verification failed"
    exit 1
fi