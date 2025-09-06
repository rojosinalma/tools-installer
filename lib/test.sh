#!/bin/bash
test_tool() {
    local tool="$1"
    
    if [[ "${tool}" == "all" ]]; then
        log "Testing all installed tools..."
        local tools=(cmake ninja python gcc g++ make binutils openssl pkg-config ccache zlib libffi readline ncurses bzip2 xz sqlite)
        local success=0
        local failed=0
        
        for t in "${tools[@]}"; do
            if test_single_tool "${t}"; then
                ((success++))
            else
                ((failed++))
            fi
        done
        
        echo ""
        log "Test Results: ${success} passed, ${failed} failed"
        return $((failed > 0 ? 1 : 0))
    else
        test_single_tool "${tool}"
    fi
}

test_single_tool() {
    local tool="$1"
    local test_cmd=""
    local display_name="${tool}"
    
    # Check if tool is installed
    if [[ ! -L "${TOOLS_PREFIX}/${tool}" ]] && [[ ! -d "${TOOLS_PREFIX}/${tool}" ]]; then
        echo "○ ${tool}: not installed"
        return 1
    fi
    
    # Set up test command based on tool
    case "${tool}" in
        cmake)
            test_cmd="${TOOLS_PREFIX}/cmake/bin/cmake --version"
            ;;
        ninja)
            test_cmd="${TOOLS_PREFIX}/ninja/bin/ninja --version"
            ;;
        python|python3)
            test_cmd="${TOOLS_PREFIX}/python/bin/python3 --version"
            display_name="python"
            ;;
        gcc)
            test_cmd="${TOOLS_PREFIX}/gcc/bin/gcc --version"
            ;;
        g++)
            test_cmd="${TOOLS_PREFIX}/gcc/bin/g++ --version"
            ;;
        make)
            test_cmd="${TOOLS_PREFIX}/make/bin/make --version"
            ;;
        binutils|ld)
            test_cmd="${TOOLS_PREFIX}/binutils/bin/ld --version"
            display_name="binutils"
            ;;
        openssl)
            test_cmd="${TOOLS_PREFIX}/openssl/bin/openssl version"
            ;;
        pkg-config)
            test_cmd="${TOOLS_PREFIX}/pkg-config/bin/pkg-config --version"
            ;;
        ccache)
            test_cmd="${TOOLS_PREFIX}/ccache/bin/ccache --version"
            ;;
        sqlite|sqlite3)
            test_cmd="${TOOLS_PREFIX}/sqlite/bin/sqlite3 --version"
            display_name="sqlite"
            ;;
        bzip2)
            test_cmd="${TOOLS_PREFIX}/bzip2/bin/bzip2 --help"
            ;;
        xz)
            test_cmd="${TOOLS_PREFIX}/xz/bin/xz --version"
            ;;
        zlib|libffi|readline|ncurses)
            # Library - check if directory exists
            if [[ -d "${TOOLS_PREFIX}/${tool}" ]]; then
                echo "✓ ${tool}: library installed"
                return 0
            else
                echo "✗ ${tool}: library not found"
                return 1
            fi
            ;;
        *)
            # Try generic approach
            if [[ -x "${TOOLS_PREFIX}/${tool}/bin/${tool}" ]]; then
                test_cmd="${TOOLS_PREFIX}/${tool}/bin/${tool} --version"
            else
                echo "? ${tool}: unknown tool or no test available"
                return 1
            fi
            ;;
    esac
    
    # Run test command if set
    if [[ -n "${test_cmd}" ]]; then
        if ${test_cmd} &> /dev/null; then
            local version=$(${test_cmd} 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+[\.0-9]*' | head -1)
            if [[ -n "${version}" ]]; then
                echo "✓ ${display_name}: version ${version}"
            else
                echo "✓ ${display_name}: working"
            fi
            return 0
        else
            echo "✗ ${display_name}: test failed"
            return 1
        fi
    fi
}
