---
name: Homebrew package installation
description: User manages all Homebrew packages via their dotfiles repo — never run brew install
type: feedback
---

Do not run `brew install` to install packages.
The user manages all Homebrew packages through their dotfiles repository and will install them manually.

**Why:** User's dotfiles repo is the single source of truth for installed packages; unexpected brew installs are not tracked there.

**How to apply:** If a tool is missing (e.g., `xcodegen`, `yq`, etc.), mention it and ask the user to install it via their dotfiles rather than running `brew install` yourself.
