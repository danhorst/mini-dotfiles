#!/bin/bash
# Linux/WSL install steps, sourced by install.sh.
# The core productivity layer (shell, CLI tools, mise) is handled by install.sh.
# This file covers Linux-only setup: Claude Code (npm), default shell.

section "Default shell (zsh)"

# Use the apt-provided zsh as the login shell: it's already in /etc/shells and
# avoids the PAM/login edge cases of a Homebrew zsh. Homebrew still drives all
# other tooling.
if ! command -v zsh &>/dev/null; then
  echo "Installing zsh via apt"
  sudo apt-get update && sudo apt-get install -y zsh
fi

zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$current_shell" = "$zsh_path" ]; then
  echo "Login shell already zsh ($zsh_path)"
else
  echo "Switching login shell to $zsh_path (chsh may prompt for your password)"
  chsh -s "$zsh_path" || echo "WARN: chsh failed; run 'chsh -s $zsh_path' manually"
fi

section "Linux notes"

echo "Core productivity layer installed by install.sh (shell, Brewfile, mise, Claude Code)."
echo "Intentionally skipped on Linux:"
echo "  - Ghostty config (use Windows Terminal; its config lives on the Windows side)"
echo "  - Caddy / Unbound / pf network infrastructure"
echo "  - Lima (WSL is already a Linux environment)"
echo "  - Gatekeeper, Power Nap, macOS SSH/ShellFish setup"
