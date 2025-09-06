#!/bin/bash
test_mirror_speed() {
    local url="$1"
    local timeout=5
    if command -v curl &> /dev/null; then
        curl -o /dev/null -s -w "%{time_total}" --connect-timeout ${timeout} --max-time ${timeout} "${url}" 2>/dev/null
    else
        wget -O /dev/null -T ${timeout} --tries=1 "${url}" 2>&1 | grep -oP 'Downloaded: .*\(\K[^)]+' | head -1
    fi
}

find_fastest_mirror() {
    local mirrors=("$@")
    local fastest_mirror=""
    local fastest_time=999999
    log "Testing mirror speeds..."
    for mirror in "${mirrors[@]}"; do
        debug "Testing mirror: ${mirror}"
        local time=$(test_mirror_speed "${mirror}")
        if [[ -n "${time}" ]] && (( $(echo "${time} < ${fastest_time}" | bc -l 2>/dev/null || echo 0) )); then
            fastest_time="${time}"
            fastest_mirror="${mirror}"
        fi
    done
    if [[ -n "${fastest_mirror}" ]]; then
        log "Fastest mirror: ${fastest_mirror} (response time: ${fastest_time}s)"
        echo "${fastest_mirror}"
    else
        echo "${mirrors[0]}"
    fi
}

# Get the best mirror URL for a given URL
get_best_mirror_url() {
    local original_url="$1"
    
    # Source mirrors configuration
    source "${SCRIPT_DIR}/config/mirrors.conf"
    
    # Determine which mirror set to use based on URL
    local mirrors=()
    if [[ "${original_url}" == *"ftp.gnu.org/gnu"* ]]; then
        mirrors=("${GNU_MIRRORS[@]}")
        local path="${original_url#*ftp.gnu.org/gnu}"
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            test_mirrors+=("${mirror}${path}")
        done
        echo "$(find_fastest_mirror "${test_mirrors[@]}")"
    elif [[ "${original_url}" == *"github.com"* ]]; then
        mirrors=("${GITHUB_MIRRORS[@]}")
        local path="${original_url#*github.com}"
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            if [[ "${mirror}" == *"ghproxy.com"* ]]; then
                test_mirrors+=("${mirror}${path}")
            else
                test_mirrors+=("${mirror}${path}")
            fi
        done
        echo "$(find_fastest_mirror "${test_mirrors[@]}")"
    elif [[ "${original_url}" == *"conda.anaconda.org"* || "${original_url}" == *"repo.anaconda.com"* ]]; then
        mirrors=("${CONDA_MIRRORS[@]}")
        local path
        if [[ "${original_url}" == *"conda.anaconda.org"* ]]; then
            path="${original_url#*conda.anaconda.org}"
        else
            path="${original_url#*repo.anaconda.com}"
        fi
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            test_mirrors+=("${mirror}${path}")
        done
        echo "$(find_fastest_mirror "${test_mirrors[@]}")"
    elif [[ "${original_url}" == *"openssl.org/source"* ]]; then
        mirrors=("${OPENSSL_MIRRORS[@]}")
        local path="${original_url#*openssl.org/source}"
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            test_mirrors+=("${mirror}${path}")
        done
        echo "$(find_fastest_mirror "${test_mirrors[@]}")"
    elif [[ "${original_url}" == *"zlib.net"* ]]; then
        mirrors=("${ZLIB_MIRRORS[@]}")
        local filename=$(basename "${original_url}")
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            if [[ "${mirror}" == *"sourceforge.net"* ]]; then
                # SourceForge has different URL structure
                test_mirrors+=("${mirror}/${filename}/download")
            else
                test_mirrors+=("${mirror}/${filename}")
            fi
        done
        echo "$(find_fastest_mirror "${test_mirrors[@]}")"
    elif [[ "${original_url}" == *"sourceware.org/pub"* ]]; then
        mirrors=("${SOURCEWARE_MIRRORS[@]}")
        local path="${original_url#*sourceware.org/pub}"
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            test_mirrors+=("${mirror}${path}")
        done
        echo "$(find_fastest_mirror "${test_mirrors[@]}")"
    else
        # No mirrors available, return original URL
        echo "${original_url}"
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    
    # Get the best mirror URL
    log "Selecting fastest mirror for ${description}..."
    local best_url=$(get_best_mirror_url "${url}")
    
    if [[ "${best_url}" != "${url}" ]]; then
        log "Using mirror: ${best_url}"
    fi
    log "Downloading ${description}..."
    mkdir -p "$(dirname "${output}")"
    if [[ "${VERBOSE}" == "true" ]]; then
        if command -v wget &> /dev/null; then
            wget -c --progress=bar:force "${best_url}" -O "${output}" 2>&1 | tee -a "${SCRIPT_DIR}/logs/download.log"
        else
            curl -L --progress-bar -C - "${best_url}" -o "${output}" 2>&1 | tee -a "${SCRIPT_DIR}/logs/download.log"
        fi
    else
        if command -v wget &> /dev/null; then
            wget -c -q "${best_url}" -O "${output}" 2>> "${SCRIPT_DIR}/logs/download.log"
        else
            curl -L -s -C - "${best_url}" -o "${output}" 2>> "${SCRIPT_DIR}/logs/download.log"
        fi
    fi
    if [[ $? -eq 0 ]]; then
        log "Successfully downloaded ${description}"
        return 0
    else
        error "Failed to download ${description}"
        return 1
    fi
}

extract_archive() {
    local file="$1"
    local dest="$2"
    mkdir -p "${dest}"
    case "${file}" in
        *.tar.gz|*.tgz)
            tar -xzf "${file}" -C "${dest}" --strip-components=1
            ;;
        *.tar.xz)
            tar -xJf "${file}" -C "${dest}" --strip-components=1
            ;;
        *.tar.bz2)
            tar -xjf "${file}" -C "${dest}" --strip-components=1
            ;;
        *.zip)
            unzip -q "${file}" -d "${dest}"
            ;;
        *.conda)
            tar -xf "${file}" -C "${dest}"
            ;;
        *)
            error "Unknown archive format: ${file}"
            return 1
            ;;
    esac
    if [[ $? -eq 0 ]]; then
        log "Successfully extracted ${file}"
        return 0
    else
        error "Failed to extract ${file}"
        return 1
    fi
}
