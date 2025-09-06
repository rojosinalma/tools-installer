#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${SCRIPT_DIR}/logs/install.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "${SCRIPT_DIR}/logs/install.log"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $1" >> "${SCRIPT_DIR}/logs/install.log"
}

debug() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $1" >> "${SCRIPT_DIR}/logs/debug.log"
}

check_disk_space() {
    local required=$1
    local available=$(df "${HOME}" | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ ${available} -lt ${required} ]]; then
        error "Insufficient disk space. Required: ${required}GB, Available: ${available}GB"
        return 1
    fi
    log "Disk space check passed (${available}GB available)"
    return 0
}

create_versioned_install() {
    local tool="$1"
    local version="$2"
    local install_dir="${TOOLS_PREFIX}/${tool}-${version}"
    if [[ -d "${install_dir}" ]]; then
        ln -sfn "${install_dir}" "${TOOLS_PREFIX}/${tool}"
        log "Created symlink: ${TOOLS_PREFIX}/${tool} -> ${install_dir}"
    fi
}

uninstall_tool() {
    local tool="$1"
    if [[ -L "${TOOLS_PREFIX}/${tool}" ]]; then
        local install_dir=$(readlink "${TOOLS_PREFIX}/${tool}")
        rm -f "${TOOLS_PREFIX}/${tool}"
        read -p "Remove installation directory ${install_dir}? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${install_dir}"
            log "Removed ${install_dir}"
        fi
        log "Uninstalled ${tool}"
    else
        warn "${tool} is not installed"
    fi
}

get_cpu_count() {
    echo $(nproc)
}

export_tool_env() {
    local tool_dir="$1"
    export PATH="${tool_dir}/bin:${PATH}"
    export LD_LIBRARY_PATH="${tool_dir}/lib:${tool_dir}/lib64:${LD_LIBRARY_PATH}"
    export PKG_CONFIG_PATH="${tool_dir}/lib/pkgconfig:${tool_dir}/lib64/pkgconfig:${PKG_CONFIG_PATH}"
    export CPATH="${tool_dir}/include:${CPATH}"
    export LIBRARY_PATH="${tool_dir}/lib:${tool_dir}/lib64:${LIBRARY_PATH}"
}
