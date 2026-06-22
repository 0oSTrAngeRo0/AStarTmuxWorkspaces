# tmux-workspaces

A lightweight tmux workspace manager. Save and restore tmux session layouts keyed by directory path —
windows, panes, splits, working directories, and running commands are all preserved.

![Version](https://img.shields.io/badge/version-0.2.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Save & Load** — capture the full tmux session layout (windows, panes, splits, cwd, commands)
- **Directory-keyed** — workspaces are identified by hashed directory path, no manual naming
- **Shell aliases** — built-in install sets up `tmux-workspaces` and `tws` aliases
- **Export & Import** — tar.gz backup and restore for all workspace data
- **Custom storage** — override the storage directory via CLI option or environment variable

## Quick Start

```bash
git clone https://github.com/0oSTrAngeRo0/AStarTmuxWorkspaces.git
cd AStarTmuxWorkspaces
./tmux-workspaces.sh install --no-backup
source ~/.bashrc
tws save
```

## Requirements

- [tmux](https://github.com/tmux/tmux)
- bash
- `sha256sum` and `realpath` (standard on Linux/macOS)

## Installation

```bash
git clone https://github.com/0oSTrAngeRo0/AStarTmuxWorkspaces.git
cd AStarTmuxWorkspaces
./tmux-workspaces.sh install
```

This adds `tmux-workspaces` and `tws` aliases to your `~/.bashrc`. Run `source ~/.bashrc` or open a new terminal to use them.

Options:
- `--backup` — back up `~/.bashrc` before modifying
- `--no-backup` — skip the backup prompt

To remove the aliases, run `tws uninstall`.

## Command Reference

| Command    | Aliases          | Description                              |
|------------|------------------|------------------------------------------|
| `save`     | `s`              | Save the current tmux session layout     |
| `load`     | `l`              | Restore a previously saved workspace     |
| `list`     | `ls`             | List all saved workspaces                |
| `delete`   | `rm`, `d`, `del` | Delete a saved workspace                 |
| `install`  | `setup`          | Add aliases to `~/.bashrc`               |
| `uninstall`| `remove`         | Remove aliases from `~/.bashrc`          |
| `export`   | `e`              | Export workspace data to a tar.gz file   |
| `import`   | `i`              | Import workspace data from a tar.gz file |
| `help`     | `h`, `-h`, `--help` | Show usage information              |

All commands accept an optional directory argument (defaults to current working directory).

## Configuration

| Method                    | Description                                   |
|---------------------------|-----------------------------------------------|
| `--store-dir <path>`      | Per-command override for the storage directory |
| `TMUX_WS_DIR`             | Environment variable for a persistent custom storage directory |
| `--debug`                 | Enable debug logging for the current command (also settable via `TMUX_WS_LOG=1`) |
| *(default)*               | `storage/` next to the script                 |

Priority: `--store-dir` > `$TMUX_WS_DIR` > default.

## Debugging

Pass `--debug` or set `TMUX_WS_LOG=1` to enable detailed execution traces:

```bash
tws --debug load ~/projects/myapp
```

Logs are written to `~/.local/state/tmux-ws/load-YYYYMMDD-HHMMSS.log` (respects `$XDG_STATE_HOME`). The log captures every pane command issued, window and session creation steps, and layout application — useful for troubleshooting why a workspace didn't restore as expected.

## Examples

```bash
# Save the current session for the working directory
tws save

# Save with an explicit path
tws save ~/projects/myapp

# List all saved workspaces
tws list

# Restore a workspace
tws load ~/projects/myapp

# Use a custom storage directory
tws --store-dir ~/.tmux-workspaces save

# Delete a workspace
tws delete ~/projects/myapp

# Export all workspace data
tws export

# Import from a backup
tws import ~/backup.tar.gz
```

## Storage Management

Export and import workspace data directly through the main script:

```bash
tws export                        # creates storage-YYYYMMDDHHMMSS.tar.gz
tws import                        # imports the latest archive found
tws import ~/backup.tar.gz        # imports a specific archive
```

## How It Works

A workspace snapshot is identified by hashing the absolute directory path with SHA-256 (first 16 hex characters). Snapshots are plain-text files stored in the storage directory.

On **save**, the script captures:
- Session name
- Window names, indices, and layout strings
- Per-pane: working directory, start command, and current command
- Shell panes (bash, zsh, etc.) are saved without a start command so they spawn a fresh shell on restore
- Foreground applications (e.g., nvim, htop) are detected via process-tree inspection and saved with their full command line

On **load**, the script recreates the session by issuing `tmux new-session`, `tmux split-window`, `tmux new-window`, `tmux select-layout`, and `tmux select-window` commands, then attaches to the restored session.

## License

MIT — see [LICENSE](LICENSE)
