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
find "$dotfiles" -maxdepth 1 -mindepth 1 -print0 | xargs -0 -I D ln -nsf "D" "$HOME/.$(basename D)"

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
find "$dotfiles_directory/claude" -maxdepth 1 -mindepth 1 -print0 | xargs -0 -I F ln -nsf "F" "$HOME/.claude/$(basename F)"

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
echo "*******************************************************************************"
echo "Done!"
echo "*******************************************************************************"
