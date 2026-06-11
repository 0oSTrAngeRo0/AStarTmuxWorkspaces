# tmux-ws

A lightweight tmux workspace manager. Save and restore tmux session layouts keyed by directory path — windows, panes, splits, working directories, and running commands are all preserved.

## Requirements

- [tmux](https://github.com/tmux/tmux)
- bash
- `sha256sum` and `realpath` (standard on Linux/macOS)

## Installation

```bash
curl -O https://raw.githubusercontent.com/<user>/tmux-ws/main/tmux-ws.sh
chmod +x tmux-ws.sh
```

Optionally, symlink or move it into your `$PATH`:

```bash
ln -s "$(pwd)/tmux-ws.sh" ~/.local/bin/tmux-ws
```

## Usage

```
tmux-ws.sh <command> [--store-dir <dir>] [directory]
```

If `[directory]` is omitted, the current working directory is used.

### Commands

| Command | Aliases | Description |
|---------|---------|-------------|
| `save` | `s` | Save the current tmux session layout for a directory |
| `load` | `l` | Restore a previously saved workspace |
| `list` | `ls` | List all saved workspaces |
| `delete` | `rm`, `d`, `del` | Delete a saved workspace |
| `help` | `h`, `-h`, `--help` | Show usage information |

### Configuration

| Method | Description |
|--------|-------------|
| `--store-dir <path>` | Per-command override for the storage directory |
| `TMUX_WS_DIR` | Environment variable for a persistent custom storage directory |
| *(default)* | `tmux-ws-storage/` next to the script |

Priority: `--store-dir` > `$TMUX_WS_DIR` > default.

## Examples

```bash
# Save the current session for the working directory
tmux-ws.sh save

# Save with an explicit path
tmux-ws.sh save ~/projects/myapp

# List all saved workspaces
tmux-ws.sh list

# Restore a workspace
tmux-ws.sh load ~/projects/myapp

# Use a custom storage directory
tmux-ws.sh --store-dir ~/.tmux-workspaces save

# Delete a workspace
tmux-ws.sh delete ~/projects/myapp
```

## How It Works

A workspace snapshot is identified by hashing the absolute directory path with SHA-256 (first 16 hex characters). Snapshots are plain-text files stored in the storage directory.

On **save**, the script captures:
- Session name
- Window names, indices, and layout strings
- Per-pane: working directory, start command, and current command
- Shell panes (bash, zsh, etc.) are saved without a command so they spawn a fresh shell on restore

On **load**, the script recreates the session by issuing `tmux new-session`, `tmux split-window`, `tmux new-window`, `tmux select-layout`, and `tmux select-window` commands, then attaches to the restored session.

## License

MIT
