#!/usr/bin/env bash
set -euo pipefail

if [ -n "${_TMUX_WS_LOG_SOURCED:-}" ]; then return 0; fi
_TMUX_WS_LOG_SOURCED=1

TMUX_WS_LOG="${TMUX_WS_LOG:-}"
TMUX_WS_LOG_FILE=""

log_init() {
    local dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-ws"
    mkdir -p "$dir"
    TMUX_WS_LOG_FILE="$dir/load-$(date +%Y%m%d-%H%M%S).log"
    exec 8>>"$TMUX_WS_LOG_FILE"
    echo "=== tmux-ws log $(date) ===" >&8
    echo "--- env: TMUX=${TMUX:-} SCRIPT_DIR=${SCRIPT_DIR:-unknown} ---" >&8
}

log_debug() {
    [ -z "${TMUX_WS_LOG:-}" ] && return
    [ -z "$TMUX_WS_LOG_FILE" ] && log_init
    echo "$(date +%H:%M:%S) $*" >&8
}

log_path() {
    [ -z "${TMUX_WS_LOG:-}" ] && return
    [ -z "$TMUX_WS_LOG_FILE" ] && log_init
    echo "$TMUX_WS_LOG_FILE"
}
