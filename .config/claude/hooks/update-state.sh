#!/usr/bin/env bash
# update-state.sh - Claude Code hook handler
#
# Maintains per-session state under ~/.local/state/claude/sessions/{session_id}.json
# for the claude-screensaver display script.
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
        printf '%s' "$EXISTING" | jq \
            --arg sid "$SESSION_ID" \
            --arg cwd "$CWD" \
            --arg project "$PROJECT" \
            --argjson now "$NOW" \
            '. + {
                session_id: $sid,
                cwd: $cwd,
                project: $project,
                status: "idle",
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
        # Kill screensaver loop for this session before removing state
        _pid_file="${STATE_DIR}/${SESSION_ID}.screensaver.pid"
        if [ -f "$_pid_file" ]; then
            _old_pid=$(cat "$_pid_file" 2>/dev/null)
            if [ -n "$_old_pid" ]; then
                pkill -P "$_old_pid" 2>/dev/null
                kill "$_old_pid" 2>/dev/null
            fi
            rm -f "$_pid_file"
        fi
        rm -f "$STATE_FILE" 2>/dev/null
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

# After a Stop event, schedule a screensaver popup if the session stays idle.
# Detach fully so Claude Code's hook executor does not wait on us.
#
# Behavior:
#   - Skip unless we're inside tmux (popup needs tmux)
#   - Skip if CLAUDE_SCREENSAVER_DISABLED=1
#   - Kill any previous screensaver loop for this session (prevents accumulation)
#   - Wait CLAUDE_SCREENSAVER_IDLE_SECONDS (default 600)
#   - If state file's updated_at is unchanged AND status is still "idle",
#     open the screensaver in a tmux popup (Esc dismisses it)
#   - Popup lock file prevents multiple sessions from opening popups simultaneously
#   - If anything changed in the meantime (new prompt, notification, end),
#     a newer event already moved updated_at and the timer silently no-ops
if [ "$EVENT" = "stop" ] && [ -n "$TMUX" ] \
   && [ "${CLAUDE_SCREENSAVER_DISABLED:-0}" != "1" ] \
   && [ -f "$STATE_FILE" ]; then

    # Kill previous screensaver loop for this session
    PID_FILE="${STATE_DIR}/${SESSION_ID}.screensaver.pid"
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$OLD_PID" ]; then
            pkill -P "$OLD_PID" 2>/dev/null
            kill "$OLD_PID" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi

    SAVED_TS=$(jq -r '.updated_at // 0' "$STATE_FILE" 2>/dev/null)
    IDLE_SECONDS="${CLAUDE_SCREENSAVER_IDLE_SECONDS:-600}"
    SCREENSAVER_BIN="$HOME/.config/claude/bin/claude-screensaver"
    POPUP_LOCK="${STATE_DIR}/.popup.lock"
    # Capture Claude's tmux pane ID now, while this hook still runs in the
    # foreground with Claude as the active pane. The background loop below
    # needs this to check copy-mode on Claude's pane specifically (not
    # whatever pane happens to be active when the loop wakes up).
    CLAUDE_PANE=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
    # Double-fork pattern: outer subshell exits immediately, inner backgrounded
    # process is reparented to init and fully detached from Claude Code's hook.
    (
        (
            # Record this loop's PID so future Stop events can kill it
            printf '%s' "$BASHPID" > "$PID_FILE"
            trap 'rm -f "$PID_FILE"' EXIT

            # Loop so the screensaver keeps coming back while the session
            # remains idle. Each iteration: sleep → check if state still
            # unchanged and idle → (skip if user is scrolling) → (skip if
            # another session has popup open) → open popup (blocks until
            # dismissed) → loop. Breaks when the user submits a new prompt,
            # a notification comes in, or the session ends (all of which
            # move updated_at away from SAVED_TS or delete the state file).
            while true; do
                sleep "$IDLE_SECONDS"
                [ -f "$STATE_FILE" ] || break
                CUR_TS=$(jq -r '.updated_at // 0' "$STATE_FILE" 2>/dev/null)
                CUR_STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null)
                [ "$CUR_TS" = "$SAVED_TS" ] || break
                [ "$CUR_STATUS" = "idle" ] || break
                # Skip popup while the user is in tmux copy-mode on Claude's
                # pane (they're actively scrolling through output). Retry on
                # the next loop iteration once they exit copy-mode.
                if [ -n "$CLAUDE_PANE" ]; then
                    IN_MODE=$(tmux display-message -t "$CLAUDE_PANE" -p '#{pane_in_mode}' 2>/dev/null)
                    if [ "$IN_MODE" = "1" ]; then
                        continue
                    fi
                fi
                # Skip if another session already has a popup open
                if [ -f "$POPUP_LOCK" ]; then
                    LOCK_PID=$(cat "$POPUP_LOCK" 2>/dev/null)
                    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
                        continue
                    fi
                    rm -f "$POPUP_LOCK"
                fi
                # Acquire popup lock, open screensaver, release on close
                printf '%s' "$BASHPID" > "$POPUP_LOCK"
                # Pass tmux's own client width through — `tput cols` inside a
                # freshly spawned popup can return stale 80, breaking figlet
                # auto-fit.
                POPUP_W=$(tmux display-message -p '#{client_width}' 2>/dev/null)
                tmux display-popup -w 100% -h 100% -E \
                    "CLAUDE_SCREENSAVER_COLUMNS=${POPUP_W:-180} $SCREENSAVER_BIN --session $SESSION_ID" 2>/dev/null
                rm -f "$POPUP_LOCK"
                # After popup closes (Esc), fall through and sleep again.
            done
        ) </dev/null >/dev/null 2>&1 &
    )
fi

exit 0
