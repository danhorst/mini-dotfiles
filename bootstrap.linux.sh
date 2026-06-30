#!/bin/bash
# One-time bootstrap for a fresh Ubuntu / WSL machine.
#
# Designed to run before the repo is cloned, e.g.:
#   curl -fsSL https://raw.githubusercontent.com/danhorst/dotfiles/main/bootstrap.linux.sh | bash
#
# Installs apt prerequisites, clones the repo, installs Linuxbrew from the
# vendored installer, and sets zsh as the login shell.
set -euo pipefail

REPO_URL="https://github.com/danhorst/dotfiles.git"
REPO_DIR="$HOME/git/danhorst/dotfiles"

rule() { printf '%s\n' "$(printf '%80s' '' | tr ' ' "$1")"; }
banner() { rule '*'; printf '* %s\n' "$1"; rule '*'; }

_find_brew() {
  for _b in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [ -x "$_b" ] && echo "$_b" && return
  done
}

banner "apt prerequisites"
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git zsh

banner "Clone dotfiles"
mkdir -p "$HOME/.config"
if [ -d "$REPO_DIR/.git" ]; then
  echo "Repo already present at $REPO_DIR"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

banner "Linuxbrew"
BREW_BIN="$(_find_brew)"
if [ -n "$BREW_BIN" ]; then
  echo "Linuxbrew already installed at $BREW_BIN"
else
  NONINTERACTIVE=1 bash "$REPO_DIR/vendor/brew-install.sh"
  BREW_BIN="$(_find_brew)"
fi
eval "$("$BREW_BIN" shellenv)"

banner "Third-party taps"
brew tap danhorst/tap
bash "$REPO_DIR/trust-no-one.sh"

banner "Login shell"
zsh_path="$(command -v zsh)"
if ! grep -qxF "$zsh_path" /etc/shells; then
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
fi
if [ "$SHELL" = "$zsh_path" ]; then
  echo "zsh is already the login shell"
else
  chsh -s "$zsh_path" || echo "WARN: chsh failed; run 'chsh -s $zsh_path' manually"
fi

banner "Next step"
echo "cd $REPO_DIR && ./install.sh"
