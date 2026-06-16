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
    backup_bashrc

    local line="alias tws='$SCRIPT_DIR/tmux-workspaces.sh'  $MARKER"

    sed -i "/$MARKER/d" "$BASHRC" 2>/dev/null || true
    touch "$BASHRC"

    echo "$line" >> "$BASHRC"

    echo "Alias added to $BASHRC"
    echo "Run 'source ~/.bashrc' or open a new terminal to use it."
}

cmd_uninstall() {
    if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        echo "No $SCRIPT aliases found in $BASHRC"
        exit 0
    fi

    backup_bashrc
    sed -i "/$MARKER/d" "$BASHRC"

    echo "Aliases removed from $BASHRC"
    echo "Run 'source ~/.bashrc' or open a new terminal."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        install|setup) cmd_install;;
        uninstall|remove) cmd_uninstall;;
        help|-h|--help)
            echo "Usage: $(basename "$0") {install|uninstall}"
            ;;
        *) cmd_install;;
    esac
fi
