---
name: Use ast-grep for structural code search
description: Reach for ast-grep over rg/grep when searching code constructs or doing multi-site refactors
metadata:
  type: feedback
---

Prefer `ast-grep` over `rg`/`grep` for code searches when:

- The search target is a code construct (function calls, method definitions, variable patterns)
- Regex would be fragile across syntactic variation (e.g., different argument formatting)
- A refactor spans multiple call sites

**Why:** the hook catches `grep` but is blind to a direct `rg` call — the `rg` → `ast-grep` judgment on structural searches is mine to make.

**How to apply:** before reaching for `rg` on a code search, ask whether the target is structural — if yes, use `ast-grep`.
Reserve `rg` for plain-text searches (log output, comments, string literals, config values).

See also [[judgment-driven-tool-choices]].
