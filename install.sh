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

section "Utilities"

echo "Setting up personal scripts"
safe_symlink "$dotfiles_directory/bin" "$HOME/.bin"

section "Packages"

echo "Ensuring baseline brew formulas are installed"
_bundle_stamp="${HOME}/.homebrew-bundle-last-run"
if ! git diff --quiet HEAD -- Brewfile "Brewfile.$OS" 2>/dev/null; then
  echo "  Brewfile has uncommitted changes; forcing bundle"
  brew_force=true
fi
if ! ssh-add -l &>/dev/null; then
  echo "  Skipping: no SSH keys loaded on agent"
elif [ "$brew_force" = false ] && [ -f "$_bundle_stamp" ] && (( $(date +%s) - $(file_mtime "$_bundle_stamp") < 86400 )); then
  echo "  Skipping: brew bundle ran within the last 24h (use -b to force)"
else
  brew update
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file Brewfile -v
  if [ -f "Brewfile.$OS" ]; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file "Brewfile.$OS" -v
  fi
  if [ "$upgrade" = true ]; then
    brew upgrade
  fi
  touch "$_bundle_stamp"
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
