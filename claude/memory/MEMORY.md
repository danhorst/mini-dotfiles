# Memory Index

- [DBH profile and working dynamics](user_profile.md) — Who DBH is and the tensions shaping how he works with agents
- [Workstation specs](reference_workstation.md) — Hardware facts for this machine — RAM and architecture — that drive context-discipline decisions
- [project-footnote-handling](project_footnote_handling.md) — How md-tools treats markdown footnotes and the danhorst.com parity/rendering constraints behind it
- [project_shell_config_naming](project_shell_config_naming.md) — "shell config files named \"zsh\" are deliberately kept bash-compatible"
- [Spec pipeline status](project_spec_pipeline.md) — Multi-model spec-driven dev pipeline — front half built; bake-off now n=3, SDD's envelope bounded both sides (thesis pays only in a middle band)
- [Use ast-grep for structural code search](feedback_ast_grep.md) — Reach for ast-grep over rg/grep when searching code constructs or doing multi-site refactors
- [feedback_config_ownership](feedback_config_ownership.md) — "where machine/tool-specific config belongs — in the tool, not the dotfiles repo"
- [md-tools usage — mdsplit and mdtable](feedback_md_tools.md) — Pipe mdsplit into mdtable -i to round-trip a file; use &#124; not \| for pipes in table cells
- [Prose voice for dev artifacts](feedback_prose_voice.md) — Match DBH's plain declarative prose for dev artifacts; avoid clever emphatic Claude-isms — essay voice is human-only
- [feedback_skill_path_resolution](feedback_skill_path_resolution.md) — "Claude Code skills must resolve dotfiles/claude paths dynamically via the ~/.claude/commands symlink, never hardcode ~/git/danhorst/dotfiles/..."
- [Judgment-driven tool choices](feedback_tool_prefs.md) — Structural diffs (difft) and situational tools (scc/watchexec/bat/tv); the PreToolUse hook covers mechanical substitutions
- [Verify a dangling blob before restoring](feedback_verify_blob_restore.md) — A recovered lost file can be a stale version; diff it semantically against HEAD before writing it back
