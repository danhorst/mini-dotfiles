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
ln -nfs "$HOME/git/dotfiles/shell/gitconfig" "$HOME/.gitconfig"
ln -nfs "$HOME/git/dotfiles/shell/zshrc" "$HOME/.zshrc"

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
cargo install monolith
cargo install ripgrep

echo ""
echo "###############################################################################"
echo "# Lima"
echo "###############################################################################"
if [ -d "~/.lima/default" ]; then
  ln -nsf "$HOME/git/dotfiles/lima/default/lima.yaml" "$HOME/.lima/default/lima.yaml"
else
  echo "Lima default VM is not set up"
fi

echo ""
echo "*******************************************************************************"
echo "Done!"
echo "*******************************************************************************"
