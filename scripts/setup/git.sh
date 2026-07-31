#!/bin/bash
# git.sh - Interactive Git configuration setup
# Auto-generates .gitconfig.local and account-specific configs

# Register a public key to GitHub via gh CLI (with auth/scope fallbacks)
register_ssh_key_github() {
    local ssh_key_path=$1
    local account_type=$2
    local pub_key="${ssh_key_path}.pub"
    local key_title
    key_title="$(hostname)-$account_type"

    if ! command_exists gh; then
        log_warn "gh CLI not found - register the key manually:"
        echo "  gh ssh-key add $pub_key --title \"$key_title\""
        return 0
    fi

    if ! confirm "Register the public key to GitHub now via gh?" "y"; then
        log_info "Register it later with: gh ssh-key add $pub_key --title \"$key_title\""
        return 0
    fi

    # Ensure gh is authenticated (browser flow)
    if ! gh auth status >/dev/null 2>&1; then
        log_info "gh is not authenticated yet - launching gh auth login (browser flow)"
        if ! gh auth login --hostname github.com --git-protocol https --web; then
            log_warn "gh auth login failed - register the key manually:"
            echo "  gh auth login"
            echo "  gh ssh-key add $pub_key --title \"$key_title\""
            return 0
        fi
    fi

    # The key lands on the ACTIVE gh account - make sure it's the right one
    local active_user
    active_user=$(gh api user --jq .login 2>/dev/null)
    if [ -n "$active_user" ]; then
        if ! confirm "Register to GitHub account '$active_user' (active gh account)?" "y"; then
            log_info "Switch accounts first, then register manually:"
            echo "  gh auth login   # or: gh auth switch --user <username>"
            echo "  gh ssh-key add $pub_key --title \"$key_title\""
            return 0
        fi
    fi

    if gh ssh-key add "$pub_key" --title "$key_title" 2>/dev/null; then
        log_success "Registered $pub_key to GitHub as \"$key_title\""
        return 0
    fi

    # Most common failure: token lacks the admin:public_key scope
    log_warn "Failed to register (token likely lacks the admin:public_key scope)"
    if confirm "Grant the scope via gh auth refresh and retry?" "y"; then
        if gh auth refresh --hostname github.com --scopes admin:public_key \
            && gh ssh-key add "$pub_key" --title "$key_title"; then
            log_success "Registered $pub_key to GitHub as \"$key_title\""
            return 0
        fi
    fi
    log_warn "Could not register automatically - do it manually:"
    echo "  gh auth refresh --hostname github.com --scopes admin:public_key"
    echo "  gh ssh-key add $pub_key --title \"$key_title\""
    return 0
}

# Check SSH keys referenced by existing account configs (for re-runs where
# Git config is already set up but keys were never generated)
check_existing_ssh_keys() {
    local account_type config_file key_path git_email
    for account_type in personal work; do
        config_file="$HOME/.gitconfig.$account_type"
        [ -f "$config_file" ] || continue
        # Extract the key path from: sshCommand = ssh -i <path> -o IdentitiesOnly=yes
        key_path=$(awk '/sshCommand/ { for (i = 1; i <= NF; i++) if ($i == "-i") print $(i + 1) }' "$config_file")
        [ -n "$key_path" ] || continue
        key_path="${key_path/#\~/$HOME}"
        git_email=$(git config --file "$config_file" user.email 2>/dev/null)
        ensure_ssh_key "$key_path" "${git_email:-$USER@$(hostname)}" "$account_type"
    done
}

# Ensure an SSH key exists (offer to generate + register to GitHub)
ensure_ssh_key() {
    local ssh_key_path=$1
    local git_email=$2
    local account_type=$3

    if [ -f "$ssh_key_path" ]; then
        log_success "SSH key exists: $ssh_key_path"
        return 0
    fi

    log_warn "SSH key not found: $ssh_key_path"
    if ! confirm "Generate it now (ed25519)?" "y"; then
        log_info "Generate it later with: ssh-keygen -t ed25519 -C \"$git_email\" -f $ssh_key_path"
        echo "  Then add it to GitHub: gh ssh-key add ${ssh_key_path}.pub --title \"$(hostname)-$account_type\""
        return 0
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # ssh-keygen prompts for a passphrase interactively (empty = no passphrase)
    if ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key_path"; then
        log_success "Generated $ssh_key_path"
        register_ssh_key_github "$ssh_key_path" "$account_type"
    else
        log_warn "ssh-keygen failed - generate it manually:"
        echo "  ssh-keygen -t ed25519 -C \"$git_email\" -f $ssh_key_path"
    fi
}

