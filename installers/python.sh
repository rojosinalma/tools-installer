#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="python"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${PYTHON_VERSION}"

log "Installing Python ${PYTHON_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "Python ${PYTHON_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${PYTHON_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/python-${PYTHON_VERSION}-hab00c5b_0_cpython.conda"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${PYTHON_URL}" "${ARCHIVE}" "Python ${PYTHON_VERSION}" "${TOOL_NAME}"
fi

log "Extracting Python"
extract_archive "${ARCHIVE}" "${INSTALL_PREFIX}" "${TOOL_NAME}"

# Create python3 symlink if it doesn't exist
if [[ ! -e "${INSTALL_PREFIX}/bin/python3" ]] && [[ -e "${INSTALL_PREFIX}/bin/python" ]]; then
    ln -s python "${INSTALL_PREFIX}/bin/python3"
fi

create_versioned_install "${TOOL_NAME}" "${PYTHON_VERSION}"

if "${INSTALL_PREFIX}/bin/python3" --version &> /dev/null; then
    log "✓ Python ${PYTHON_VERSION} installed successfully"
else
    error "Python installation verification failed"
    exit 1
fi