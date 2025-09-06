#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="sqlite"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${SQLITE_VERSION}"

log "Installing sqlite ${SQLITE_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "sqlite ${SQLITE_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${SQLITE_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/sqlite-autoconf-${SQLITE_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${SQLITE_URL}" "${ARCHIVE}" "sqlite ${SQLITE_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/sqlite-${SQLITE_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting sqlite"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring sqlite" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --enable-readline \
    --enable-threadsafe

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${SQLITE_VERSION}"

if "${INSTALL_PREFIX}/bin/sqlite3" --version &> /dev/null; then
    log "✓ sqlite ${SQLITE_VERSION} installed successfully"
else
    error "sqlite installation verification failed"
    exit 1
fi

clean_build "${BUILD_DIR}"