#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR="$HOME/.claude/projects/-Users-dbh-git-danhorst-dotfiles/memory"
PREFS_FILE="$MEMORY_DIR/feedback_tool_prefs.md"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

cat > "$PREFS_FILE" << 'EOF'
---
name: Tool substitution preferences
description: Substitution rules for shell tools — check before every Bash call
type: feedback
---

**Rule:** Never use the POSIX default when a replacement is listed here.

| Instead of              | Use                     | Why / when                                          |
| ----------------------- | ----------------------- | --------------------------------------------------- |
| `grep`                  | `rg`                    | always                                              |
| `grep` on code          | `ast-grep`              | code constructs, multi-site refactors, AST patterns |
| `find`                  | `fd`                    | always                                              |
| `sed` (find/replace)    | `sd`                    | standard regex, no shell-escaping pitfalls          |
| `sed`/`awk` on config   | `yq`                    | YAML/JSON/TOML/XML — preserves formatting           |
| `git diff` (shell)      | `git diff &#124; delta` | human-readable output                               |
| `git diff` (structural) | `difft`                 | when line-diffs hide what actually moved            |

**Why:** POSIX tools are ingrained defaults that cause silent drift from DBH's preferences.

**How to apply:** Check this table before writing any Bash call involving grep, find, sed, awk, or git diff.
EOF

ENTRY="- [Tool substitution preferences](feedback_tool_prefs.md) — substitution table: rg/ast-grep/fd/sd/yq/delta/difft instead of POSIX defaults"
if ! grep -q "feedback_tool_prefs" "$MEMORY_INDEX" 2>/dev/null; then
    echo "$ENTRY" >> "$MEMORY_INDEX"
fi
