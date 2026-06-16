#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BASHRC="$HOME/.bashrc"
MARKER="# tmux-ws"

backup_bashrc() {
    local ts backup
    ts=$(date +%Y%m%d%H%M%S)
    backup="$HOME/.bashrc.backup.$ts"
    if [ -f "$BASHRC" ]; then
        cp "$BASHRC" "$backup"
        echo "Backed up: $backup"
    fi
}

cmd_setup() {
    backup_bashrc

    local lines=(
        "alias tmux-ws='$SCRIPT_DIR/tmux-ws.sh'          $MARKER"
        "alias tmux-ws-setup='$SCRIPT_DIR/setup.sh'      $MARKER"
        "alias tmux-ws-storage='$SCRIPT_DIR/storage.sh'  $MARKER"
    )

    sed -i "/$MARKER/d" "$BASHRC" 2>/dev/null || true
    touch "$BASHRC"

    for line in "${lines[@]}"; do
        echo "$line" >> "$BASHRC"
    done

    echo "Aliases added to $BASHRC"
    echo "Run 'source ~/.bashrc' or open a new terminal to use them."
}

cmd_uninstall() {
    if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        echo "No tmux-ws aliases found in $BASHRC"
        exit 0
    fi

    backup_bashrc
    sed -i "/$MARKER/d" "$BASHRC"

    echo "Aliases removed from $BASHRC"
    echo "Run 'source ~/.bashrc' or open a new terminal."
}

case "${1:-}" in
    uninstall|remove|rm) cmd_uninstall;;
    help|-h|--help)
        echo "Usage: $(basename "$0") [uninstall]"
        echo "  (no args)  Add tmux-ws aliases to ~/.bashrc"
        echo "  uninstall  Remove tmux-ws aliases from ~/.bashrc"
        ;;
    *) cmd_setup;;
esac