# Prompt until a non-empty answer that passes an optional validator is given.
# Always uses `read -r` so a backslash in a name is not eaten.
#   prompt_value <varname> <prompt> [validator_regex] [error_message]
prompt_value() {
    local __var=$1 __prompt=$2 __pattern=${3:-} __err=${4:-Invalid value.}
    local __input
    while true; do
        printf '%s' "$__prompt"
        read -r __input
        if [ -z "$__input" ]; then
            echo "Value cannot be empty."
            continue
        fi
        if [ -n "$__pattern" ] && ! printf '%s' "$__input" | grep -Eq "$__pattern"; then
            echo "$__err"
            continue
        fi
        printf -v "$__var" '%s' "$__input"
        return 0
    done
}

setup_git_account() {
    local account_type=$1  # "personal" or "work"
    local config_file="$HOME/.gitconfig.$account_type"

    echo
    log_section "Setting up $account_type Git account"

    # git config treats # and ; as comment starters and a trailing backslash as
    # a line continuation, so a name containing them silently corrupts the file.
    local git_name git_email ssh_key_path
    prompt_value git_name "Name for $account_type commits: " \
        '^[^#;\\]*[^#;\\[:space:]][^#;\\]*$' \
        "Name cannot contain # ; or \\."
    prompt_value git_email "Email for $account_type commits: " \
        '^[^[:space:]#;\\]+@[^[:space:]#;\\]+\.[^[:space:]#;\\]+$' \
        "Enter a valid email address."

    # Prompt for SSH key path
    local default_ssh_key="$HOME/.ssh/id_ed25519_$account_type"
    printf 'SSH key path (default: %s): ' "$default_ssh_key"
    read -r ssh_key_path
    ssh_key_path=${ssh_key_path:-$default_ssh_key}
    # Expand a leading ~ ourselves: read does not, and ssh-keygen would happily
    # create a directory literally named "~" in the current directory.
    ssh_key_path="${ssh_key_path/#\~/$HOME}"

    # Back up an existing account config even when ~/.gitconfig.local is absent
    # (an aborted earlier run leaves exactly that state)
    [ -f "$config_file" ] && backup_path "$config_file"

    # Create the config file
    cat > "$config_file" <<EOF
[user]
	name = $git_name
	email = $git_email

[core]
	sshCommand = ssh -i $ssh_key_path -o IdentitiesOnly=yes
EOF

    log_success "Created $config_file"

    # Generate + register the SSH key if it doesn't exist
    ensure_ssh_key "$ssh_key_path" "$git_email" "$account_type"
}

