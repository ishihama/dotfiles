# aliases.sh - Modern CLI tool aliases

# Interactive-only: non-interactive shells (Claude Code's Bash tool, CI scripts)
# should see the real commands with their original option syntax.
[[ -o interactive ]] || return 0

alias vi=nvim
alias vim=nvim
alias cat='bat --paging=never'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias la='eza -a --icons'
alias lt='eza --tree --icons'
alias grep='rg'
alias find='fd'
alias ps='procs'
alias du='dust'
alias df='duf'
alias sed='sd'
alias top='btop'
alias http='xh'

# lazygit
alias lg='lazygit'
