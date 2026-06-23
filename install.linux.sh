#!/bin/bash
# Linux/WSL install steps, sourced by install.sh.
# The core productivity layer (shell, CLI tools, mise, Claude Code) is handled
# by install.sh. This file is where Linux-only setup would go.

section "Linux notes"

echo "Core productivity layer installed by install.sh (shell, Brewfile, mise, Claude Code)."
echo "Intentionally skipped on Linux:"
echo "  - Ghostty config (use Windows Terminal; its config lives on the Windows side)"
echo "  - Caddy / Unbound / pf network infrastructure"
echo "  - Lima (WSL is already a Linux environment)"
echo "  - Gatekeeper, Power Nap, macOS SSH/ShellFish setup"
