#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"

cmd_export() {
    local outfile
    outfile="${1:-storage-$(date +%Y%m%d%H%M%S).tar.gz}"

    if [ ! -d "$STORE_DIR" ] || [ -z "$(ls -A "$STORE_DIR" 2>/dev/null)" ]; then
        echo "No workspace data to export."
        exit 0
    fi

    tar -czf "$outfile" -C "$(dirname "$STORE_DIR")" "$(basename "$STORE_DIR")"
    echo "Exported: $outfile"
}

cmd_import() {
    local infile
    infile="${1:-}"

    if [ -z "$infile" ]; then
        local latest
        latest=$(ls -t storage-*.tar.gz 2>/dev/null | head -1)
        if [ -z "$latest" ]; then
            echo "No archive found. Usage: $SCRIPT import <file.tar.gz>"
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
        backup="storage.backup.$ts"
        mv "$STORE_DIR" "$backup"
        echo "Existing storage backed up: $backup"
    fi

    mkdir -p "$(dirname "$STORE_DIR")"
    tar -xzf "$infile" -C "$(dirname "$STORE_DIR")"
    echo "Imported from: $infile"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        export|e) cmd_export "${2:-}";;
        import|i) cmd_import "${2:-}";;
        help|-h|--help)
            echo "Usage: $(basename "$0") {export|import} [file]"
            ;;
        *)
            echo "Usage: $(basename "$0") {export|import} [file]"
            exit 1
            ;;
    esac
fi
