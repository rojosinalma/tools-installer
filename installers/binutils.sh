#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="binutils"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${BINUTILS_VERSION}"

log "Installing Binutils ${BINUTILS_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "Binutils ${BINUTILS_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${BINUTILS_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/binutils-${BINUTILS_VERSION}.tar.xz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${BINUTILS_URL}" "${ARCHIVE}" "Binutils ${BINUTILS_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/binutils-${BINUTILS_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting Binutils"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring Binutils" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --disable-nls \
    --disable-gprofng \
    --enable-gold \
    --enable-ld=default \
    --enable-plugins \
    --with-system-zlib

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${BINUTILS_VERSION}"

if "${INSTALL_PREFIX}/bin/ld" --version &> /dev/null; then
    log "✓ Binutils ${BINUTILS_VERSION} installed successfully"
else
    error "Binutils installation verification failed"
    exit 1
fi

clean_build "${BUILD_DIR}"