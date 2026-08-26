#!/bin/bash
# network_force is consumed by the sourced install.{macos,linux}.sh
# shellcheck disable=SC2034

brew_force=false
network_force=false
upgrade=true

print_help() {
  cat <<EOF
Usage: $0 [-b] [-n] [--no-upgrade] [-h]

  -b, --brew       Update Homebrew and install from Brewfile (bypasses 24h cache)
  -n, --network    Reset Unbound, Caddy, and pf network configuration (macOS only)
      --no-upgrade  Skip brew upgrade after bundle
  -h, --help       Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--brew)    brew_force=true ;;
    -n|--network) network_force=true ;;
    --no-upgrade) upgrade=false ;;
    -h|--help)    print_help; exit 0 ;;
    *) echo "Usage: $0 [-b] [-n] [--no-upgrade] [-h]" >&2; exit 1 ;;
  esac
  shift
done

echo "WARN: Run install script from the root of the dotfiles repo"
dotfiles_directory="$(pwd)"
dotfiles="$dotfiles_directory/shell"

# shellcheck source=/dev/null
source "$dotfiles_directory/lib/common.sh"

# Linuxbrew isn't on PATH in a fresh shell; bootstrap.linux.sh eval'd it
# for its own process only. Try both common install locations.
if is_linux && ! command -v brew &>/dev/null; then
  for _brew in /home/linuxbrew/.linuxbrew/bin/brew ~/.linuxbrew/bin/brew; do
    [ -x "$_brew" ] && eval "$($_brew shellenv)" && break
  done
  unset _brew
fi
if is_linux && ! command -v brew &>/dev/null; then
  NONINTERACTIVE=1 bash "$dotfiles_directory/vendor/brew-install.sh"
  for _brew in /home/linuxbrew/.linuxbrew/bin/brew ~/.linuxbrew/bin/brew; do
    [ -x "$_brew" ] && eval "$($_brew shellenv)" && break
  done
  unset _brew
fi

section "Dotfiles"

echo "Symlinking dotfiles into $HOME"
while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  safe_symlink "$file" "$HOME/.$filename"
done < <(find "$dotfiles" -maxdepth 1 -type f -print0)

section "Config (XDG)"

echo "Symlinking tracked config files into $HOME/.config"
while IFS= read -r rel; do
  [ "$rel" = "shell/config/.gitkeep" ] && continue
  dest="$HOME/.config/${rel#shell/config/}"
  mkdir -p "$(dirname "$dest")"
  safe_symlink "$dotfiles_directory/$rel" "$dest"
done < <(git -C "$dotfiles_directory" ls-files shell/config)

section "Git hooks"

current_hooks_path=$(git config --local --get core.hooksPath 2>/dev/null || true)
if [ "$current_hooks_path" = ".githooks" ]; then
  echo "  Git hooks path already set to .githooks"
else
  git config --local core.hooksPath .githooks
  echo "  Set core.hooksPath = .githooks"
fi

section "SSH key management"

ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
SSH_KEY="$(git config --global user.signingkey)"
SSH_KEY="${SSH_KEY/#\~/$HOME}"
GIT_EMAIL="$(git config --global user.email)"

if [ -z "$SSH_KEY" ]; then
  echo "WARN: No signing key configured in git; skipping allowed signers setup"
else
  if [ ! -f "$SSH_KEY" ]; then
    echo "Signing key $SSH_KEY not found; generating new SSH key"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "${SSH_KEY%.pub}" -N ""
    echo "NOTE: new signing key generated — add $SSH_KEY to GitHub as a Signing Key (Settings > SSH and GPG keys) for the Verified badge"
  fi

  key_fingerprint=$(awk '{print $2}' "$SSH_KEY")
  if grep -qF "$key_fingerprint" "$ALLOWED_SIGNERS" 2>/dev/null; then
    echo "Signing key already in allowed signers"
  else
    echo "$GIT_EMAIL $(cat "$SSH_KEY")" >> "$ALLOWED_SIGNERS"
    echo "Added signing key to $ALLOWED_SIGNERS"
  fi
