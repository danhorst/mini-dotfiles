#!/bin/bash
# One-time bootstrap for a fresh Ubuntu / WSL machine.
#
# Designed to run before the repo is cloned, e.g.:
#   curl -fsSL https://raw.githubusercontent.com/danhorst/dotfiles/main/bootstrap.linux.sh | bash
#
# Installs apt prerequisites, Linuxbrew, and zsh as the login shell, clones the
# repo, then points you at ./install.sh.
set -euo pipefail

REPO_URL="https://github.com/danhorst/dotfiles.git"
REPO_DIR="$HOME/git/danhorst/dotfiles"
BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"

rule() { printf '%s\n' "$(printf '%80s' '' | tr ' ' "$1")"; }
banner() { rule '*'; printf '* %s\n' "$1"; rule '*'; }

banner "apt prerequisites"
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git zsh

banner "Linuxbrew"
if [ -x "$BREW_BIN" ]; then
  echo "Linuxbrew already installed at $BREW_BIN"
else
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$BREW_BIN" shellenv)"

banner "Login shell"
zsh_path="$(command -v zsh)"
if ! grep -qxF "$zsh_path" /etc/shells; then
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
fi
if [ "$SHELL" = "$zsh_path" ]; then
  echo "zsh is already the login shell"
else
  chsh -s "$zsh_path"
  echo "Set login shell to $zsh_path (takes effect on next login)"
fi

banner "Clone dotfiles"
mkdir -p "$HOME/.config"
if [ -d "$REPO_DIR/.git" ]; then
  echo "Repo already present at $REPO_DIR"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

banner "Next step"
echo "cd $REPO_DIR && ./install.sh"
