#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"

cmd_load() {
    local target_dir="${1:-$(pwd)}"

    local abs file session
    abs=$(resolve "$target_dir")
    file="$STORE_DIR/$(hash_path "$abs")"

    [ -f "$file" ] || die "no workspace for $abs (looked: $file)"

    session="$abs"
    local pane_base; pane_base=$(grep '^pane-base-index ' "$file" | head -1 | awk '{print $2}')
    pane_base="${pane_base:-0}"

    if tmux has-session -t "=$session" 2>/dev/null; then
        echo "Session '$session' already exists."
        read -r -p "(a)ttach or (s)kip? [a/s] " choice
        case "$choice" in
            a|A|attach)
                    [ -n "${TMUX:-}" ] && tmux switch-client -t "$session" || tmux attach -t "$session"
                    exit 0;;
            *) echo "To attach later:  tmux attach -t $session"; exit 0;;
        esac
    fi

    local cur_win="" cur_name="" cur_layout="" cur_active=""
    local is_first=1  pane_n=0
    local active_win=""

    while IFS= read -r line; do
        case "$line" in
        session*|path*|"#"*|"") continue ;;
        window*)
            if [ -n "$cur_layout" ] && [ -n "$cur_win" ]; then
                tmux select-layout -t "$cur_win" "$cur_layout"
            fi
            cur_name=$(echo "$line" | awk '{print $3}')
            cur_active=$(echo "$line" | awk '{print $4}')
            pane_n=0
            ;;
        layout*)
            cur_layout=$(echo "$line" | cut -d' ' -f2-)
            ;;
        pane-base-index*) continue ;;
        pane*)
            local p_cwd p_cmd
            p_cwd=$(echo "$line" | awk '{print $3}')
            p_cmd=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf "%s%s", $i, (i==NF?"":" ")}')
            pane_n=$((pane_n + 1))

            if [ $is_first -eq 1 ] && [ $pane_n -eq 1 ]; then
                cur_win=$(tmux new-session -d -P -F '#{window_id}' \
                    -s "$session" -n "$cur_name" -c "$p_cwd" $p_cmd)
                tmux set-option -t "$session" pane-base-index "$pane_base"
                [ "$cur_active" = "active" ] && active_win="$cur_win"
            elif [ $is_first -eq 1 ]; then
                tmux split-window -t "$cur_win" -v -c "$p_cwd" $p_cmd
            elif [ $pane_n -eq 1 ]; then
                cur_win=$(tmux new-window -d -P -F '#{window_id}' \
                    -t "$session:" -n "$cur_name" -c "$p_cwd" $p_cmd)
                [ "$cur_active" = "active" ] && active_win="$cur_win"
            else
                tmux split-window -t "$cur_win" -v -c "$p_cwd" $p_cmd
            fi

            [ $is_first -eq 1 ] && [ $pane_n -eq 1 ] && is_first=0
            ;;
        esac
    done < "$file"

    if [ -n "$cur_layout" ] && [ -n "$cur_win" ]; then
        tmux select-layout -t "$cur_win" "$cur_layout"
    fi

    [ -n "$active_win" ] && tmux select-window -t "$active_win"

    if [ -n "${TMUX:-}" ]; then
        tmux switch-client -t "$session"
    else
        tmux attach -t "$session"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced by ${SCRIPT}.sh"
    exit 1
fi
