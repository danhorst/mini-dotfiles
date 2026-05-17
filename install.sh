#!/bin/bash

force=false
while getopts "f" opt; do
  case $opt in
    f) force=true ;;
    *) echo "Usage: $0 [-f]" >&2; exit 1 ;;
  esac
done

safe_symlink() {
  local target="$1"
  local link_name="$2"

  if [ -L "$link_name" ]; then
    current_target="$(readlink "$link_name")"
    if [ "$current_target" = "$target" ]; then
      echo "  Symlink already exists: $link_name"
    else
      ln -nsf "$target" "$link_name"
      echo "  Updated symlink: $link_name -> $target (was -> $current_target)"
    fi
  elif [ -e "$link_name" ]; then
    echo "  WARNING: $link_name exists as a real file/directory. Skipping."
  else
    ln -nsf "$target" "$link_name"
    echo "  Created symlink: $link_name -> $target"
  fi
}

_rule() {
  local char="$1" title="$2"
  local cols width border
  cols=${COLUMNS:-$(stty size </dev/tty 2>/dev/null | awk '{print $2}')}
  cols=${cols:-80}
  width=$(( cols < 80 ? cols : 80 ))
  border=$(printf "%${width}s" '' | tr ' ' "$char")
  printf '%s\n' "$border"
  printf '%s %s\n' "$char" "$title"
  printf '%s\n' "$border"
}

section() { _rule "#" "$1"; }
banner()  { _rule "*" "$1"; }

section "Xcode"

echo "Ensuring Xcode utilities are installed"
xcode-select --install

section "Dotfiles"

echo "WARN: Run install script from the root of the dotfiles repo"
dotfiles_directory="$(pwd)"
dotfiles="$dotfiles_directory/shell"

echo "Symlinking dotfiles into $HOME"
while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  safe_symlink "$file" "$HOME/.$filename"
done < <(find "$dotfiles" -maxdepth 1 -type f -print0)

section "Utilities"

echo "Setting up personal scripts"
safe_symlink "$dotfiles_directory/bin" "$HOME/.bin"

section "Packages"

echo "Ensuring baseline brew formulas are installed"
brew update
brew bundle --file Brewfile -v

section "mise"

echo "Installing mise-managed tools"
mise install

section "Lima"

if [ -d "/Users/lima" ]; then
  echo "Lima shared directory is set up"
else
  mkdir /Users/lima
fi

if [ -d "$HOME/.lima/default" ]; then
  echo "Ensure Lima default VM config is tracked"
  safe_symlink "$dotfiles_directory/lima/default/lima.yaml" "$HOME/.lima/default/lima.yaml"
else
  echo "Lima default VM is not set up"
fi

section "Claude Code"

mkdir -p "$HOME/.claude"
echo "Symlinking Claude Code config into $HOME/.claude"
while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  safe_symlink "$file" "$HOME/.claude/$filename"
done < <(find "$dotfiles_directory/claude" -maxdepth 1 -type f -print0)

section "Ghostty"

GHOSTTY_CONF_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
GHOSTTY_XDG_DIR="$HOME/.config/ghostty"
mkdir -p "$GHOSTTY_CONF_DIR"
mkdir -p "$GHOSTTY_XDG_DIR"
echo "Symlinking Ghostty config"
safe_symlink "$dotfiles_directory/ghostty/config" "$GHOSTTY_CONF_DIR/config"
echo "Symlinking Ghostty themes"
safe_symlink "$dotfiles_directory/ghostty/themes" "$GHOSTTY_XDG_DIR/themes"

section "Playwright"

echo "Installing Playwright Chromium browser"
mise exec -- playwright install chromium

section "SSH key management"

ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
SSH_KEY="$(git config --global user.signingkey)"
GIT_EMAIL="$(git config --global user.email)"

if [ -z "$SSH_KEY" ]; then
  echo "WARN: No signing key configured in git; skipping allowed signers setup"
else
  if [ ! -f "$SSH_KEY" ]; then
    echo "Signing key $SSH_KEY not found; generating new SSH key"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "${SSH_KEY%.pub}" -N ""
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

section "Unbound (local DNS)"

UNBOUND_PREFIX="$(brew --prefix)/etc/unbound"
UNBOUND_CONF="$UNBOUND_PREFIX/unbound.conf"
UNBOUND_LOCAL="$UNBOUND_PREFIX/local-dev.conf"

unbound_changed=false

