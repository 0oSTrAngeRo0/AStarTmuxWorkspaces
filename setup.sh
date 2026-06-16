#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"

BASHRC="$HOME/.bashrc"
MARKER="# tws"

backup_bashrc() {
    local ts backup
    ts=$(date +%Y%m%d%H%M%S)
    backup="$HOME/.bashrc.backup.$ts"
    if [ -f "$BASHRC" ]; then
        cp "$BASHRC" "$backup"
        echo "Backed up: $backup"
    fi
}

cmd_install() {
    local do_backup=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --backup)    do_backup="yes"; shift;;
            --no-backup) do_backup="no"; shift;;
            *)           die "unknown option for install: $1";;
        esac
    done

    if [ -z "$do_backup" ]; then
        read -r -p "Backup ~/.bashrc before making changes? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS]) do_backup="yes";;
            *)                 do_backup="no";;
        esac
    fi

    if [ "$do_backup" = "yes" ]; then
        backup_bashrc
    fi

    sed -i "/$MARKER/d" "$BASHRC" 2>/dev/null || true
    touch "$BASHRC"

    echo "alias tmux-workspaces='$SCRIPT_DIR/tmux-workspaces.sh'  $MARKER" >> "$BASHRC"
    echo "alias tws='tmux-workspaces'                            $MARKER" >> "$BASHRC"

    echo "Aliases added to $BASHRC"
    echo "Run 'source ~/.bashrc' or open a new terminal to use them."
}

cmd_uninstall() {
    local do_backup=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --backup)    do_backup="yes"; shift;;
            --no-backup) do_backup="no"; shift;;
            *)           die "unknown option for uninstall: $1";;
        esac
    done

    if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        echo "No $SCRIPT aliases found in $BASHRC"
        exit 0
    fi

    if [ -z "$do_backup" ]; then
        read -r -p "Backup ~/.bashrc before making changes? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS]) do_backup="yes";;
            *)                 do_backup="no";;
        esac
    fi

    if [ "$do_backup" = "yes" ]; then
        backup_bashrc
    fi
    sed -i "/$MARKER/d" "$BASHRC"

    echo "Aliases removed from $BASHRC"
    echo "Run 'source ~/.bashrc' or open a new terminal."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        install|setup)    shift; cmd_install "$@";;
        uninstall|remove) shift; cmd_uninstall "$@";;
        help|-h|--help)
            echo "Usage: $(basename "$0") {install|uninstall} [--backup|--no-backup]"
            ;;
        *) cmd_install "$@";;
    esac
fi
