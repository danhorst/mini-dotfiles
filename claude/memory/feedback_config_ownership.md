---
name: feedback_config_ownership
description: "what belongs to the dotfiles repo vs the tool — don't track machine config there, and don't `brew install` (the Brewfile is the source of truth)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ec48f5ad-a6c9-4ad0-926c-ce5a67c8e022
---

DBH prefers to push machine-specific or tool-specific config down into the tools themselves rather than tracking it in the dotfiles repo.
The dotfiles repo is for portable, tool-agnostic setup; per-machine values (e.g.
Obsidian vault path, corpus publish path) live in `~/.zshenv.local` (untracked) or in the tool's own config.

Package installs are the same domain: don't run `brew install` yourself.
The dotfiles `Brewfile` is the single source of truth for installed packages — an unexpected `brew install` isn't tracked there.

**Why:** keeps the dotfiles repo from becoming a registry of every tool's machine state; each tool owns what it knows, and the Brewfile owns what's installed.

**How to apply:** don't suggest "track it in dotfiles (tracked-but-overridable)" for machine/tool-specific values — that direction was explicitly declined.
Default to the tool's own config, or the untracked local file.
When a tool is missing (e.g.
`xcodegen`, `yq`), name it and ask DBH to add it via the dotfiles Brewfile rather than running `brew install`.
See [[project_shell_config_naming]].