if [ "$force" = true ] || [ "$(readlink "$UNBOUND_LOCAL")" != "$dotfiles_directory/unbound/local-dev.conf" ]; then
  echo "Symlinking Unbound local zone config"
  safe_symlink "$dotfiles_directory/unbound/local-dev.conf" "$UNBOUND_LOCAL"
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

section "Caddy"

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
  "$(go env GOPATH)/bin/xcaddy" build --with github.com/tailscale/caddy-tailscale --output "$TMP_CADDY"
  sudo mv "$TMP_CADDY" "$CADDY_BINARY"
  sudo chmod 755 "$CADDY_BINARY"
  echo "Caddy installed to $CADDY_BINARY"
fi

echo "Setting up Caddy config directory"
caddy_conf_ok=true
[ ! -d "$CADDY_CONF_DIR/sites" ] && caddy_conf_ok=false
[ "$(stat -f '%Su:%Sg' "$CADDY_CONF_DIR" 2>/dev/null)" != "root:admin" ] && caddy_conf_ok=false
[ "$(readlink "$CADDY_CONF_DIR/Caddyfile" 2>/dev/null)" != "$dotfiles_directory/caddy/Caddyfile" ] && caddy_conf_ok=false
if [ "$force" = true ] || [ "$caddy_conf_ok" = false ]; then
  sudo mkdir -p "$CADDY_CONF_DIR/sites"
  sudo chown root:admin "$CADDY_CONF_DIR"
  sudo chown root:admin "$CADDY_CONF_DIR/sites"
  sudo chmod 775 "$CADDY_CONF_DIR/sites"
  sudo ln -nsf "$dotfiles_directory/caddy/Caddyfile" "$CADDY_CONF_DIR/Caddyfile"
  sudo chmod o+r "$CADDY_CONF_DIR/Caddyfile"
else
  echo "Caddy config directory already configured"
fi

echo "Setting up Caddy data directory"
if [ "$force" = true ] || [ ! -d /usr/local/share/caddy ] || [ "$(stat -f '%Su:%Sg' /usr/local/share/caddy 2>/dev/null)" != "root:wheel" ]; then
  sudo mkdir -p /usr/local/share/caddy
  sudo chown root:wheel /usr/local/share/caddy
else
  echo "Caddy data directory already configured"
fi

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
  sudo launchctl unload "$CADDY_PLIST_DEST" 2>/dev/null || true
  sudo cp "$CADDY_PLIST_SRC" "$CADDY_PLIST_DEST"
  sudo chown root:wheel "$CADDY_PLIST_DEST"
  sudo chmod 644 "$CADDY_PLIST_DEST"
  sudo launchctl load "$CADDY_PLIST_DEST"
  echo "Caddy LaunchDaemon installed and loaded"
fi

section "pf (local HTTPS redirect)"

PF_ANCHOR_SRC="$dotfiles_directory/caddy/pf.anchor"
PF_ANCHOR_DEST="/etc/pf.anchors/com.danhorst.caddy"
PF_PLIST_SRC="$dotfiles_directory/caddy/com.danhorst.pf.plist"
PF_PLIST_DEST="/Library/LaunchDaemons/com.danhorst.pf.plist"

echo "Installing pf anchor"
if [ "$force" = true ] || ! cmp -s "$PF_ANCHOR_SRC" "$PF_ANCHOR_DEST" 2>/dev/null; then
  sudo cp "$PF_ANCHOR_SRC" "$PF_ANCHOR_DEST"
  sudo pfctl -a com.apple/caddy -f "$PF_ANCHOR_DEST" 2>/dev/null || true
  sudo pfctl -e 2>/dev/null || true
else
  echo "pf anchor already up to date"
fi

if [ -f "$PF_PLIST_DEST" ] && [ "$force" = false ]; then
  echo "pf LaunchDaemon already installed"
else
  echo "Installing pf LaunchDaemon"
  sudo launchctl unload "$PF_PLIST_DEST" 2>/dev/null || true
  sudo cp "$PF_PLIST_SRC" "$PF_PLIST_DEST"
  sudo chown root:wheel "$PF_PLIST_DEST"
  sudo chmod 644 "$PF_PLIST_DEST"
  sudo launchctl load "$PF_PLIST_DEST"
  echo "pf LaunchDaemon installed and loaded"
fi

section "Power Management"

current_powernap=$(pmset -g | awk '/powernap/ {print $2}')
if [ "$current_powernap" = "0" ]; then
  echo "Power Nap already disabled"
else
  echo "Disabling Power Nap (prevents Continuity/Universal Control disconnections)"
  sudo pmset -a powernap 0
fi

banner "Done!"
