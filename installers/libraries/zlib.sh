#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="zlib"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${ZLIB_VERSION}"

log "Installing zlib ${ZLIB_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "zlib ${ZLIB_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${ZLIB_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/zlib-${ZLIB_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${ZLIB_URL}" "${ARCHIVE}" "zlib ${ZLIB_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/zlib-${ZLIB_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting zlib"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring zlib" "build"
run_command "${TOOL_NAME}" "build" "./configure --prefix='${INSTALL_PREFIX}'"

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${ZLIB_VERSION}"

log "✓ zlib ${ZLIB_VERSION} installed successfully"
clean_build "${BUILD_DIR}"