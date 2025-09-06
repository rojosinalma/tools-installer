#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_PREFIX="${HOME}/tools"
LOCAL_PREFIX="${TOOLS_PREFIX}"

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/build.sh"
source "${SCRIPT_DIR}/lib/test.sh"
source "${SCRIPT_DIR}/config/versions.conf"

mkdir -p "${SCRIPT_DIR}/downloads"
mkdir -p "${SCRIPT_DIR}/build"
mkdir -p "${SCRIPT_DIR}/logs"
mkdir -p "${TOOLS_PREFIX}"

COMMAND="${1:-help}"
TARGET="${2:-}"
VERBOSE=false
CUSTOM_VERSION=""

# Parse arguments
i=1
while [[ $i -le $# ]]; do
    case "${!i}" in
        --verbose)
            VERBOSE=true
            ;;
        --version)
            # Get next argument as version
            next_i=$((i+1))
            if [[ ${next_i} -le $# ]]; then
                CUSTOM_VERSION="${!next_i}"
                i=$((i+1))  # Skip next argument since we consumed it
            fi
            ;;
    esac
    i=$((i+1))
done

show_help() {
    cat << HELP
Core Build Kit Installer

Usage: ./installer.sh [COMMAND] [TARGET] [OPTIONS]

Commands:
    help              Show this help message
    list              List all available tools
    download TARGET   Download sources without building
    install TARGET    Install specified target
    uninstall TOOL    Remove specified tool
    status            Show installation status
    test TOOL         Test if tool is working

Targets:
    all              All tools
    phase1           Pre-compiled binaries only
    phase2           Build from source tools
    phase3           Essential libraries
    [tool-name]      Specific tool (e.g., cmake, gcc)

Options:
    --verbose        Show detailed command output
    --version VER    Override tool version (download only)

Examples:
    ./installer.sh download all
    ./installer.sh download cmake --version 3.25.0
    ./installer.sh install all
    ./installer.sh install cmake
    ./installer.sh install phase1 --verbose
    ./installer.sh status
    ./installer.sh test gcc
HELP
}

list_tools() {
    echo "=== Available Tools ==="
    echo ""
    echo "Phase 1 - Pre-compiled Binaries:"
    echo "  - cmake (${CMAKE_VERSION})"
    echo "  - ninja (${NINJA_VERSION})"
    echo "  - python (${PYTHON_VERSION})"
    echo ""
    echo "Phase 2 - Build from Source:"
    echo "  - gcc (${GCC_VERSION})"
    echo "  - binutils (${BINUTILS_VERSION})"
    echo "  - make (${MAKE_VERSION})"
    echo "  - openssl (${OPENSSL_VERSION})"
    echo "  - pkg-config (${PKGCONFIG_VERSION})"
    echo "  - ccache (${CCACHE_VERSION})"
    echo ""
    echo "Phase 3 - Essential Libraries:"
    echo "  - zlib (${ZLIB_VERSION})"
    echo "  - libffi (${LIBFFI_VERSION})"
    echo "  - readline (${READLINE_VERSION})"
    echo "  - ncurses (${NCURSES_VERSION})"
    echo "  - bzip2 (${BZIP2_VERSION})"
    echo "  - xz (${XZ_VERSION})"
    echo "  - sqlite (${SQLITE_VERSION})"
}

check_status() {
    echo "=== Installation Status ==="
    echo ""
    local tools=(cmake ninja python gcc make binutils openssl pkg-config ccache)
    for tool in "${tools[@]}"; do
        if [[ -L "${TOOLS_PREFIX}/${tool}" ]]; then
            local version=$(readlink "${TOOLS_PREFIX}/${tool}" | sed 's/.*-//')
            echo "✓ ${tool}: ${version}"
        elif command -v "${tool}" &> /dev/null; then
            echo "○ ${tool}: system version"
        else
            echo "✗ ${tool}: not installed"
        fi
    done
}

download_tool_source() {
    local tool="$1"
    local custom_version="${2:-}"
    
    # Set version variables, use custom version if provided
    local version_var="${tool^^}_VERSION"
    local url_var="${tool^^}_URL"
    local version="${custom_version:-${!version_var}}"
    local base_url="${!url_var}"
    
    # Handle special case for sqlite which has different version format
    if [[ "${tool}" == "sqlite" && -n "${custom_version}" ]]; then
        # Convert x.y.z to xxyyzz00 format for sqlite
        local major minor patch
        IFS='.' read -r major minor patch <<< "${custom_version}"
        version=$(printf "%02d%02d%02d00" "$major" "$minor" "$patch")
    fi
    
    # Replace version in URL if custom version provided
    if [[ -n "${custom_version}" ]]; then
        case "${tool}" in
            cmake)
                base_url="https://github.com/Kitware/CMake/releases/download/v${version}/cmake-${version}-linux-x86_64.tar.gz"
                ;;
            ninja)
                base_url="https://github.com/ninja-build/ninja/releases/download/v${version}/ninja-linux.zip"
                ;;
            python)
                base_url="https://conda.anaconda.org/conda-forge/linux-64/python-${version}-hab00c5b_0_cpython.conda"
                ;;
            gcc)
                base_url="https://ftp.gnu.org/gnu/gcc/gcc-${version}/gcc-${version}.tar.xz"
                ;;
            binutils)
                base_url="https://ftp.gnu.org/gnu/binutils/binutils-${version}.tar.xz"
                ;;
            make)
                base_url="https://ftp.gnu.org/gnu/make/make-${version}.tar.gz"
                ;;
            openssl)
                base_url="https://www.openssl.org/source/openssl-${version}.tar.gz"
                ;;
            pkg-config|pkgconfig)
                base_url="https://pkg-config.freedesktop.org/releases/pkg-config-${version}.tar.gz"
                ;;
            ccache)
                base_url="https://github.com/ccache/ccache/releases/download/v${version}/ccache-${version}.tar.xz"
                ;;
            zlib)
                base_url="https://zlib.net/zlib-${version}.tar.gz"
                ;;
            libffi)
                base_url="https://github.com/libffi/libffi/releases/download/v${version}/libffi-${version}.tar.gz"
                ;;
            readline)
                base_url="https://ftp.gnu.org/gnu/readline/readline-${version}.tar.gz"
                ;;
            ncurses)
                base_url="https://ftp.gnu.org/gnu/ncurses/ncurses-${version}.tar.gz"
                ;;
            bzip2)
                base_url="https://sourceware.org/pub/bzip2/bzip2-${version}.tar.gz"
                ;;
            xz)
                base_url="https://tukaani.org/xz/xz-${version}.tar.xz"
                ;;
            sqlite)
                base_url="https://www.sqlite.org/2023/sqlite-autoconf-${version}.tar.gz"
                ;;
        esac
    fi
    
    local filename=$(basename "${base_url}")
    local output="${SCRIPT_DIR}/downloads/${filename}"
    
    log "Downloading ${tool} version ${custom_version:-${!version_var}}"
    
    if [[ -f "${output}" ]]; then
        log "File already exists: ${filename}"
        return 0
    fi
    
    download_file "${base_url}" "${output}" "${tool} ${version}"
    
    if [[ $? -eq 0 ]]; then
        log "Successfully downloaded ${tool} to ${output}"
    else
        error "Failed to download ${tool}"
        return 1
    fi
}

