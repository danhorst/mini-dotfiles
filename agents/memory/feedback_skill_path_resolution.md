---
name: feedback_skill_path_resolution
description: "Claude Code skills must resolve dotfiles/claude paths dynamically via the ~/.claude/commands symlink, never hardcode ~/git/danhorst/dotfiles/..."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 71afb4a8-b10b-4362-a462-aacf4c8abd46
---

Skill files (`dotfiles/claude/commands/*.md`) must not hardcode `~/git/danhorst/dotfiles/claude/...` paths.
Resolve instead with:

```
CLAUDE_ROOT="$(dirname "$(readlink ~/.claude/commands)")"
```

`~/.claude/commands` is a symlink to `dotfiles/claude/commands` and is guaranteed to exist; `$CLAUDE_ROOT` resolves to `dotfiles/claude` regardless of where that checkout actually lives.
The idiom itself is documented once in `dotfiles/claude/README.md`'s "Path resolution" section — skills should reference that doc rather than re-explaining the mechanism inline each time.

**Why:** DBH dislikes paths coupled to one machine's home-directory layout — came up when reviewing the new `update-go-deps` skill, then retrofitted into `release.md`, `bootstrap-release.md`, and `wrap-it-up.md`, which previously all hardcoded the absolute path.

**How to apply:** Any new skill that needs to reference `fixtures/`, `memory/`, or other `dotfiles/claude` subdirectories should resolve `CLAUDE_ROOT` this way rather than writing a literal home-directory path.
Don't extract the one-liner into a shared script — the script's own location would need the same resolution, so there's nothing to gain; only the explanatory prose was worth deduplicating (into the README), not the one-liner itself.
