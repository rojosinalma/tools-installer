#!/bin/bash
configure_build() {
    local src_dir="$1"
    local prefix="$2"
    shift 2
    local extra_args="$@"
    cd "${src_dir}"
    if [[ "${VERBOSE}" == "true" ]]; then
        ./configure --prefix="${prefix}" ${extra_args} 2>&1 | tee -a "${SCRIPT_DIR}/logs/build.log"
    else
        ./configure --prefix="${prefix}" ${extra_args} >> "${SCRIPT_DIR}/logs/build.log" 2>&1
    fi
    return $?
}

run_make() {
    local target="${1:-}"
    local jobs=$(get_cpu_count)
    log "Building with ${jobs} parallel jobs"
    if [[ "${VERBOSE}" == "true" ]]; then
        make -j${jobs} ${target} 2>&1 | tee -a "${SCRIPT_DIR}/logs/build.log"
    else
        make -j${jobs} ${target} >> "${SCRIPT_DIR}/logs/build.log" 2>&1
    fi
    return $?
}

cmake_build() {
    local src_dir="$1"
    local build_dir="$2"
    local prefix="$3"
    shift 3
    local extra_args="$@"
    mkdir -p "${build_dir}"
    cd "${build_dir}"
    log "Configuring with CMake"
    if [[ "${VERBOSE}" == "true" ]]; then
        cmake "${src_dir}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DCMAKE_BUILD_TYPE=Release \
            ${extra_args} 2>&1 | tee -a "${SCRIPT_DIR}/logs/build.log"
    else
        cmake "${src_dir}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DCMAKE_BUILD_TYPE=Release \
            ${extra_args} >> "${SCRIPT_DIR}/logs/build.log" 2>&1
    fi
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    run_make
    return $?
}

clean_build() {
    local build_dir="$1"
    if [[ -d "${build_dir}" ]]; then
        log "Cleaning build directory: ${build_dir}"
        rm -rf "${build_dir}"
    fi
}

install_make() {
    log "Installing..."
    if [[ "${VERBOSE}" == "true" ]]; then
        make install 2>&1 | tee -a "${SCRIPT_DIR}/logs/install.log"
    else
        make install >> "${SCRIPT_DIR}/logs/install.log" 2>&1
    fi
    return $?
}

set_optimization_flags() {
    export CFLAGS="-O3 -march=native -mtune=native"
    export CXXFLAGS="-O3 -march=native -mtune=native"
    export LDFLAGS="-Wl,-rpath,${TOOLS_PREFIX}/lib -Wl,-rpath,${TOOLS_PREFIX}/lib64"
    debug "Optimization flags set: CFLAGS=${CFLAGS}"
}

unset_optimization_flags() {
    unset CFLAGS
    unset CXXFLAGS
    unset LDFLAGS
}