fi

# ShellFish (iPhone) key — export from ShellFish > Settings > SSH Keys,
# then copy to this path before running install.
SHELLFISH_KEY="$HOME/.ssh/shellfish-iphone.pub"

if [ ! -f "$SHELLFISH_KEY" ]; then
  echo "WARN: ShellFish key not found at $SHELLFISH_KEY; skipping"
  echo "  Export your public key from ShellFish > Settings > SSH Keys and copy it there"
else
  key_data=$(awk '{print $2}' "$SHELLFISH_KEY")

  if grep -qF "$key_data" "$ALLOWED_SIGNERS" 2>/dev/null; then
    echo "ShellFish key already in allowed signers"
  else
    echo "$GIT_EMAIL $(cat "$SHELLFISH_KEY")" >> "$ALLOWED_SIGNERS"
    echo "Added ShellFish key to $ALLOWED_SIGNERS"
  fi

  AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"
  if grep -qF "$key_data" "$AUTHORIZED_KEYS" 2>/dev/null; then
    echo "ShellFish key already in authorized_keys"
  else
    cat "$SHELLFISH_KEY" >> "$AUTHORIZED_KEYS"
    echo "Added ShellFish key to $AUTHORIZED_KEYS"
  fi
fi

section "Utilities"

echo "Setting up personal scripts"
safe_symlink "$dotfiles_directory/bin" "$HOME/.bin"

echo "Ensuring GOPATH bin directory exists"
mkdir -p "$HOME/.go/bin"

section "Packages"

echo "Ensuring baseline brew formulas are installed"
_bundle_stamp="${HOME}/.homebrew-bundle-last-run"
if ! git diff --quiet HEAD -- Brewfile "Brewfile.$OS" 2>/dev/null; then
  echo "  Brewfile has uncommitted changes; forcing bundle"
  brew_force=true
fi
if [ -f "$_bundle_stamp" ] && ! ssh-add -l &>/dev/null; then
  echo "  Skipping: no SSH keys loaded on agent"
elif [ "$brew_force" = false ] && [ -f "$_bundle_stamp" ] && (( $(date +%s) - $(file_mtime "$_bundle_stamp") < 86400 )); then
  echo "  Skipping: brew bundle ran within the last 24h (use -b to force)"
else
  _bundle_ok=true
  brew update || _bundle_ok=false
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file Brewfile -v || _bundle_ok=false
  if [ -f "Brewfile.$OS" ]; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file "Brewfile.$OS" -v || _bundle_ok=false
  fi
  if [ "$upgrade" = true ]; then
    brew upgrade
  fi
  if [ "$_bundle_ok" = true ]; then
    touch "$_bundle_stamp"
  else
    echo "  brew bundle had errors; stamp not set — re-run to retry"
  fi
fi

section "mise"

echo "Installing mise-managed tools"
mise install

section "Claude Code"

mkdir -p "$HOME/.claude"
echo "Symlinking Claude Code config into $HOME/.claude"
while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  safe_symlink "$file" "$HOME/.claude/$filename"
done < <(find "$dotfiles_directory/claude" -maxdepth 1 -type f -print0)
safe_symlink "$dotfiles_directory/claude/commands" "$HOME/.claude/commands"

if command -v rtk &>/dev/null && command -v claude &>/dev/null; then
  echo "Bootstrapping rtk for Claude Code"
  rtk init --global --auto-patch
else
  echo "Skipping rtk bootstrap for Claude Code (rtk or claude not found)"
fi

if [ -f "$dotfiles_directory/install.$OS.sh" ]; then
  # shellcheck source=/dev/null
  source "$dotfiles_directory/install.$OS.sh"
else
  echo "No platform-specific install script for OS=$OS; skipping"
fi

banner "Done!"
