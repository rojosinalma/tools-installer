#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="bzip2"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${BZIP2_VERSION}"

log "Installing bzip2 ${BZIP2_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "bzip2 ${BZIP2_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${BZIP2_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/bzip2-${BZIP2_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${BZIP2_URL}" "${ARCHIVE}" "bzip2 ${BZIP2_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/bzip2-${BZIP2_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting bzip2"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Building bzip2" "build"
# bzip2 uses custom makefile, not configure
run_command "${TOOL_NAME}" "build" "make -f Makefile-libbz2_so"
run_make "" "${TOOL_NAME}"

tool_log "${TOOL_NAME}" "Installing bzip2" "build"
run_command "${TOOL_NAME}" "build" "make install PREFIX='${INSTALL_PREFIX}'"

# Install shared library manually
cp -P libbz2.so* "${INSTALL_PREFIX}/lib/"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${BZIP2_VERSION}"

log "✓ bzip2 ${BZIP2_VERSION} installed successfully"
clean_build "${BUILD_DIR}"