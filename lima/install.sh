#!/bin/bash

# Resolve the repo root from this script's own location so the checkout can live
# anywhere the Lima guest can see it, not just one hardcoded path.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "###############################################################################"
echo "Package updates"
echo "###############################################################################"

sudo apt update
sudo apt upgrade

echo ""
echo "###############################################################################"
echo "Essential packages"
echo "###############################################################################"

sudo apt install \
	autoconf \
	bison \
	build-essential \
	curl \
	git \
	libffi-dev \
	libgdbm-dev \
	libncurses5-dev \
	libreadline-dev \
	libreadline-dev \
	libssl-dev \
	libyaml-dev \
	tree \
	vim \
	zlib1g-dev

echo ""
echo "###############################################################################"
echo "Dotfiles"
echo "###############################################################################"

ln -nsf "$REPO_DIR/lima/bashrc" "$HOME/.bashrc"
ln -nsf "$REPO_DIR/shell/gitconfig" "$HOME/.gitconfig"

echo "###############################################################################"
echo "rbenv"
echo "###############################################################################"

if [ -d "$HOME/.rbenv" ]; then
  echo "rbenv already installed"
else
  git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
fi

if [ -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  echo "ruby-build is already installed"
else
  echo "Installing ruby-build"
  mkdir -p "$HOME/.rbenv/plugins/ruby-build"
  git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
fi

echo ""
echo "###############################################################################"
echo "nvm"
echo "###############################################################################"

if declare -f nvm &> /dev/null; then
  echo "nvm is installed"
else
  "$REPO_DIR/lima/nvm-install.sh"
fi

echo ""
echo "###############################################################################"
echo "Claude Code"
echo "###############################################################################"

if command -v claude >/dev/null 2>&1; then
  echo "claude is already installed"
else
  echo "claude is not installed"
  bash "$REPO_DIR/vendor/claude-install.sh"
fi

echo ""
echo "*******************************************************************************"
echo "Done!"
echo "*******************************************************************************"
