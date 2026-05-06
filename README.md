# Mac Mini Dotfiles

Personal dotfiles for MacOS. Supersedes [`dotfiles`][1]; designed to complement [`wrk`][2] and play nicely with [Tailscale][3].

## What's included

- **Shell** — `zsh` config, lots of `git`/productivity aliases, utilities including `fzf` with `ripgrep` and `bat` previews.
- **Terminal** — Simple [Ghostty][4] config, simplified `tmux` controls, and vi-mode `inputrc`
- **Editor** — `vim`, Zed, VS Code
- **Git** — comprehensive aliases including branch cleanup helpers, [`delta`][5] and [`difftastic`][6] for diffs, 
- **Runtimes** — `mise` managing NodeJS, Python, and Ruby; `rbenv` and `nvm` in Lima VMs
- **Local dev infrastructure** — [`caddy`][7] for local HTTPS reverse proxy, [`unbound`][8] for `.test` DNS resolution, Power Nap disabled for stable Continuity/Universal Control
- **Claude Code** — settings and tool preferences ([`ast-grep`][9], [`sd`][10], [`yq`][11])
- **Homebrew** — `Brewfile` with formulae and casks for the full environment

## Prerequisites

- MacOS
- [Homebrew][12]
- OPTIONAL: [1Password][13] for SSH key management; the SSH config expects the 1Password socket but falls back to a default SSH agent if 1Password is not present.

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

[1]: https://github.com/danhorst/dotfiles
[2]: https://github.com/danhorst/wrk
[3]: https://tailscale.com
[4]: https://ghostty.org
[5]: https://github.com/dandavison/delta
[6]: https://github.com/wilfred/difftastic
[7]: https://caddyserver.com
[8]: https://nlnetlabs.nl/projects/unbound/about/
[9]: https://ast-grep.github.io
[10]: https://github.com/chmln/sd
[11]: https://github.com/mikefarah/yq
[12]: https://brew.sh
[13]: https://1password.com
