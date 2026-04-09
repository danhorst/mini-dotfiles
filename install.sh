#!/bin/bash

echo "###############################################################################"
echo "# Xcode"
echo "###############################################################################"

echo "Ensuring Xcode utilities are installed"
xcode-select --install

echo ""
echo "###############################################################################"
echo "# Dotfiles"
echo "###############################################################################"
echo ""

echo "WARN: Run install script from the root of the dotfiles repo"
dotfiles_directory="$(pwd)"
dotfiles="$dotfiles_directory/shell"

echo "Symlinking dotfiles into $HOME"
while IFS= read -r -d '' f; do
  ln -nsf "$f" "$HOME/.$(basename "$f")"
done < <(find "$dotfiles" -maxdepth 1 -mindepth 1 -print0)

echo ""
echo "###############################################################################"
echo "# Utilities"
echo "###############################################################################"
echo ""

if [ -L "$HOME/.bin" ]; then
  echo "Personal scripts are already linked"
else
  echo "Setting up personal scripts"
  ln -nsf "$dotfiles_directory/bin" "$HOME/.bin"
fi

echo ""
echo "###############################################################################"
echo "# Packages"
echo "###############################################################################"

echo "Ensureing baseline brew formulas are installed"
brew bundle --file Brewfile -v

echo ""
echo "###############################################################################"
echo "# Rust & Crates"
echo "###############################################################################"

rustup default stable
rustup update

cargo install bat
cargo install fd-find
cargo install git-delta
cargo install ripgrep

echo ""
echo "###############################################################################"
echo "# Lima"
echo "###############################################################################"

if [ -d "/Users/lima" ]; then
  echo "Lima shared directory is set up"
else
  mkdir /Users/lima
fi

echo ""
echo "###############################################################################"
echo "# Claude Code"
echo "###############################################################################"

mkdir -p "$HOME/.claude"
echo "Symlinking Claude Code config into $HOME/.claude"
while IFS= read -r -d '' f; do
  ln -nsf "$f" "$HOME/.claude/$(basename "$f")"
done < <(find "$dotfiles_directory/claude" -maxdepth 1 -mindepth 1 -print0)

echo ""
echo "###############################################################################"
echo "# Lima"
echo "###############################################################################"

if [ -d "$HOME/.lima/default" ]; then
  echo "Ensure Lima default VM config is tracked"
  ln -nsf "$HOME/git/dotfiles/lima/default/lima.yaml" "$HOME/.lima/default/lima.yaml"
else
  echo "Lima default VM is not set up"
fi

echo ""
echo "###############################################################################"
echo "# Unbound (local DNS)"
echo "###############################################################################"

UNBOUND_PREFIX="$(brew --prefix)/etc/unbound"
UNBOUND_CONF="$UNBOUND_PREFIX/unbound.conf"
UNBOUND_LOCAL="$UNBOUND_PREFIX/local-dev.conf"

unbound_changed=false

if [ "$(readlink "$UNBOUND_LOCAL")" != "$dotfiles_directory/unbound/local-dev.conf" ]; then
  echo "Symlinking Unbound local zone config"
  ln -nsf "$dotfiles_directory/unbound/local-dev.conf" "$UNBOUND_LOCAL"
  unbound_changed=true
else
  echo "Unbound local zone config symlink already up to date"
fi

if ! grep -q "local-dev.conf" "$UNBOUND_CONF"; then
  echo "Adding include directive to unbound.conf"
  echo "include: \"$UNBOUND_LOCAL\"" >> "$UNBOUND_CONF"
  unbound_changed=true
fi

if [ ! -f "/etc/resolver/test" ]; then
  echo "Creating /etc/resolver/test"
  sudo mkdir -p /etc/resolver
  sudo sh -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
  unbound_changed=true
fi

if [ "$unbound_changed" = true ]; then
  echo "Restarting Unbound"
  sudo brew services restart unbound
else
  echo "No Unbound changes; skipping restart"
fi

echo ""
echo "###############################################################################"
echo "# Caddy (port 443 privileges)"
echo "###############################################################################"

CADDY_SUDOERS_SRC="$dotfiles_directory/caddy/caddy.sudoers"
CADDY_SUDOERS_DEST="/etc/sudoers.d/caddy"

if [ -f "$CADDY_SUDOERS_DEST" ]; then
  echo "Caddy sudoers file already installed"
else
  echo "Validating caddy sudoers file"
  visudo -c -f "$CADDY_SUDOERS_SRC"
  echo "Installing caddy sudoers file"
  sudo install -m 0440 -o root -g wheel "$CADDY_SUDOERS_SRC" "$CADDY_SUDOERS_DEST"
  echo "Caddy sudoers file installed"
fi

echo ""
echo "*******************************************************************************"
echo "Done!"
echo "*******************************************************************************"
