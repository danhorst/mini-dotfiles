---
name: Judgment-driven tool choices
description: Structural diffs (difft) and situational tools (scc/watchexec/bat/tv); the PreToolUse hook covers mechanical substitutions
metadata:
  type: feedback
---

**Mechanical substitutions** (grep → rg/ast-grep, find → fd, sed → sd/yq, awk → yq/sd) are enforced at `PreToolUse` by `tool-prefs-check.sh`, with extension lists in `claude/etc/`.
This memory covers what the hook can't reach.

**`git diff` for structural moves.**
Use `difft` when a line-diff would hide what actually moved — refactors that reshape lines but preserve semantics.
`difft <a> <b>` or `GIT_EXTERNAL_DIFF=difft git diff` for a one-off.
Default `git diff` already pipes through delta (configured as git pager) for human-readable line diffs; that's fine for ordinary changes.

**Situational tools — reach for these when the situation fits:**

- `scc` — SLOC / language summary before reading an unfamiliar repo.
- `watchexec` — file-watcher loop when the tool itself lacks `--watch`.
- `bat` — syntax-highlighted shell reads; for tool-driven file reads use the `Read` tool, not `bat`.
- `tv` (`tidy-viewer`) — tabular data inspection.

See also [[use-ast-grep-for-structural-code-search]], [[md-tools-usage-mdsplit-and-mdtable]].