setup_git() {
    # This module is interactive and writes ~/.gitconfig.*, generates SSH keys
    # and uploads them to GitHub - none of which can be meaningfully previewed.
    if is_dry_run; then
        if [ -f "$HOME/.gitconfig.local" ]; then
            log_info "[DRY RUN] ~/.gitconfig.local exists; would offer to reconfigure"
        else
            log_info "[DRY RUN] would prompt for Git accounts and write ~/.gitconfig.local,"
            log_info "[DRY RUN]   ~/.gitconfig.personal, ~/.gitconfig.work, ~/.config/gh/account-map"
            log_info "[DRY RUN]   and offer to generate an SSH key and register it with GitHub"
        fi
        return 0
    fi

    # Check if .gitconfig.local already exists
    if [ -f "$HOME/.gitconfig.local" ]; then
        log_skip "Git configuration already exists at ~/.gitconfig.local"
        if confirm "Do you want to reconfigure Git accounts?" "n"; then
            backup_path "$HOME/.gitconfig.local"
            [ -f "$HOME/.gitconfig.personal" ] && backup_path "$HOME/.gitconfig.personal"
            [ -f "$HOME/.gitconfig.work" ] && backup_path "$HOME/.gitconfig.work"
        else
            # Still make sure the referenced SSH keys exist (generate + register if not)
            check_existing_ssh_keys
            return 0
        fi
    fi

    echo
    log_info "Git supports multiple account configurations."
    log_info "This setup will create .gitconfig.local with includeIf directives."
    echo

    if ! confirm "Do you want to set up Git account configuration now?" "y"; then
        log_skip "Skipping Git configuration"
        return 0
    fi

    # GitHub owner names go into an includeIf gitdir: pattern, so restrict them
    # to what GitHub actually allows. A name with a space or quote produces a
    # pattern that never matches, and commits then go out as the INVALID
    # placeholder user with no visible error.
    local gh_name_re='^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$'
    local gh_name_err="Use letters, digits and hyphens only (max 39 characters)."

    local github_username work_org work_gh_username=""
    echo
    prompt_value github_username \
        "Enter your GitHub username (for personal repos): " \
        "$gh_name_re" "$gh_name_err"

    # Prompt for work account
    local has_work_account=false
    echo
    if confirm "Do you have a work account?" "n"; then
        has_work_account=true
        prompt_value work_org "Enter work organization name: " \
            "$gh_name_re" "$gh_name_err"
        prompt_value work_gh_username \
            "Enter your work GitHub username (for gh CLI): " \
            "$gh_name_re" "$gh_name_err"
    fi

    # Set up personal account
    setup_git_account "personal"

    # Set up work account if requested
    if [ "$has_work_account" = true ]; then
        setup_git_account "work"
    fi

    # Create .gitconfig.local with includeIf directives
    echo
    log_section "Creating .gitconfig.local"

    # Overwrites any hand-added third includeIf; back it up so it is recoverable
    [ -f "$HOME/.gitconfig.local" ] && backup_path "$HOME/.gitconfig.local"

    cat > "$HOME/.gitconfig.local" <<EOF
# Auto-generated by dotfiles setup
# This file is NOT tracked in the dotfiles repository
# Re-running ./init.sh rewrites it; the previous version is kept as
# .gitconfig.local.backup.<timestamp>

# Personal repositories: ~/repos/github.com/$github_username/
[includeIf "gitdir:~/repos/github.com/$github_username/"]
	path = ~/.gitconfig.personal
EOF

    if [ "$has_work_account" = true ]; then
        cat >> "$HOME/.gitconfig.local" <<EOF

# Work repositories: ~/repos/github.com/$work_org/
[includeIf "gitdir:~/repos/github.com/$work_org/"]
	path = ~/.gitconfig.work
EOF
    fi

    log_success "Created ~/.gitconfig.local"

    # Summary
    echo
    log_section "Git Configuration Summary"
    echo "Personal repos: ~/repos/github.com/$github_username/"
    echo "  Config: ~/.gitconfig.personal"
    if [ "$has_work_account" = true ]; then
        echo "Work repos: ~/repos/github.com/$work_org/"
        echo "  Config: ~/.gitconfig.work"
    fi
    echo
    log_info "Clone repositories using: gh repo clone <owner>/<repo>"
    log_info "This will automatically place them in the correct directory structure"

    # Generate gh CLI account-map for automatic account switching
    log_section "Creating gh account-map"
    mkdir -p "$HOME/.config/gh"
    local account_map="$HOME/.config/gh/account-map"

    # Same as .gitconfig.local: this is rewritten wholesale, so keep a copy of
    # any manually added mappings
    [ -f "$account_map" ] && backup_path "$account_map"

    cat > "$account_map" <<EOF
# Auto-generated by dotfiles setup
# Format: directory-owner gh-username
$github_username $github_username
EOF

    if [ "$has_work_account" = true ] && [ -n "$work_gh_username" ]; then
        echo "$work_org $work_gh_username" >> "$account_map"
    fi

    log_success "Created $account_map"
    log_info "gh CLI will auto-switch accounts based on ~/repos/github.com/{owner}/ directory"
}
