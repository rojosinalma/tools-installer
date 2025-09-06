#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="xz"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${XZ_VERSION}"

log "Installing xz ${XZ_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "xz ${XZ_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${XZ_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/xz-${XZ_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${XZ_URL}" "${ARCHIVE}" "xz ${XZ_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/xz-${XZ_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting xz"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring xz" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --disable-doc

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${XZ_VERSION}"

log "✓ xz ${XZ_VERSION} installed successfully"
clean_build "${BUILD_DIR}"