#!/bin/bash
test_tool() {
    local tool="$1"
    log "Testing ${tool}..."
    case "${tool}" in
        cmake)
            "${TOOLS_PREFIX}/cmake/bin/cmake" --version &> /dev/null
            ;;
        ninja)
            "${TOOLS_PREFIX}/ninja/ninja" --version &> /dev/null
            ;;
        python|python3)
            "${TOOLS_PREFIX}/python/bin/python3" -c "import sys; print(sys.version)" &> /dev/null
            ;;
        gcc)
            "${TOOLS_PREFIX}/gcc/bin/gcc" --version &> /dev/null
            ;;
        make)
            "${TOOLS_PREFIX}/make/bin/make" --version &> /dev/null
            ;;
        openssl)
            "${TOOLS_PREFIX}/openssl/bin/openssl" version &> /dev/null
            ;;
        *)
            if [[ -x "${TOOLS_PREFIX}/${tool}/bin/${tool}" ]]; then
                "${TOOLS_PREFIX}/${tool}/bin/${tool}" --version &> /dev/null || true
                return 0
            else
                return 1
            fi
            ;;
    esac
    if [[ $? -eq 0 ]]; then
        log "✓ ${tool} is working correctly"
        return 0
    else
        error "✗ ${tool} test failed"
        return 1
    fi
}
