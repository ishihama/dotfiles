# memo.sh - Simple memo management (~/memos/)

MEMO_DIR=~/memos

function memo() {
    mkdir -p "$MEMO_DIR"

    if [[ -n "$1" ]]; then
        nvim "$MEMO_DIR/$1.md"
    else
        local selected=$(
            { echo "[+ 新規作成]"; fd -e md . "$MEMO_DIR" 2>/dev/null | xargs -I{} basename {} .md; } | \
            fzf --prompt="Memo > " \
                --preview='[[ {} == "[+ 新規作成]" ]] && echo "新しいメモを作成" || bat --color=always --style=plain '"$MEMO_DIR"'/{}.md 2>/dev/null' \
                --preview-window=right:60%
        )

        [[ -z "$selected" ]] && return

        if [[ "$selected" == "[+ 新規作成]" ]]; then
            echo -n "ファイル名 (拡張子不要): "
            read filename
            [[ -z "$filename" ]] && return
            nvim "$MEMO_DIR/$filename.md"
        else
            nvim "$MEMO_DIR/$selected.md"
        fi
    fi
}

function memo-search() {
    mkdir -p "$MEMO_DIR"

    local match=$(
        rg --color=always --line-number --no-heading . "$MEMO_DIR" 2>/dev/null | \
        fzf --ansi --prompt="Search > " \
            --preview='bat --color=always --highlight-line={2} {1}' \
            --preview-window='+{2}-10' \
            --delimiter=':'
    )

    if [[ -n "$match" ]]; then
        local file=$(echo "$match" | cut -d':' -f1)
        local line=$(echo "$match" | cut -d':' -f2)
        nvim "+$line" "$file"
    fi
}
