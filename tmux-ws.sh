#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
SCRIPT="tmux-ws.sh"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

SHELL_NAMES="bash zsh fish sh dash tcsh csh ksh mksh"

die() { echo "Error: $*" >&2; exit 1; }

store_dir() {
    if   [ -n "${ARG_STORE_DIR:-}" ]; then  echo "$ARG_STORE_DIR"
    elif [ -n "${TMUX_WS_DIR:-}" ];     then  echo "$TMUX_WS_DIR"
    else                                     echo "$SCRIPT_DIR/tmux-ws-storage"
    fi
}

hash_path() { echo -n "$1" | sha256sum | cut -c1-16; }

resolve() {
    local d="${1:-$(pwd)}"
    realpath -q "$d" 2>/dev/null || { pushd "$d" >/dev/null && pwd && popd >/dev/null; }
}

is_shell() {
    local c="$1"
    for s in $SHELL_NAMES; do [ "$c" = "$s" ] && return 0; done
    return 1
}

clean_cmd() { sed 's/^"//;s/"$//' <<< "$1"; }

# ── save ─────────────────────────────────────────────────────────────────────

cmd_save() {
    local target_dir="" store=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --store-dir) store="$2"; shift 2;;
            *) target_dir="$1"; shift;;
        esac
    done

    [ -n "${TMUX:-}" ] || die "must be run inside a tmux session"

    export ARG_STORE_DIR="${store:-$(store_dir)}"
    local session abs file
    session=$(tmux display -p '#{session_name}')
    abs=$(resolve "$target_dir")
    file="$(store_dir)/$(hash_path "$abs")"

    mkdir -p "$(store_dir)"

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

            while IFS='|' read -r p_idx p_path p_start p_cur; do
                if [ -z "$p_start" ] && ! is_shell "$p_cur"; then
                    echo "pane $p_idx $p_path $p_cur"
                elif [ -z "$p_start" ] || is_shell "$p_cur"; then
                    echo "pane $p_idx $p_path"
                else
                    echo "pane $p_idx $p_path $(clean_cmd "$p_start")"
                fi
            done < <(tmux list-panes -t ":$w_idx" \
                -F '#{pane_index}|#{pane_current_path}|#{pane_start_command}|#{pane_current_command}')
        done < <(tmux list-windows \
            -F '#{window_index}|#{window_name}|#{window_layout}|#{window_active}')
    } > "$file"

    echo "Saved: $session -> $file"
}

# ── load ─────────────────────────────────────────────────────────────────────

cmd_load() {
    local target_dir="" store=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --store-dir) store="$2"; shift 2;;
            *) target_dir="$1"; shift;;
        esac
    done

    export ARG_STORE_DIR="${store:-$(store_dir)}"
    local abs file session
    abs=$(resolve "$target_dir")
    file="$(store_dir)/$(hash_path "$abs")"

    [ -f "$file" ] || die "no workspace for $abs (looked: $file)"

    session=$(grep '^session ' "$file" | head -1 | awk '{print $2}')
    local pane_base; pane_base=$(grep '^pane-base-index ' "$file" | head -1 | awk '{print $2}')
    pane_base="${pane_base:-0}"

    if tmux has-session -t "=$session" 2>/dev/null; then
        echo "Session '$session' already exists."
        read -r -p "(a)ttach or (s)kip? [a/s] " choice
        case "$choice" in
            a|A|attach) tmux attach -t "$session"; exit 0;;
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

    tmux attach -t "$session"
}

# ── list ─────────────────────────────────────────────────────────────────────

cmd_list() {
    local store=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --store-dir) store="$2"; shift 2;;
            *) shift;;
        esac
    done
    export ARG_STORE_DIR="${store:-$(store_dir)}"
    local d; d="$(store_dir)"
    [ -d "$d" ] || { echo "(empty)"; exit 0; }

    local count=0
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        local s p
        s=$(grep '^session ' "$f" | head -1 | awk '{print $2}')
        p=$(grep '^path ' "$f" | head -1 | awk '{$1=""; print substr($0,2)}')
        printf "%-20s %s\n" "$s" "$p"
        count=$((count + 1))
    done
    [ "$count" -eq 0 ] && echo "(empty)"
}

# ── delete ───────────────────────────────────────────────────────────────────

cmd_delete() {
    local target_dir="" store=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --store-dir) store="$2"; shift 2;;
            *) target_dir="$1"; shift;;
        esac
    done

    export ARG_STORE_DIR="${store:-$(store_dir)}"
    local abs file
    abs=$(resolve "$target_dir")
    file="$(store_dir)/$(hash_path "$abs")"

    [ -f "$file" ] || die "no workspace for $abs"
    rm "$file"
    echo "Deleted: $abs"
}

# ── help ─────────────────────────────────────────────────────────────────────

cmd_help() {
    cat <<EOF
$SCRIPT  v$VERSION  —  tmux workspace manager

Usage:  $SCRIPT <command> [--store-dir <dir>] [directory]

Commands:
  save  [dir]     Save current tmux session layout
  load  [dir]     Load a saved workspace
  list            List all saved workspaces
  delete [dir]    Delete a saved workspace
  help            Show this message

Options:
  --store-dir <dir>   Storage directory (default: script dir/tmux-ws-storage,
                       env: \$TMUX_WS_DIR)

If [dir] is omitted, current working directory is used.

Examples:
  $SCRIPT save                      save current session for pwd
  $SCRIPT save ~/projects/foo       save with explicit path
  $SCRIPT load                      load workspace for pwd
  $SCRIPT load ~/projects/foo       load workspace for specific path
  $SCRIPT --store-dir ~/.ws save    save to custom store
  $SCRIPT list                      show all saved workspaces
EOF
}

# ── main ─────────────────────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
    case "$1" in
        --store-dir) export ARG_STORE_DIR="$2"; shift 2;;
        -*) die "unknown option: $1";;
        *)  break;;
    esac
done

cmd="${1:-help}"
shift || true

case "$cmd" in
    save|s)         cmd_save "$@";;
    load|l)         cmd_load "$@";;
    list|ls)        cmd_list "$@";;
    delete|rm|d|del) cmd_delete "$@";;
    help|h|-h|--help) cmd_help;;
    *)              die "unknown command: $cmd\nRun '$SCRIPT help'."
esac
