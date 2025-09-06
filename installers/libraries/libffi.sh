#!/bin/bash
set -e
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/config/versions.conf"

TOOL_NAME="libffi"
INSTALL_PREFIX="${TOOLS_PREFIX}/${TOOL_NAME}-${LIBFFI_VERSION}"

log "Installing libffi ${LIBFFI_VERSION}"

if [[ -d "${INSTALL_PREFIX}" ]]; then
    warn "libffi ${LIBFFI_VERSION} is already installed"
    create_versioned_install "${TOOL_NAME}" "${LIBFFI_VERSION}"
    exit 0
fi

ARCHIVE="${SCRIPT_DIR}/downloads/libffi-${LIBFFI_VERSION}.tar.gz"
if [[ ! -f "${ARCHIVE}" ]]; then
    download_file "${LIBFFI_URL}" "${ARCHIVE}" "libffi ${LIBFFI_VERSION}" "${TOOL_NAME}"
fi

BUILD_DIR="${SCRIPT_DIR}/build/libffi-${LIBFFI_VERSION}"
clean_build "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

log "Extracting libffi"
extract_archive "${ARCHIVE}" "${BUILD_DIR}" "${TOOL_NAME}"

cd "${BUILD_DIR}"
set_optimization_flags

tool_log "${TOOL_NAME}" "Configuring libffi" "build"
configure_build "${BUILD_DIR}" "${INSTALL_PREFIX}" "${TOOL_NAME}" \
    --disable-docs

run_make "" "${TOOL_NAME}"
install_make "${TOOL_NAME}"

unset_optimization_flags
create_versioned_install "${TOOL_NAME}" "${LIBFFI_VERSION}"

log "✓ libffi ${LIBFFI_VERSION} installed successfully"
clean_build "${BUILD_DIR}"