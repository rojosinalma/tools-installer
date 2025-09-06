#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="ccache"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${CCACHE_VERSION}"

log "Installing ccache ${CCACHE_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "ccache ${CCACHE_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${CCACHE_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/ccache-${CCACHE_VERSION}.tar.xz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${CCACHE_URL}" "${ARCHIVE}" "ccache ${CCACHE_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/ccache-${CCACHE_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting ccache"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

BUILD_OBJ_DIR="${BUILD_DIR}-obj"
mkdir -p "${BUILD_OBJ_DIR}"

set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring ccache with CMake" "build"
cmake_build "${BUILD_DIR}" "${BUILD_OBJ_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    -DENABLE_TESTING=OFF

cd "${BUILD_OBJ_DIR}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${CCACHE_VERSION}"

if "${INSTALL_PREFIX}/bin/ccache" --version &> /dev/null; then
    log "✓ ccache ${CCACHE_VERSION} installed successfully"
else
    error "ccache installation verification failed"
    exit 1
fi

clean_build "${BUILD_DIR}"
clean_build "${BUILD_OBJ_DIR}"