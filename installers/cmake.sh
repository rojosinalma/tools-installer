#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="cmake"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${CMAKE_VERSION}"

log "Installing CMake ${CMAKE_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "CMake ${CMAKE_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${CMAKE_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${CMAKE_URL}" "${ARCHIVE}" "CMake ${CMAKE_VERSION}"
fi

log "Extracting CMake"
extract_archive "${ARCHIVE}" "${INSTALL_PREFIX}"
create_versioned_install "${TOOL_NAME}" "${CMAKE_VERSION}"

if "${INSTALL_PREFIX}/bin/cmake" --version &> /dev/null; then
    log "✓ CMake ${CMAKE_VERSION} installed successfully"
else
    error "CMake installation verification failed"
    exit 1
fi
