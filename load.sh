#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"

cmd_load() {
    local target_dir="${1:-$(pwd)}"

    local abs file session
    abs=$(resolve "$target_dir")
    file="$STORE_DIR/$(hash_path "$abs")"

    log_debug "load: target_dir=$target_dir abs=$abs file=$file"

    [ -f "$file" ] || die "no workspace for $abs (looked: $file)"

    session="$abs"
    log_debug "load: session=$session"
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
    local line_n=0

    while IFS= read -r line; do
        line_n=$((line_n + 1))
        log_debug "  L$line_n: $line"
        case "$line" in
        session*|path*|"#"*|"")
            log_debug "  L$line_n: -> skip (meta/comment/empty)"
            continue ;;
        window*)
            if [ -n "$cur_layout" ] && [ -n "$cur_win" ]; then
                log_debug "  L$line_n: -> select-layout -t $cur_win $cur_layout"
                tmux select-layout -t "$cur_win" "$cur_layout"
            fi
            cur_name=$(echo "$line" | awk '{print $3}')
            cur_active=$(echo "$line" | awk '{print $4}')
            log_debug "  L$line_n: -> window name='$cur_name' active='$cur_active' pane_n=0"
            pane_n=0
            ;;
        layout*)
            cur_layout=$(echo "$line" | cut -d' ' -f2-)
            log_debug "  L$line_n: -> layout='$cur_layout'"
            ;;
        pane-base-index*)
            log_debug "  L$line_n: -> skip (pane-base-index already read)"
            continue ;;
        pane*)
            local p_cwd p_cmd
            p_cwd=$(echo "$line" | awk '{print $3}')
            p_cmd=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf "%s%s", $i, (i==NF?"":" ")}')
            pane_n=$((pane_n + 1))
            log_debug "  L$line_n: -> pane n=$pane_n is_first=$is_first cwd='$p_cwd' cmd='$p_cmd' cur_win=$cur_win cur_name='$cur_name' cur_active='$cur_active'"

            if [ $is_first -eq 1 ] && [ $pane_n -eq 1 ]; then
                log_debug "  L$line_n:    exec: new-session -s '$session' -n '$cur_name' -c '$p_cwd' $p_cmd"
                cur_win=$(tmux new-session -d -P -F '#{window_id}' \
                    -s "$session" -n "$cur_name" -c "$p_cwd" $p_cmd)
                log_debug "  L$line_n:    -> cur_win=$cur_win"
                tmux set-option -t "$session" pane-base-index "$pane_base"
                [ "$cur_active" = "active" ] && active_win="$cur_win"
            elif [ $is_first -eq 1 ]; then
                log_debug "  L$line_n:    exec: split-window -t '$cur_win' -v -c '$p_cwd' $p_cmd"
                tmux split-window -t "$cur_win" -v -c "$p_cwd" $p_cmd
            elif [ $pane_n -eq 1 ]; then
                log_debug "  L$line_n:    exec: new-window -t '$session:' -n '$cur_name' -c '$p_cwd' $p_cmd"
                cur_win=$(tmux new-window -d -P -F '#{window_id}' \
                    -t "$session:" -n "$cur_name" -c "$p_cwd" $p_cmd)
                log_debug "  L$line_n:    -> cur_win=$cur_win"
                [ "$cur_active" = "active" ] && active_win="$cur_win"
            else
                log_debug "  L$line_n:    exec: split-window -t '$cur_win' -v -c '$p_cwd' $p_cmd"
                tmux split-window -t "$cur_win" -v -c "$p_cwd" $p_cmd
            fi

            [ $is_first -eq 1 ] && [ $pane_n -eq 1 ] && is_first=0
            log_debug "  L$line_n:    after: is_first=$is_first active_win=$active_win"
            ;;
        esac
    done < "$file"

    log_debug "load: loop finished, final cur_win=$cur_win cur_layout='$cur_layout' active_win=$active_win"

    if [ -n "$cur_layout" ] && [ -n "$cur_win" ]; then
        log_debug "load: select-layout -t $cur_win $cur_layout"
        tmux select-layout -t "$cur_win" "$cur_layout"
    fi

    [ -n "$active_win" ] && tmux select-window -t "$active_win"
    log_debug "load: select-window active_win=$active_win"

    if [ -n "${TMUX:-}" ]; then
        log_debug "load: switch-client -t '$session'"
        tmux switch-client -t "$session"
    else
        log_debug "load: attach -t '$session'"
        tmux attach -t "$session"
    fi
    log_debug "load: done"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced by ${SCRIPT}.sh"
    exit 1
fi
