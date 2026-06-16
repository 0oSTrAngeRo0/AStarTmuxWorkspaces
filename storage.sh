#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
STORE_DIR="${TMUX_WS_STORE_DIR:-$SCRIPT_DIR/tmux-ws-storage}"

cmd_export() {
    local outfile="${1:-tmux-ws-storage-$(date +%Y%m%d%H%M%S).tar.gz}"

    if [ ! -d "$STORE_DIR" ] || [ -z "$(ls -A "$STORE_DIR" 2>/dev/null)" ]; then
        echo "No workspace data to export."
        exit 0
    fi

    tar -czf "$outfile" -C "$SCRIPT_DIR" "$(basename "$STORE_DIR")"
    echo "Exported: $outfile"
}

cmd_import() {
    local infile="${1:-}"

    if [ -z "$infile" ]; then
        local latest
        latest=$(ls -t tmux-ws-storage-*.tar.gz 2>/dev/null | head -1)
        if [ -z "$latest" ]; then
            echo "No archive found. Usage: $(basename "$0") import <file.tar.gz>"
            exit 1
        fi
        infile="$latest"
    fi

    if [ ! -f "$infile" ]; then
        echo "File not found: $infile"
        exit 1
    fi

    if [ -d "$STORE_DIR" ] && [ -n "$(ls -A "$STORE_DIR" 2>/dev/null)" ]; then
        local ts backup
        ts=$(date +%Y%m%d%H%M%S)
        backup="tmux-ws-storage.backup.$ts"
        mv "$STORE_DIR" "$backup"
        echo "Existing storage backed up: $backup"
    fi

    mkdir -p "$(dirname "$STORE_DIR")"
    tar -xzf "$infile" -C "$SCRIPT_DIR"
    echo "Imported from: $infile"
}

case "${1:-}" in
    export|e) cmd_export "${2:-}";;
    import|i) cmd_import "${2:-}";;
    help|-h|--help)
        echo "Usage: $(basename "$0") <command> [file]"
        echo "  export [file]  Export workspace data to a tar.gz archive"
        echo "  import [file]  Import workspace data from a tar.gz archive"
        ;;
    *)
        echo "Usage: $(basename "$0") {export|import} [file]"
        exit 1
        ;;
esac
