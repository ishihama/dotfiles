#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"

input=$(cat)
worktree_path=$(echo "$input" | jq -r '.worktree_path // empty')
branch=$(echo "$input" | jq -r '.branch // empty')

if command -v gwq &>/dev/null && [[ -n "$branch" ]]; then
    gwq remove -f -b "$branch" 2>/dev/null || true
else
    [[ -n "$worktree_path" ]] && git worktree remove --force "$worktree_path" 2>/dev/null || true
    [[ -n "$branch" ]] && git branch -D "$branch" 2>/dev/null || true
fi