download_only() {
    local target="$1"
    case "${target}" in
        all)
            if [[ -n "${CUSTOM_VERSION}" ]]; then
                warn "Custom version specified for 'all' - this will apply to every tool"
            fi
            download_only phase1
            download_only phase2 
            download_only phase3
            ;;
        phase1)
            log "Downloading Phase 1: Pre-compiled binaries"
            if [[ -n "${CUSTOM_VERSION}" ]]; then
                warn "Custom version ${CUSTOM_VERSION} will apply to all Phase 1 tools"
            fi
            download_tool_source cmake "${CUSTOM_VERSION}"
            download_tool_source ninja "${CUSTOM_VERSION}"
            download_tool_source python "${CUSTOM_VERSION}"
            ;;
        phase2)
            log "Downloading Phase 2: Build from source"
            if [[ -n "${CUSTOM_VERSION}" ]]; then
                warn "Custom version ${CUSTOM_VERSION} will apply to all Phase 2 tools"
            fi
            download_tool_source gcc "${CUSTOM_VERSION}"
            download_tool_source binutils "${CUSTOM_VERSION}"
            download_tool_source make "${CUSTOM_VERSION}"
            download_tool_source openssl "${CUSTOM_VERSION}"
            download_tool_source pkg-config "${CUSTOM_VERSION}"
            download_tool_source ccache "${CUSTOM_VERSION}"
            ;;
        phase3)
            log "Downloading Phase 3: Essential libraries"
            if [[ -n "${CUSTOM_VERSION}" ]]; then
                warn "Custom version ${CUSTOM_VERSION} will apply to all Phase 3 libraries"
            fi
            for lib in zlib libffi readline ncurses bzip2 xz sqlite; do
                download_tool_source "${lib}" "${CUSTOM_VERSION}"
            done
            ;;
        *)
            # Single tool download
            download_tool_source "${target}" "${CUSTOM_VERSION}"
            ;;
    esac
}

