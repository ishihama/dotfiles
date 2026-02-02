#!/bin/bash
# platform.sh - Platform detection utilities
# Detects the operating system and provides helper functions

# Detect the current platform
detect_platform() {
    local uname_str=$(uname -s)

    case "$uname_str" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            # Check if running under WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Platform check helper functions
is_macos() {
    [ "$(detect_platform)" = "macos" ]
}

is_linux() {
    [ "$(detect_platform)" = "linux" ]
}

is_wsl() {
    [ "$(detect_platform)" = "wsl" ]
}

# Export the platform for use in scripts
export DOTFILES_PLATFORM=$(detect_platform)

# Export functions
export -f detect_platform is_macos is_linux is_wsl
