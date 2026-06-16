#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"

cmd_list() {
    [ -d "$STORE_DIR" ] || { echo "(empty)"; exit 0; }

    local count=0
    for f in "$STORE_DIR"/*; do
        [ -f "$f" ] || continue
        local p
        p=$(grep '^path ' "$f" | head -1 | awk '{$1=""; print substr($0,2)}')
        printf "%s\n" "$p"
        count=$((count + 1))
    done
    [ "$count" -eq 0 ] && echo "(empty)"
}

cmd_delete() {
    local target_dir="${1:-$(pwd)}"

    local abs file
    abs=$(resolve "$target_dir")
    file="$STORE_DIR/$(hash_path "$abs")"

    [ -f "$file" ] || die "no workspace for $abs"
    rm "$file"
    echo "Deleted: $abs"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced by ${SCRIPT}.sh"
    exit 1
fi