install_tool() {
    local target="$1"
    case "${target}" in
        all)
            install_tool phase1
            install_tool phase2
            install_tool phase3
            ;;
        phase1)
            log "Installing Phase 1: Pre-compiled binaries"
            bash "${SCRIPT_DIR}/installers/cmake.sh"
            bash "${SCRIPT_DIR}/installers/ninja.sh"
            bash "${SCRIPT_DIR}/installers/python.sh"
            ;;
        phase2)
            log "Installing Phase 2: Build from source"
            bash "${SCRIPT_DIR}/installers/gcc.sh"
            bash "${SCRIPT_DIR}/installers/binutils.sh"
            bash "${SCRIPT_DIR}/installers/make.sh"
            bash "${SCRIPT_DIR}/installers/openssl.sh"
            bash "${SCRIPT_DIR}/installers/pkg-config.sh"
            bash "${SCRIPT_DIR}/installers/ccache.sh"
            ;;
        phase3)
            log "Installing Phase 3: Essential libraries"
            for lib in zlib libffi readline ncurses bzip2 xz sqlite; do
                bash "${SCRIPT_DIR}/installers/libraries/${lib}.sh"
            done
            ;;
        *)
            if [[ -f "${SCRIPT_DIR}/installers/${target}.sh" ]]; then
                bash "${SCRIPT_DIR}/installers/${target}.sh"
            elif [[ -f "${SCRIPT_DIR}/installers/libraries/${target}.sh" ]]; then
                bash "${SCRIPT_DIR}/installers/libraries/${target}.sh"
            else
                error "Unknown target: ${target}"
                exit 1
            fi
            ;;
    esac
}

case "${COMMAND}" in
    help) show_help ;;
    list) list_tools ;;
    download)
        [[ -z "${TARGET}" ]] && error "No target specified" && exit 1
        download_only "${TARGET}"
        ;;
    install)
        [[ -z "${TARGET}" ]] && error "No target specified" && exit 1
        install_tool "${TARGET}"
        ;;
    status) check_status ;;
    test)
        [[ -z "${TARGET}" ]] && error "No tool specified" && exit 1
        test_tool "${TARGET}"
        ;;
    uninstall)
        [[ -z "${TARGET}" ]] && error "No tool specified" && exit 1
        uninstall_tool "${TARGET}"
        ;;
    *)
        error "Unknown command: ${COMMAND}"
        show_help
        exit 1
        ;;
esac
