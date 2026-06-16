#!/usr/bin/env bash
set -euo pipefail

if [ -n "${_TMUX_WS_UTILS_SOURCED:-}" ]; then return 0; fi
_TMUX_WS_UTILS_SOURCED=1

SCRIPT="tmux-workspaces"
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
SHELL_NAMES="bash zsh fish sh dash tcsh csh ksh mksh tmux"

die() { echo "Error: $*" >&2; exit 1; }

hash_path() { echo -n "$1" | sha256sum | cut -c1-16; }

resolve() {
    local d="${1:-$(pwd)}"
    realpath -q "$d" 2>/dev/null || { pushd "$d" >/dev/null && pwd && popd >/dev/null; }
}

is_shell() {
    local c
    c=$(basename "$1")
    for s in $SHELL_NAMES; do [ "$c" = "$s" ] && return 0; done
    return 1
}

clean_cmd() { sed 's/^"//;s/"$//' <<< "$1"; }

lookup_app() {
    local ppid="$1" depth="${2:-0}"
    [ "$depth" -gt 3 ] && return 1
    local child_pid child_comm found
    for child_pid in $(ps -o pid= --ppid "$ppid" 2>/dev/null); do
        [ -z "$child_pid" ] && continue
        child_comm=$(ps -o comm= -p "$child_pid" 2>/dev/null)
        [ -z "$child_comm" ] && continue
        is_shell "$child_comm" && continue
        [ "$child_comm" = "tmux" ] && continue
        echo "$child_comm"
        return 0
    done
    for child_pid in $(ps -o pid= --ppid "$ppid" 2>/dev/null); do
        [ -z "$child_pid" ] && continue
        found=$(lookup_app "$child_pid" $((depth + 1)))
        [ -n "$found" ] && { echo "$found"; return 0; }
    done
    return 1
}
