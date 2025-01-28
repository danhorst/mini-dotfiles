#!/bin/zsh

echo "###############################################################################"
echo "# Xcode"
echo "###############################################################################"

echo "Ensuring Xcode utilities are installed"
xcode-select --install

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

cargo install bat
cargo install fd-find
cargo install git-delta
#cargo install jwt-ui # Use homebrew instead
cargo install monolith
cargo install ripgrep
#cargo install tidy-viewer # Use homebrew instead
