# Core Build Kit Installer

A comprehensive toolkit installer for Debian 9 systems without root access.

## Features
- Automatic dependency resolution
- Mirror speed testing  
- Parallel compilation (24 cores)
- Version management with symlinks
- Rollback capability
- Comprehensive logging

## Quick Start
```bash
./installer.sh help          # Show help
./installer.sh list          # List available tools
./installer.sh install all   # Install everything
./installer.sh status        # Check installation status
```

## Tools Included

### Phase 1 - Pre-compiled Binaries
- CMake 3.27.9 (LTS)
- Ninja 1.11.1
- Python 3.11.8

### Phase 2 - Build from Source  
- GCC 10.5.0
- Binutils 2.40
- Make 4.4.1
- OpenSSL 3.0.13 (LTS)
- pkg-config 0.29.2
- ccache 4.9

### Phase 3 - Essential Libraries
- zlib 1.3.1
- libffi 3.4.4
- readline 8.2
- ncurses 6.4
- bzip2 1.0.8
- xz 5.4.5
- sqlite 3.44.2
