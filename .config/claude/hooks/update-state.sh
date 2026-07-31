#!/usr/bin/env bash
# update-state.sh - Claude Code hook handler
#
# Maintains per-session state under ~/.local/state/claude/sessions/{session_id}.json
# for the claude-status display script (tmux sidebar / status bar).
#
# Usage: update-state.sh <event_type>
#   events: session_start | prompt_submit | stop | notification | session_end
#
# Reads Claude Code hook input as JSON on stdin. Always exits 0 so a failure
# here can never break Claude.

EVENT="${1:-unknown}"
STATE_DIR="${HOME}/.local/state/claude/sessions"
mkdir -p "$STATE_DIR" 2>/dev/null

# Read hook input from stdin (may be empty when invoked manually)
INPUT=""
if [ ! -t 0 ]; then
    INPUT=$(cat 2>/dev/null || printf '')
fi

# Helper: extract a field from the hook JSON, falling back to empty string
jget() {
    printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null
}

SESSION_ID=$(jget '.session_id')
CWD=$(jget '.cwd')

# Without a session_id we cannot key state — bail out silently
if [ -z "$SESSION_ID" ]; then
    exit 0
fi

[ -z "$CWD" ] && CWD="$PWD"
PROJECT=$(basename "$CWD")

STATE_FILE="${STATE_DIR}/${SESSION_ID}.json"
TMP_FILE="${STATE_FILE}.tmp.$$"
NOW=$(date +%s)

# Read existing state if any (so we can preserve started_at across events)
EXISTING="{}"
if [ -f "$STATE_FILE" ]; then
    EXISTING=$(cat "$STATE_FILE" 2>/dev/null || printf '{}')
fi

# Build the updated state document
case "$EVENT" in
    session_start)
        STARTED_AT=$(printf '%s' "$EXISTING" | jq -r '.started_at // empty' 2>/dev/null)
        [ -z "$STARTED_AT" ] && STARTED_AT="$NOW"
        printf '%s' "$EXISTING" | jq \
            --arg sid "$SESSION_ID" \
            --arg cwd "$CWD" \
            --arg project "$PROJECT" \
            --argjson started "$STARTED_AT" \
            --argjson now "$NOW" \
            '. + {
                session_id: $sid,
                cwd: $cwd,
                project: $project,
                status: "idle",
                started_at: $started,
                updated_at: $now,
                last_idle_at: $now
            }' > "$TMP_FILE" 2>/dev/null
        ;;

    prompt_submit)
        # Truncate prompt to keep state file small
        PROMPT=$(jget '.prompt' | head -c 200)
        printf '%s' "$EXISTING" | jq \
            --arg sid "$SESSION_ID" \
            --arg cwd "$CWD" \
            --arg project "$PROJECT" \
            --arg prompt "$PROMPT" \
            --argjson now "$NOW" \
            '. + {
                session_id: $sid,
                cwd: $cwd,
                project: $project,
                status: "working",
                last_prompt: $prompt,
                updated_at: $now
            }' > "$TMP_FILE" 2>/dev/null
        ;;

    stop)
        # トランスクリプト末尾からClaudeの最後の返答を抽出する
        # (サイドバーで「何と言って終わったか」を表示するため)。
        # tail -c で切れた先頭の不完全なJSON行は tail -n +2 で捨てる
        TRANSCRIPT=$(jget '.transcript_path')
        LAST_REPLY=""
        if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
            # jq内で改行を潰して1メッセージ=1行にしてから最後の行を取る
            LAST_REPLY=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null | tail -n +2 | \
                jq -r 'select(.type == "assistant")
                       | [.message.content[]? | select(.type == "text") | .text]
                       | join(" ")
                       | gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "")' 2>/dev/null | \
                grep -v '^$' | tail -1 | head -c 200)
        fi
        printf '%s' "$EXISTING" | jq \
            --arg sid "$SESSION_ID" \
            --arg cwd "$CWD" \
            --arg project "$PROJECT" \
            --arg reply "$LAST_REPLY" \
            --argjson now "$NOW" \
            '. + {
                session_id: $sid,
                cwd: $cwd,
                project: $project,
                status: "idle",
                last_reply: $reply,
                updated_at: $now,
                last_idle_at: $now
            }' > "$TMP_FILE" 2>/dev/null
        ;;

    notification)
        MESSAGE=$(jget '.message' | head -c 200)
        printf '%s' "$EXISTING" | jq \
            --arg sid "$SESSION_ID" \
            --arg cwd "$CWD" \
            --arg project "$PROJECT" \
            --arg msg "$MESSAGE" \
            --argjson now "$NOW" \
            '. + {
                session_id: $sid,
                cwd: $cwd,
                project: $project,
                status: "waiting",
                last_notification: $msg,
                updated_at: $now
            }' > "$TMP_FILE" 2>/dev/null
        ;;

    session_end)
        rm -f "$STATE_FILE" 2>/dev/null
        # ステータスバーのClaudeセグメントを即時更新
        [ -n "$TMUX" ] && tmux refresh-client -S 2>/dev/null
        exit 0
        ;;

    *)
        exit 0
        ;;
esac

# Atomic move only if jq produced output
if [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$STATE_FILE" 2>/dev/null
else
    rm -f "$TMP_FILE" 2>/dev/null
fi

# tmux内で動作している場合、Claudeが動いているtmux上の位置を状態に記録し、
# ステータスバーのClaudeセグメント (claude-status bar) を即時更新する。
# tmux_session はサイドバー表示とセッション切替fzfの状態グリフに使われる。
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] && [ -s "$STATE_FILE" ]; then
    T_SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}' 2>/dev/null)
    T_WINDOW=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}' 2>/dev/null)
    T_PANE_INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_index}' 2>/dev/null)
    if [ -n "$T_SESSION" ]; then
        if jq --arg tsess "$T_SESSION" --arg twin "$T_WINDOW" --arg tpane "$TMUX_PANE" \
            --arg tpidx "$T_PANE_INDEX" \
            '. + {tmux_session: $tsess, tmux_window: $twin, tmux_pane: $tpane, tmux_pane_index: $tpidx}' \
            "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && [ -s "$TMP_FILE" ]; then
            mv "$TMP_FILE" "$STATE_FILE" 2>/dev/null
        else
            rm -f "$TMP_FILE" 2>/dev/null
        fi
    fi
    tmux refresh-client -S 2>/dev/null
fi

# 入力待ち (許可プロンプト等) になったらmacOS通知センターに表示する。
# 引数渡し (on run argv) なのでメッセージ内の引用符での注入は起きない。
# 無効化: CLAUDE_NOTIFY_DISABLED=1
if [ "$EVENT" = "notification" ] \
   && [ "${CLAUDE_NOTIFY_DISABLED:-0}" != "1" ] \
   && command -v osascript >/dev/null 2>&1; then
    osascript \
        -e 'on run argv' \
        -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
        -e 'end run' \
        "${MESSAGE:-Waiting for input}" "Claude Code: ${PROJECT}" \
        >/dev/null 2>&1 &
fi

exit 0
