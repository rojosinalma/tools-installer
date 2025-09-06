#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="ncurses"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${NCURSES_VERSION}"

log "Installing ncurses ${NCURSES_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "ncurses ${NCURSES_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${NCURSES_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/ncurses-${NCURSES_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${NCURSES_URL}" "${ARCHIVE}" "ncurses ${NCURSES_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/ncurses-${NCURSES_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting ncurses"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring ncurses" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --with-shared \
    --without-debug \
    --enable-widec

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${NCURSES_VERSION}"

log "✓ ncurses ${NCURSES_VERSION} installed successfully"
clean_build "${BUILD_DIR}"