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
        local time=$(test_mirror_speed "${mirror}" 2>/dev/null || echo "")
        if [[ -n "${time}" ]] && (( $(echo "${time} < ${fastest_time}" | bc -l 2>/dev/null || echo 0) )); then
            fastest_time="${time}"
            fastest_mirror="${mirror}"
        fi
    done
    if [[ -n "${fastest_mirror}" ]]; then
        log "Fastest mirror: ${fastest_mirror} (response time: ${fastest_time}s)"
        echo "${fastest_mirror}"
    else
        log "No mirrors responded, using first mirror: ${mirrors[0]}"
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
        find_fastest_mirror "${test_mirrors[@]}"
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
        find_fastest_mirror "${test_mirrors[@]}"
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
        find_fastest_mirror "${test_mirrors[@]}"
    elif [[ "${original_url}" == *"openssl.org/source"* ]]; then
        mirrors=("${OPENSSL_MIRRORS[@]}")
        local path="${original_url#*openssl.org/source}"
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            test_mirrors+=("${mirror}${path}")
        done
        find_fastest_mirror "${test_mirrors[@]}"
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
        find_fastest_mirror "${test_mirrors[@]}"
    elif [[ "${original_url}" == *"sourceware.org/pub"* ]]; then
        mirrors=("${SOURCEWARE_MIRRORS[@]}")
        local path="${original_url#*sourceware.org/pub}"
        local test_mirrors=()
        for mirror in "${mirrors[@]}"; do
            test_mirrors+=("${mirror}${path}")
        done
        find_fastest_mirror "${test_mirrors[@]}"
    else
        # No mirrors available, return original URL
        echo "${original_url}"
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    local tool_name="${4:-unknown}"
    
    # Get the best mirror URL
    tool_log "${tool_name}" "Selecting fastest mirror for ${description}..." "download"
    local best_url
    best_url=$(get_best_mirror_url "${url}" | tail -n1) || {
        tool_warn "${tool_name}" "Mirror selection failed, using original URL" "download"
        best_url="${url}"
    }
    
    if [[ "${best_url}" != "${url}" ]]; then
        tool_log "${tool_name}" "Using mirror: ${best_url}" "download"
    fi
    tool_log "${tool_name}" "Downloading ${description}..." "download"
    mkdir -p "$(dirname "${output}")"
    
    local download_result=0
    
    if command -v wget &> /dev/null; then
        if [[ "${VERBOSE}" == "true" ]]; then
            run_command "${tool_name}" "download" "wget -c --progress=bar:force '${best_url}' -O '${output}'"
        else
            run_command "${tool_name}" "download" "wget -c -q '${best_url}' -O '${output}'"
        fi
        download_result=$?
    else
        if [[ "${VERBOSE}" == "true" ]]; then
            run_command "${tool_name}" "download" "curl -L --progress-bar -C - '${best_url}' -o '${output}'"
        else
            run_command "${tool_name}" "download" "curl -L -s -C - '${best_url}' -o '${output}'"
        fi
        download_result=$?
    fi
    
    if [[ ${download_result} -eq 0 ]]; then
        tool_log "${tool_name}" "Successfully downloaded ${description}" "download"
        return 0
    else
        tool_error "${tool_name}" "Failed to download ${description}" "download"
        return 1
    fi
}

extract_archive() {
    local file="$1"
    local dest="$2"
    local tool_name="${3:-unknown}"
    mkdir -p "${dest}"
    
    local extract_cmd=""
    case "${file}" in
        *.tar.gz|*.tgz)
            extract_cmd="tar -xzf '${file}' -C '${dest}' --strip-components=1"
            ;;
        *.tar.xz)
            extract_cmd="tar -xJf '${file}' -C '${dest}' --strip-components=1"
            ;;
        *.tar.bz2)
            extract_cmd="tar -xjf '${file}' -C '${dest}' --strip-components=1"
            ;;
        *.zip)
            extract_cmd="unzip -q '${file}' -d '${dest}'"
            ;;
        *.conda)
            extract_cmd="tar -xf '${file}' -C '${dest}'"
            ;;
        *)
            error "Unknown archive format: ${file}"
            return 1
            ;;
    esac
    
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}[CMD]${NC} ${extract_cmd}"
    fi
    
    eval "${extract_cmd}"
    if [[ $? -eq 0 ]]; then
        log "Successfully extracted ${file}"
        return 0
    else
        error "Failed to extract ${file}"
        return 1
    fi
}
