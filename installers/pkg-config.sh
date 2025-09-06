#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="pkg-config"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${PKG_CONFIG_VERSION}"

log "Installing pkg-config ${PKG_CONFIG_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "pkg-config ${PKG_CONFIG_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${PKG_CONFIG_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/pkg-config-${PKG_CONFIG_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${PKG_CONFIG_URL}" "${ARCHIVE}" "pkg-config ${PKG_CONFIG_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/pkg-config-${PKG_CONFIG_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting pkg-config"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring pkg-config" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --with-internal-glib

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${PKG_CONFIG_VERSION}"

if "${INSTALL_PREFIX}/bin/pkg-config" --version &> /dev/null; then
    log "✓ pkg-config ${PKG_CONFIG_VERSION} installed successfully"
else
    error "pkg-config installation verification failed"
    exit 1
fi

clean_build "${BUILD_DIR}"