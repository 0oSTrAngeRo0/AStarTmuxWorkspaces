#!/usr/bin/env bash
set -euo pipefail

VERSION="0.2.0"

SD="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SD/utils.sh"
source "$SD/log.sh"
source "$SD/save.sh"
source "$SD/load.sh"
source "$SD/list.sh"
source "$SD/setup.sh"
source "$SD/storage.sh"

while [ $# -gt 0 ]; do
    case "$1" in
        --store-dir) ARG_STORE_DIR="$2"; shift 2;;
        --debug)     TMUX_WS_LOG=1; shift;;
        -*) die "unknown option: $1";;
        *)  break;;
    esac
done

export TMUX_WS_LOG="${TMUX_WS_LOG:-}"

if [ -n "${ARG_STORE_DIR:-}" ]; then
    STORE_DIR="$ARG_STORE_DIR"
elif [ -n "${TMUX_WS_DIR:-}" ]; then
    STORE_DIR="$TMUX_WS_DIR"
else
    STORE_DIR="$SCRIPT_DIR/storage"
fi
export STORE_DIR

cmd_help() {
    cat <<EOF
$SCRIPT  v$VERSION  —  tmux workspace manager

Usage:  $SCRIPT <command> [options] [arguments]

Commands:
  save     [dir]    Save current tmux session layout
  load     [dir]    Load a saved workspace
  list              List all saved workspaces
  delete   [dir]    Delete a saved workspace
  install           Add tws alias to ~/.bashrc
  uninstall         Remove tws alias from ~/.bashrc
  export   [file]   Export workspace data to a tar.gz archive
  import   [file]   Import workspace data from a tar.gz archive
  help              Show this message

Options:
  --store-dir <dir>   Storage directory (default: $SCRIPT_DIR/storage,
                        env: \$TMUX_WS_DIR)
  --debug             Enable debug logging (env: \$TMUX_WS_LOG)

If [dir] is omitted, current working directory is used.

Examples:
  $SCRIPT save                      save current session for pwd
  $SCRIPT save ~/projects/foo       save with explicit path
  $SCRIPT load                      load workspace for pwd
  $SCRIPT load ~/projects/foo       load workspace for specific path
  $SCRIPT --store-dir ~/.ws save    save to custom store
  $SCRIPT list                      show all saved workspaces
  $SCRIPT install                   add tws alias to ~/.bashrc
  $SCRIPT export                    export all workspace data
  $SCRIPT import ~/backup.tar.gz    import workspace data
EOF
}

cmd="${1:-help}"
shift || true

case "$cmd" in
    save|s)             cmd_save "$@";;
    load|l)             cmd_load "$@";;
    list|ls)            cmd_list "$@";;
    delete|rm|d|del)    cmd_delete "$@";;
    install|setup)      cmd_install "$@";;
    uninstall|remove)   cmd_uninstall "$@";;
    export|e)           cmd_export "$@";;
    import|i)           cmd_import "$@";;
    help|h|-h|--help)   cmd_help;;
    *)                  die "unknown command: $cmd\nRun '$SCRIPT help'."
esac
