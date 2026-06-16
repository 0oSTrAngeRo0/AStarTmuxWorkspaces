#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"

cmd_save() {
    local target_dir="${1:-$(pwd)}"

    [ -n "${TMUX:-}" ] || die "must be run inside a tmux session"

    local session abs file
    session=$(tmux display -p '#{session_name}')
    abs=$(resolve "$target_dir")
    file="$STORE_DIR/$(hash_path "$abs")"

    mkdir -p "$STORE_DIR"

    local pane_base
    pane_base=$(tmux display -p '#{pane-base-index}')

    {
        echo "session $session"
        echo "path $abs"
        echo "pane-base-index $pane_base"

        while IFS='|' read -r w_idx w_name w_layout w_active; do
            local aflag=""
            [ "$w_active" = "1" ] && aflag=" active"
            echo "window $w_idx $w_name$aflag"
            echo "layout $w_layout"

            while IFS='|' read -r p_idx p_path p_start p_cur p_pid; do
                local pane_cmd=""
                if [ -n "$p_start" ]; then
                    local cleaned
                    cleaned=$(clean_cmd "$p_start")
                    is_shell "$cleaned" || pane_cmd="$cleaned"
                elif [ "$p_cur" = "tmux" ]; then
                    pane_cmd=$(lookup_app "$p_pid")
                elif ! is_shell "$p_cur"; then
                    pane_cmd="$p_cur"
                fi

                if [ -n "$pane_cmd" ]; then
                    echo "pane $p_idx $p_path $pane_cmd"
                else
                    echo "pane $p_idx $p_path"
                fi
            done < <(tmux list-panes -t ":$w_idx" \
                -F '#{pane_index}|#{pane_current_path}|#{pane_start_command}|#{pane_current_command}|#{pane_pid}')
        done < <(tmux list-windows \
            -F '#{window_index}|#{window_name}|#{window_layout}|#{window_active}')
    } > "$file"

    echo "Saved: $session -> $file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced by ${SCRIPT}.sh"
    exit 1
fi
