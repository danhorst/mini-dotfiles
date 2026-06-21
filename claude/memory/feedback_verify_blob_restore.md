---
name: Verify a dangling blob before restoring
description: A recovered lost file can be a stale version; diff it semantically against HEAD before writing it back
metadata:
  type: feedback
---

When a file's uncommitted working-tree change disappears and you recover it from a `git fsck` dangling blob, do NOT restore by size/diff-shape match alone — that match is weak and can pick a stale historical copy.

On 2026-06-21 an uncommitted `claude/settings.json` change vanished during a commit (cause never confirmed — possibly the markdown pre-commit hook, possibly a live-config rewrite; the file may be linked to live `~/.claude/`).
The dangling blob I matched by diff-shape and restored turned out to be a pre-June-16 version: it reintroduced a retired `UserPromptSubmit` sync hook (firing an error every prompt) and silently dropped the current `SessionStart` seed-memory hook, the `PreToolUse` hook, and a permission.
It was a regression, not the intended edit.

**Why:** restoring a stale config silently removes live functionality and is hard to notice.
**How to apply:** before writing a recovered blob over a file, diff it *semantically* against HEAD (`git show HEAD:path` then compare hook keys, permission entries, structure), not just by line count.
If the blob drops things HEAD has, it's stale — prefer `git checkout HEAD -- path`.
Recover dangling blobs with `git fsck --lost-found` before GC reclaims them.
Also: stage or stash unrelated changes before committing in this repo, since an unstaged change went missing around commit time.
