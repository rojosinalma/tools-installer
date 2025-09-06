#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="readline"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${READLINE_VERSION}"

log "Installing readline ${READLINE_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "readline ${READLINE_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${READLINE_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/readline-${READLINE_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${READLINE_URL}" "${ARCHIVE}" "readline ${READLINE_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/readline-${READLINE_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting readline"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring readline" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --with-curses

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${READLINE_VERSION}"

log "✓ readline ${READLINE_VERSION} installed successfully"
clean_build "${BUILD_DIR}"