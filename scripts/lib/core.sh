#!/bin/bash
# core.sh - Core utility functions for dotfiles setup
# Provides logging, error handling, and common utilities

# Dry run mode (set via --dry-run flag in init.sh)
DRY_RUN=${DRY_RUN:-false}

# Color codes for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'

# Logging functions
log_header() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}===================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}$1${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}===================================================${COLOR_RESET}"
}

log_section() {
    echo -e "${COLOR_BOLD}${COLOR_BLUE}>>> $1${COLOR_RESET}"
}

log_info() {
    echo -e "${COLOR_CYAN}ℹ $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}" >&2
}

log_skip() {
    echo -e "${COLOR_YELLOW}⊘ $1${COLOR_RESET}"
}

# Error handler - called on script errors
error_handler() {
    local exit_code=$1
    local line_number=$2
    log_error "Error occurred in script at line $line_number (exit code: $exit_code)"
    log_info "Check the output above for details"
    exit "$exit_code"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create a timestamped backup of a file or directory
backup_path() {
    local path=$1
    if [ -e "$path" ]; then
        local timestamp=$(date +%Y%m%d%H%M%S)
        local backup_path="${path}.backup.${timestamp}"
        cp -r "$path" "$backup_path"
        log_info "Backed up $path to $backup_path"
        return 0
    fi
    return 1
}

# Create a symlink safely (with backup if target exists)
safe_symlink() {
    local source=$1
    local target=$2

    # Check if source exists
    if [ ! -e "$source" ]; then
        log_error "Source does not exist: $source"
        return 1
    fi

    # If target exists and is not a symlink to source
    if [ -e "$target" ] && [ "$(readlink "$target")" != "$source" ]; then
        backup_path "$target"
        rm -rf "$target"
    fi

    # Create symlink if it doesn't exist or points elsewhere
    if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$source" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would link: $target -> $source"
        else
            ln -sf "$source" "$target"
            log_success "Linked: $target -> $source"
        fi
    else
        log_skip "Already linked: $target"
    fi
}

# Ask for user confirmation (returns 0 for yes, 1 for no)
confirm() {
    local prompt=$1
    local default=${2:-n}  # Default to 'n' if not specified

    local yn_prompt
    if [ "$default" = "y" ]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi

    while true; do
        read -p "$prompt $yn_prompt " -n 1 -r
        echo

        # If empty response, use default
        if [ -z "$REPLY" ]; then
            [ "$default" = "y" ] && return 0 || return 1
        fi

        case "$REPLY" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Run a setup module script
run_setup_module() {
    local module_name=$1
    local description=$2
    local script_path="${SCRIPTS_DIR}/setup/${module_name}.sh"

    echo
    log_section "$description"

    if [ ! -f "$script_path" ]; then
        log_error "Module not found: $script_path"
        return 1
    fi

    # Source the module and run its setup function
    if source "$script_path" && setup_${module_name}; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Export functions for use in other scripts
export -f log_header log_section log_info log_success log_warn log_error log_skip
export -f error_handler command_exists backup_path safe_symlink confirm run_setup_module
