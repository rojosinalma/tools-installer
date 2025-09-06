#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="gcc"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${GCC_VERSION}"

log "Installing GCC ${GCC_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "GCC ${GCC_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${GCC_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/gcc-${GCC_VERSION}.tar.xz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${GCC_URL}" "${ARCHIVE}" "GCC ${GCC_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/gcc-${GCC_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting GCC"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"

# Download prerequisites
tool_log "${TOOL_NAME}" "Downloading GCC prerequisites" "build"
run_command "${TOOL_NAME}" "build" "./contrib/download_prerequisites"

# Create separate build directory
BUILD_OBJ_DIR="${BUILD_DIR}-obj"
mkdir -p "${BUILD_OBJ_DIR}"
cd "${BUILD_OBJ_DIR}"

set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring GCC" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-bootstrap \
    --with-system-zlib

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${GCC_VERSION}"

if "${INSTALL_PREFIX}/bin/gcc" --version &> /dev/null; then
    log "✓ GCC ${GCC_VERSION} installed successfully"
else
    error "GCC installation verification failed"
    exit 1
fi

clean_build "${BUILD_DIR}"
clean_build "${BUILD_OBJ_DIR}"