#!/bin/bash
set -e
export PATH="/opt/homebrew/bin:$PATH"

input=$(cat)
new_branch=$(echo "$input" | jq -r '.new_branch // empty')
base_branch=$(echo "$input" | jq -r '.base_branch // "HEAD"')

if command -v gwq &>/dev/null; then
    git branch "$new_branch" "$base_branch" 2>/dev/null || true
    gwq add "$new_branch" >/dev/null 2>&1
    gwq get "$new_branch"
else
    worktree_path=".claude/worktrees/${new_branch}"
    mkdir -p "$(dirname "$worktree_path")"
    git worktree add -b "$new_branch" "$worktree_path" "$base_branch"
    echo "$worktree_path"
fi
