#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="openssl"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${OPENSSL_VERSION}"

log "Installing OpenSSL ${OPENSSL_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "OpenSSL ${OPENSSL_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${OPENSSL_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/openssl-${OPENSSL_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${OPENSSL_URL}" "${ARCHIVE}" "OpenSSL ${OPENSSL_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/openssl-${OPENSSL_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting OpenSSL"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring OpenSSL" "build"
run_command "${TOOL_NAME}" "build" "./config --prefix='${INSTALL_PREFIX}' --openssldir='${INSTALL_PREFIX}/ssl' shared zlib"

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${OPENSSL_VERSION}"

if "${INSTALL_PREFIX}/bin/openssl" version &> /dev/null; then
    log "✓ OpenSSL ${OPENSSL_VERSION} installed successfully"
else
    error "OpenSSL installation verification failed"
    exit 1
fi

clean_build "${BUILD_DIR}"