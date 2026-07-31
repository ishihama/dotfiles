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

# True when --dry-run was passed to init.sh
is_dry_run() {
    [ "$DRY_RUN" = true ]
}

# Run a command, or describe it when in dry-run mode.
# Usage: run_cmd rm -rf "$target"
# NOTE: this takes a plain argv - it cannot carry shell redirections or pipes.
#       Guard those with `is_dry_run` at the call site instead.
run_cmd() {
    if is_dry_run; then
        log_info "[DRY RUN] would run: $*"
        return 0
    fi
    "$@"
}

# Download a remote installer to a temp file and echo its path.
# The caller is responsible for removing the file.
#
# This exists because `sh -c "$(curl -fsSL ...)"` succeeds silently when the
# download fails: the command substitution collapses to an empty string and
# `sh -c ""` exits 0, so the caller happily reports success.
fetch_installer() {
    local url=$1
    local tmp
    tmp=$(mktemp) || return 1

    if ! curl -fsSL "$url" -o "$tmp"; then
        log_error "Download failed: $url"
        rm -f "$tmp"
        return 1
    fi

    if [ ! -s "$tmp" ]; then
        log_error "Downloaded an empty file: $url"
        rm -f "$tmp"
        return 1
    fi

    printf '%s\n' "$tmp"
}

# Create a timestamped backup of a file or directory
backup_path() {
    local path=$1
    [ -e "$path" ] || return 1

    if is_dry_run; then
        log_info "[DRY RUN] would back up: $path"
        return 0
    fi

    local timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    local dest="${path}.backup.${timestamp}"

    # Two backups of the same target within one second must not nest inside
    # each other, so keep looking until we find a free name.
    local n=1
    while [ -e "$dest" ]; do
        dest="${path}.backup.${timestamp}.${n}"
        n=$((n + 1))
    done

    # -P keeps symlinks inside the tree as symlinks instead of dereferencing them
    if cp -RP "$path" "$dest"; then
        log_info "Backed up $path to $dest"
        return 0
    fi

    log_error "Failed to back up $path"
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

    # Already pointing where we want it
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        log_skip "Already linked: $target"
        return 0
    fi

    # Something else occupies the target. Clear it out first - but never in
    # dry-run mode, which must leave the filesystem exactly as it found it.
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            # A symlink carries no data of its own, so replace it without a backup
            if is_dry_run; then
                log_info "[DRY RUN] would replace symlink: $target -> $(readlink "$target")"
            else
                rm -f "$target"
            fi
        else
            if is_dry_run; then
                log_info "[DRY RUN] would back up and remove: $target"
            else
                backup_path "$target" || return 1
                rm -rf "$target"
            fi
        fi
    fi

    if is_dry_run; then
        log_info "[DRY RUN] would link: $target -> $source"
        return 0
    fi

    # -n so that a leftover symlink-to-directory is replaced rather than
    # having the new link created inside it
    ln -sfn "$source" "$target"
    log_success "Linked: $target -> $source"
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

    # Read a whole line, not a single character. With `-n 1` a user typing
    # "yes<Enter>" leaves "es" in the buffer, which the next `read` in the
    # caller silently consumes as its answer.
    local reply
    while true; do
        printf '%s %s ' "$prompt" "$yn_prompt"
        if ! read -r reply; then
            echo
            [ "$default" = "y" ] && return 0 || return 1
        fi

        # If empty response, use default
        if [ -z "$reply" ]; then
            [ "$default" = "y" ] && return 0 || return 1
        fi

        case "$reply" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo])     return 1 ;;
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
export -f error_handler command_exists is_dry_run run_cmd fetch_installer
export -f backup_path safe_symlink confirm run_setup_module
