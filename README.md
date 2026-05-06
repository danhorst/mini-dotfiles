# dotfiles

Personal dotfiles for macOS.

## What's included

- **Shell** — zsh config, 40+ git/utility aliases, `fzf` with `ripgrep` and `bat` previews
- **Terminal** — Ghostty config, `tmux` (Ctrl-Space prefix, mouse, Alt-arrow panes), vi-mode `inputrc`
- **Editor** — `vim`, Zed, VS Code
- **Git** — `delta` and `difftastic` for diffs, comprehensive aliases including branch cleanup helpers
- **Runtimes** — `mise` managing NodeJS, Python, and Ruby; `rbenv` and `nvm` in Lima VMs
- **Local dev infrastructure** — `caddy` for local HTTPS reverse proxy, `unbound` for `.test` DNS resolution, Power Nap disabled for stable Continuity/Universal Control
- **Claude Code** — settings and tool preferences (`ast-grep`, `sd`, `yq`)
- **Homebrew** — Brewfile with formulae and casks for the full environment

## Prerequisites

- macOS
- [Homebrew](https://brew.sh)
- [1Password](https://1password.com) — used as the SSH agent; the SSH config expects the 1Password socket

## Installation

```sh
./install.sh
```

The script will:

1. Ensure Xcode command-line tools are installed
2. Symlink files from `shell/` into `$HOME`
3. Symlink `bin/` to `$HOME/.bin`
4. Run `brew bundle` to install packages
5. Install Rust and key crates (`bat`, `fd`, `git-delta`, `ripgrep`)
6. Set up the Lima VM directory and config
7. Symlink Claude Code config into `$HOME/.claude/`
8. Configure `unbound` for `.test` DNS (writes to `/etc/resolver/test`)
9. Install the `caddy` sudoers file for port 443 access
10. Disable Power Nap via `pmset` (fixes Continuity/Universal Control disconnections)

Pass `-f` to force re-running steps that would otherwise be skipped.

## Layout

| Path            | Contents                                                                       |
| --------------- | ------------------------------------------------------------------------------ |
| `shell/`        | Dotfiles symlinked into `$HOME` (zshrc, gitconfig, tmux.conf, etc.)            |
| `shell/config/` | XDG config files symlinked into `$HOME/.config` (ghostty, zed, mise, gh, etc.) |
| `bin/`          | Personal utility scripts                                                       |
| `claude/`       | Claude Code settings and CLAUDE.md                                             |
| `caddy/`        | Sudoers file for `caddy`                                                       |
| `unbound/`      | Local DNS config for `.test` domain                                            |
| `lima/`         | Lima VM config and setup scripts                                               |
| `Brewfile`      | Homebrew bundle manifest                                                       |
