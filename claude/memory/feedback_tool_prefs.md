---
name: Tool substitution preferences
description: Substitution table — rg/ast-grep/fd/sd/yq/delta/difft instead of POSIX defaults; check before every Bash call
metadata:
  type: feedback
---

**Rule:** never use the POSIX default when a replacement is listed here.

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

**How to apply:** check this table before writing any Bash call involving grep, find, sed, awk, or git diff.

See also [[use-ast-grep-for-structural-code-search]], [[md-tools-usage-mdsplit-and-mdtable]].
