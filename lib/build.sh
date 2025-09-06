#!/bin/bash
configure_build() {
    local src_dir="$1"
    local prefix="$2"
    local tool_name="${3:-unknown}"
    shift 3
    local extra_args="$@"
    cd "${src_dir}"
    run_command "${tool_name}" "build" "./configure --prefix='${prefix}' ${extra_args}"
    return $?
}

run_make() {
    local target="${1:-}"
    local tool_name="${2:-unknown}"
    local jobs=$(get_cpu_count)
    tool_log "${tool_name}" "Building with ${jobs} parallel jobs" "build"
    run_command "${tool_name}" "build" "make -j${jobs} ${target}"
    return $?
}

cmake_build() {
    local src_dir="$1"
    local build_dir="$2"
    local prefix="$3"
    local tool_name="${4:-unknown}"
    shift 4
    local extra_args="$@"
    mkdir -p "${build_dir}"
    cd "${build_dir}"
    tool_log "${tool_name}" "Configuring with CMake" "build"
    run_command "${tool_name}" "build" "cmake '${src_dir}' -DCMAKE_INSTALL_PREFIX='${prefix}' -DCMAKE_BUILD_TYPE=Release ${extra_args}"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    run_make "" "${tool_name}"
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
    local tool_name="${1:-unknown}"
    tool_log "${tool_name}" "Installing..." "build"
    run_command "${tool_name}" "build" "make install"
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
