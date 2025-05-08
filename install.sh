#!/bin/bash

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
rustup update

cargo install bat
cargo install fd-find
cargo install git-delta
cargo install monolith
cargo install ripgrep

echo "*******************************************************************************"
echo "Done!"
echo "*******************************************************************************"
