# Mac Mini Dotfiles

Personal dotfiles for macOS, with a cross-platform core that also runs on Ubuntu/WSL.
Supersedes [`dotfiles`][1]; designed to complement [`wrk`][2] and play nicely with [Tailscale][3].

## What's included

- **Shell** — `zsh` config, lots of `git`/productivity aliases, utilities including `fzf` with `ripgrep` and `bat` previews.
- **Terminal** — Simple [Ghostty][4] config, simplified `tmux` controls, and vi-mode `inputrc`
- **Editor** — `vim`, Zed, VS Code
- **Git** — comprehensive aliases including branch cleanup helpers, [`delta`][5] and [`difftastic`][6] for diffs, 
- **Runtimes** — `mise` managing NodeJS, Python, and Ruby; `rbenv` and `nvm` in Lima VMs
- **Local dev infrastructure** — [`caddy`][7] for local HTTPS reverse proxy, [`unbound`][8] for `.test` DNS resolution, Power Nap disabled for stable Continuity/Universal Control
- **Claude Code** — settings and tool preferences ([`ast-grep`][9], [`sd`][10], [`yq`][11])
- **Homebrew** — split `Brewfile` (cross-platform core), `Brewfile.macos`, and `Brewfile.linux`

The cross-platform core (shell, CLI tools, `mise` runtimes, Claude Code) installs on both targets.
Linux/WSL intentionally omits the macOS-only layer: Caddy/Unbound/pf network infrastructure, Lima, GUI casks, Gatekeeper, Power Nap, and the macOS SSH/ShellFish setup.
Terminal config on Windows is handled by Windows Terminal, whose settings live on the Windows side and are not yet tracked here.

## Prerequisites

### macOS

- [Homebrew][12]
- OPTIONAL: [1Password][13] for SSH key management; the SSH config expects the 1Password socket but falls back to a default SSH agent if 1Password is not present.

### Ubuntu / WSL

- Nothing — `bootstrap.linux.sh` installs the apt prerequisites, [Linuxbrew][12], and zsh.

## Installation

### macOS

```sh
./install.sh
```

The orchestrator (`install.sh`) runs the cross-platform steps, then sources `install.macos.sh` for the macOS-only layer: symlink `shell/` into `$HOME`, set git hooks, symlink `bin/`, run `brew bundle` against `Brewfile` + `Brewfile.macos`, install `mise` tools, link Claude Code config, then Xcode CLT, Gatekeeper, Codex, Lima, Ghostty, Playwright, SSH keys, `unbound` `.test` DNS, `caddy`, `pf`, and Power Nap.

Pass `-b` to force a `brew bundle` (bypasses the 24h cache) and `-n` to reset the Unbound/Caddy/pf network configuration.

### Ubuntu / WSL

On a fresh machine, download and run the bootstrap (no need to install `git` yourself first):

```sh
curl -fsSL https://raw.githubusercontent.com/danhorst/dotfiles/main/bootstrap.linux.sh | bash
cd ~/git/danhorst/dotfiles && ./install.sh
```

`bootstrap.linux.sh` installs apt prerequisites, Linuxbrew, and zsh as the login shell, then clones this repo.
`install.sh` then runs the cross-platform steps and sources `install.linux.sh`.

## Layout

| Path                                    | Contents                                                                             |
| --------------------------------------- | ------------------------------------------------------------------------------------ |
| `shell/`                                | Dotfiles symlinked into `$HOME` (zshrc, gitconfig, tmux.conf, etc.)                  |
| `shell/config/`                         | Tracked XDG config files symlinked into `$HOME/.config` (mise, alacritty, 1Password) |
| `bin/`                                  | Personal utility scripts                                                             |
| `claude/`                               | Claude Code settings and CLAUDE.md                                                   |
| `caddy/`                                | Sudoers file for `caddy`                                                             |
| `unbound/`                              | Local DNS config for `.test` domain                                                  |
| `lima/`                                 | Lima VM config and setup scripts                                                     |
| `experiments/`                          | Self-contained research rigs (e.g. `sdd-bakeoff`); not deployed config               |
| `lib/`                                  | Shared shell helpers and platform detection (`common.sh`)                            |
| `install.sh`                            | Orchestrator; runs cross-platform steps then sources the platform script             |
| `install.macos.sh` / `install.linux.sh` | Platform-specific install steps                                                      |
| `bootstrap.linux.sh`                    | One-time Ubuntu/WSL prep (apt prereqs, Linuxbrew, zsh, clone)                        |
| `Brewfile`                              | Cross-platform Homebrew bundle; `Brewfile.macos` / `Brewfile.linux` add per-OS       |

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
