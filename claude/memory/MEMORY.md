# Memory Index

- [DBH profile and working dynamics](user_profile.md) — Who DBH is and the tensions shaping how he works with agents
- [Workstation specs](reference_workstation.md) — Hardware facts for this machine — RAM and architecture — that drive context-discipline decisions
- [project_claude_settings_live_writes](project_claude_settings_live_writes.md) — "Claude Code live-writes model into settings.json and reformats it; where that file is a symlinked tracked seed (this dotfiles repo) it shows perpetually dirty, and the durable model default lives in untracked settings.local.json"
- [project-footnote-handling](project_footnote_handling.md) — How md-tools treats markdown footnotes and the danhorst.com parity/rendering constraints behind it
- [project_shell_config_naming](project_shell_config_naming.md) — "shell config files named \"zsh\" are deliberately kept bash-compatible"
- [Spec pipeline status](project_spec_pipeline.md) — Multi-model spec-driven dev pipeline — front half built; bake-off now n=3, SDD's envelope bounded both sides (thesis pays only in a middle band)
- [Use ast-grep for structural code search](feedback_ast_grep.md) — Reach for ast-grep over rg/grep when searching code constructs or doing multi-site refactors
- [feedback_config_ownership](feedback_config_ownership.md) — "what belongs to the dotfiles repo vs the tool — don't track machine config there, and don't `brew install` (the Brewfile is the source of truth)"
- [md-tools usage — mdsplit and mdtable](feedback_md_tools.md) — Pipe mdsplit into mdtable -i to round-trip a file; use &#124; not \| for pipes in table cells
- [Prose voice for dev artifacts](feedback_prose_voice.md) — Match DBH's plain declarative prose for dev artifacts; avoid clever emphatic Claude-isms — essay voice is human-only
- [feedback-repo-bin-path](feedback_repo_bin_path.md) — "Project bin/ dirs are almost always on DBH's PATH (check .mise.toml); scripts there can shadow system binaries — write helper scripts to call system tools by absolute path"
- [feedback_skill_path_resolution](feedback_skill_path_resolution.md) — "Claude Code skills must resolve dotfiles/claude paths dynamically via the ~/.claude/commands symlink, never hardcode ~/git/danhorst/dotfiles/..."
- [feedback-sudo-escalation](feedback_sudo_escalation.md) — "For helper scripts needing root, self-escalate at the top — don't prime sudo mid-script"
- [Judgment-driven tool choices](feedback_tool_prefs.md) — Structural diffs (difft) and situational tools (scc/watchexec/bat/tv); the PreToolUse hook covers mechanical substitutions
- [Verify a dangling blob before restoring](feedback_verify_blob_restore.md) — A recovered lost file can be a stale version; diff it semantically against HEAD before writing it back
