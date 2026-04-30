#!/bin/bash

force=false
while getopts "f" opt; do
  case $opt in
    f) force=true ;;
    *) echo "Usage: $0 [-f]" >&2; exit 1 ;;
  esac
done

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
echo "# mise"
echo "###############################################################################"

echo "Installing mise-managed tools"
mise install

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

if [ -d "$HOME/.lima/default" ]; then
  echo "Ensure Lima default VM config is tracked"
  ln -nsf "$HOME/git/dotfiles/lima/default/lima.yaml" "$HOME/.lima/default/lima.yaml"
else
  echo "Lima default VM is not set up"
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
echo "# Playwright"
echo "###############################################################################"

echo "Installing Playwright Chromium browser"
mise exec -- playwright install chromium

echo ""
echo "###############################################################################"
echo "# SSH allowed signers"
echo "###############################################################################"

ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
SSH_KEY="$(git config --global user.signingkey)"
GIT_EMAIL="$(git config --global user.email)"

if [ -z "$SSH_KEY" ]; then
  echo "WARN: No signing key configured in git; skipping allowed signers setup"
else
  if [ ! -f "$SSH_KEY" ]; then
    echo "Signing key $SSH_KEY not found; generating new SSH key"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "${SSH_KEY%.pub}"
  fi

  if [ -f "$ALLOWED_SIGNERS" ]; then
    echo "SSH allowed signers file already present"
  else
    echo "Generating SSH allowed signers file"
    echo "$GIT_EMAIL $(cat "$SSH_KEY")" > "$ALLOWED_SIGNERS"
    echo "Created $ALLOWED_SIGNERS"
  fi
fi

echo ""
echo "###############################################################################"
echo "# Unbound (local DNS)"
echo "###############################################################################"

UNBOUND_PREFIX="$(brew --prefix)/etc/unbound"
UNBOUND_CONF="$UNBOUND_PREFIX/unbound.conf"
UNBOUND_LOCAL="$UNBOUND_PREFIX/local-dev.conf"

unbound_changed=false

if [ "$force" = true ] || [ "$(readlink "$UNBOUND_LOCAL")" != "$dotfiles_directory/unbound/local-dev.conf" ]; then
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

if [ "$force" = true ] || [ ! -f "/etc/resolver/test" ]; then
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
echo "# Caddy"
echo "###############################################################################"

CADDY_BINARY="/usr/local/bin/caddy"
CADDY_CONF_DIR="/etc/caddy"
CADDY_PLIST_SRC="$dotfiles_directory/caddy/com.danhorst.caddy.plist"
CADDY_PLIST_DEST="/Library/LaunchDaemons/com.danhorst.caddy.plist"
CADDY_SUDOERS_SRC="$dotfiles_directory/caddy/caddy.sudoers"
CADDY_SUDOERS_DEST="/etc/sudoers.d/caddy"

if [ -f "$CADDY_BINARY" ] && [ "$force" = false ]; then
  echo "Caddy binary already installed at $CADDY_BINARY"
else
  echo "Installing xcaddy"
  go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
  echo "Building Caddy with Tailscale plugin (this takes a moment)"
  TMP_CADDY="$(mktemp /tmp/caddy-build-XXXX)"
  "$GOPATH/bin/xcaddy" build --with github.com/tailscale/caddy-tailscale --output "$TMP_CADDY"
  sudo mv "$TMP_CADDY" "$CADDY_BINARY"
  sudo chmod 755 "$CADDY_BINARY"
  echo "Caddy installed to $CADDY_BINARY"
fi

echo "Setting up Caddy config directory"
sudo mkdir -p "$CADDY_CONF_DIR/sites"
sudo chown root:admin "$CADDY_CONF_DIR"
sudo chown root:admin "$CADDY_CONF_DIR/sites"
sudo chmod 775 "$CADDY_CONF_DIR/sites"
sudo ln -nsf "$dotfiles_directory/caddy/Caddyfile" "$CADDY_CONF_DIR/Caddyfile"
sudo chmod o+r "$CADDY_CONF_DIR/Caddyfile"

if [ -f "$CADDY_SUDOERS_DEST" ] && [ "$force" = false ]; then
  echo "Caddy sudoers file already installed"
else
  echo "Validating caddy sudoers file"
  visudo -c -f "$CADDY_SUDOERS_SRC"
  echo "Installing caddy sudoers file"
  sudo install -m 0440 -o root -g wheel "$CADDY_SUDOERS_SRC" "$CADDY_SUDOERS_DEST"
  echo "Caddy sudoers file installed"
fi

if [ -f "$CADDY_PLIST_DEST" ] && [ "$force" = false ]; then
  echo "Caddy LaunchDaemon already installed"
else
  echo "Installing Caddy LaunchDaemon"
  sudo cp "$CADDY_PLIST_SRC" "$CADDY_PLIST_DEST"
  sudo chown root:wheel "$CADDY_PLIST_DEST"
  sudo chmod 644 "$CADDY_PLIST_DEST"
  sudo launchctl load "$CADDY_PLIST_DEST"
  echo "Caddy LaunchDaemon installed and loaded"
fi

echo ""
echo "*******************************************************************************"
echo "Done!"
echo "*******************************************************************************"
