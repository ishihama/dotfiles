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

# State files contain cwd and prompt text, so keep them owner-only.
umask 077
STATE_DIR="${HOME}/.local/state/claude/sessions"
mkdir -p "$STATE_DIR" 2>/dev/null
chmod 700 "$STATE_DIR" 2>/dev/null

# Read hook input from stdin (may be empty when invoked manually)
INPUT=""
if [ ! -t 0 ]; then
    INPUT=$(cat 2>/dev/null || printf '')
fi

# Extract every field we need in ONE jq pass rather than forking per field.
# Truncation happens inside jq (.[0:200]) so it counts characters, not bytes -
# `head -c 200` used to slice Japanese prompts mid-codepoint.
# Control characters are flattened to spaces so the US-separated read below
# cannot be split by an embedded newline.
FIELD_SEP=$'\x1f'
IFS="$FIELD_SEP" read -r SESSION_ID CWD PROMPT MESSAGE TRANSCRIPT <<EOF
$(printf '%s' "$INPUT" | jq -r '
    # Must use \x00-\x1f here: jq/Oniguruma does not read a \uNNNN escape
    # as a codepoint inside a bracket range, and would instead match the
    # literal characters u, 0-1 and f - silently mangling ids and prompts.
    def clean: (. // "") | tostring | gsub("[\\x00-\\x1f]"; " ");
    [ (.session_id | clean),
      (.cwd | clean),
      (.prompt | clean | .[0:200]),
      (.message | clean | .[0:200]),
      (.transcript_path | clean)
    ] | join("\u001f")' 2>/dev/null)
EOF

# Without a session_id we cannot key state - bail out silently.
# The id becomes a filename, so reject anything that could escape STATE_DIR.
case "$SESSION_ID" in
    ''|*[!A-Za-z0-9_-]*) exit 0 ;;
esac

[ -z "$CWD" ] && CWD="$PWD"
PROJECT=$(basename "$CWD")

STATE_FILE="${STATE_DIR}/${SESSION_ID}.json"
TMP_FILE="${STATE_FILE}.tmp.$$"
LOCK_DIR="${STATE_FILE}.lock"
NOW=$(date +%s)

cleanup() { rm -f "$TMP_FILE" 2>/dev/null; rmdir "$LOCK_DIR" 2>/dev/null; }
trap cleanup EXIT

# Serialize the read-modify-write. Two hooks for the same session (a
# Notification and a Stop arriving together) would otherwise both read the old
# document and the second mv would silently discard the first one's update,
# leaving the session stuck on "working" forever.
acquire_lock() {
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        mkdir "$LOCK_DIR" 2>/dev/null && return 0
        # Reclaim a lock orphaned by a killed hook
        if [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
            rmdir "$LOCK_DIR" 2>/dev/null
        fi
        sleep 0.05
    done
    return 1
}

if [ "$EVENT" = "session_end" ]; then
    rm -f "$STATE_FILE" 2>/dev/null
    [ -n "$TMUX" ] && tmux refresh-client -S 2>/dev/null
    exit 0
fi

case "$EVENT" in
    session_start|prompt_submit|stop|notification) ;;
    *) exit 0 ;;
esac

acquire_lock || exit 0

# Read existing state if any (so we can preserve started_at / first_prompt)
EXISTING="{}"
if [ -f "$STATE_FILE" ]; then
    EXISTING=$(cat "$STATE_FILE" 2>/dev/null || printf '{}')
    # A corrupt file must not make this session permanently un-updatable
    printf '%s' "$EXISTING" | jq -e . >/dev/null 2>&1 || EXISTING="{}"
fi

# Claude's closing reply, for the sidebar's "what did it finish with" line.
# tail -c can cut the first line mid-JSON, so drop it with tail -n +2.
LAST_REPLY=""
if [ "$EVENT" = "stop" ] && [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    LAST_REPLY=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null | tail -n +2 | \
        jq -r 'select(.type == "assistant")
               | [.message.content[]? | select(.type == "text") | .text]
               | join(" ")
               | gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "")
               | .[0:200]' 2>/dev/null | \
        grep -v '^$' | tail -1)
fi

# Where this Claude is running inside tmux. Recorded here (rather than in a
# second read-modify-write pass) so the whole document is written atomically.
# Queried one field at a time: tmux escapes non-printing characters in -p/-F
# output (\037 etc.), so a US-separated single call cannot be split reliably
# when a session name contains one.
T_SESSION=""; T_WINDOW=""; T_PANE_INDEX=""
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
    T_SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}' 2>/dev/null)
    T_WINDOW=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}' 2>/dev/null)
    T_PANE_INDEX=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_index}' 2>/dev/null)
fi

# Single write covering state, transcript path and tmux location.
printf '%s' "$EXISTING" | jq \
    --arg event "$EVENT" \
    --arg sid "$SESSION_ID" \
    --arg cwd "$CWD" \
    --arg project "$PROJECT" \
    --arg prompt "$PROMPT" \
    --arg msg "$MESSAGE" \
    --arg reply "$LAST_REPLY" \
    --arg tp "$TRANSCRIPT" \
    --arg tsess "$T_SESSION" \
    --arg twin "$T_WINDOW" \
    --arg tpane "${TMUX_PANE:-}" \
    --arg tpidx "$T_PANE_INDEX" \
    --argjson now "$NOW" '
    . as $prev
    | . + {
        session_id: $sid,
        cwd: $cwd,
        project: $project,
        updated_at: $now,
        started_at: (
            # Coerce: a non-numeric started_at from an older/corrupt file used
            # to abort the whole update via --argjson
            if ($prev.started_at | type) == "number" then $prev.started_at else $now end
        )
      }
    | if $event == "session_start" then
          . + {status: "idle", last_idle_at: $now}
      elif $event == "prompt_submit" then
          . + {status: "working", last_prompt: $prompt}
          | .first_prompt = (if ($prev.first_prompt // "") == "" then $prompt
                             else $prev.first_prompt end)
      elif $event == "stop" then
          . + {status: "idle", last_reply: $reply, last_idle_at: $now}
      else
          . + {status: "waiting", last_notification: $msg}
      end
    | if $tp != "" then . + {transcript_path: $tp} else . end
    | if $tsess != "" then
          . + {tmux_session: $tsess, tmux_window: $twin,
               tmux_pane: $tpane, tmux_pane_index: $tpidx}
      else . end
    ' > "$TMP_FILE" 2>/dev/null

# Promote only a file that actually parses. `[ -s ]` alone would install a
# partially-written document (jq killed mid-flush, ENOSPC), and one unparsable
# state file blanks the sidebar for every session.
if jq -e . "$TMP_FILE" >/dev/null 2>&1; then
    mv "$TMP_FILE" "$STATE_FILE" 2>/dev/null
fi
cleanup
trap - EXIT

# Refresh the tmux status-right Claude segment immediately
[ -n "$TMUX" ] && tmux refresh-client -S 2>/dev/null

# Surface input-waiting (permission prompts etc.) in macOS Notification Center.
# Data is passed as argv (on run argv), so quotes in the message cannot inject.
# Disable with CLAUDE_NOTIFY_DISABLED=1
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
