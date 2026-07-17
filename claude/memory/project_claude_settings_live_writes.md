---
name: project_claude_settings_live_writes
description: "Claude Code live-writes model into settings.json and reformats it; where that file is a symlinked tracked seed (this dotfiles repo) it shows perpetually dirty, and the durable model default lives in untracked settings.local.json"
metadata: 
  node_type: memory
  type: project
  originSessionId: dd011166-5d6f-4c67-b2f3-9ad716fdf8ba
---

**Portable Claude Code behavior:** `/model` writes the model default as a top-level `model` key into the config dir's `settings.json` (config dir = `$CLAUDE_CONFIG_DIR`, default `~/.claude`), and the harness reformats/reorders that file on its own.
`settings.local.json` in the same dir is the untracked local-override companion; it's assumed to take precedence over `settings.json` (sticky) but that ordering is unverified — if a `/model` change stops persisting across sessions, this override is the likely cause, so change the durable default by editing the local file.

**This dotfiles setup:** `$CLAUDE_CONFIG_DIR/settings.json` is a symlink to the dotfiles repo's tracked `claude/settings.json`, so those live-writes land in the working tree — `git status` shows `claude/settings.json` dirty even right after a clean commit.
Leave it unstaged; treat the model/reformat drift as expected noise, not a bug to fix.

Guards keep the tracked file clean: the PostToolUse sort hook runs `del(.model) | .permissions.allow |= sort` (scoped to `settings.json` only, so it never strips the local override), and `.githooks/pre-commit` blocks a top-level `model` at commit time.
To commit a *real* `settings.json` change, reconstruct from HEAD and re-apply the minimal edit (`git show HEAD:claude/settings.json > claude/settings.json` then `sd -s …`) rather than staging the harness-reformatted copy — otherwise the diff is 60+ lines of reordering noise.
The durable model default lives in the untracked `settings.local.json` (gitignored via `claude/settings.local.json`), merged alongside its machine permissions.

**Why:** this cost real rediscovery time — the dirty-file churn triggered a false "config gutted" alarm ([[verify-a-dangling-blob-before-restoring]]), and a mid-commit harness rewrite forced a rebuild.
**How to apply:** don't "clean up" `settings.json`'s model/reformat drift by committing it; edit `settings.local.json` for machine-specific Claude config, consistent with [[feedback_config_ownership]].
