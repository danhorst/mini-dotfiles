End-of-session memory triage.
Compare live memory against the cemented seed set and resolve each divergence in whichever direction makes sense per file.
Live can drift behind cemented when a seed update wasn't mirrored — promotion isn't always the right move.

## Steps

1. Compute paths:
   - `CLAUDE_ROOT="$(dirname "$(readlink ~/.claude/commands)")"` (see dotfiles/claude/README.md).
   - Cemented seeds: `$CLAUDE_ROOT/memory/`
   - Live memory: `~/.claude/projects/<encoded-cwd>/memory/` where `<encoded-cwd>` is `$PWD` with `/` replaced by `-`.

2. Classify each `*.md` in live (excluding `MEMORY.md`):
   - **New** — in live, not in cemented. Likely an agent-added memory worth promoting.
   - **Changed** — in both, content differs.
   - **Excluded** — cemented version has `cement: false` in its frontmatter. Report briefly, do not offer.
   - **Unchanged** — identical. Ignore silently.

3. For each changed file, look for staleness signals in the LIVE version's frontmatter.
   Either signal below suggests the live file is older than the cemented seed — drift from a seed update never mirrored to live, not a deliberate edit; mark the recommendation as **re-sync from cemented** in that case, otherwise default to **cement live to cemented**.
   - An `originSessionId:` field (auto-memory system metadata; cemented seeds never carry this).
   - Flat `type:` rather than the `metadata.type:` wrapper (pre-spec format).

4. If no candidates remain after exclusions, report "no memory changes to cement" and stop.

5. For each new/changed candidate, show DBH:
   - Filename and classification (new / changed / changed-with-stale-live).
   - `description:` from frontmatter.
   - For changed files: a brief diff (`difft` preferred, or `git diff --no-index --stat`).

6. Ask DBH the direction per file via `AskUserQuestion` (single-select per question, batched in groups of up to 4 if needed).
   For changed-with-stale-live files, present "Re-sync" first and label it Recommended; for new files and clean-changed files, present "Cement" first and label it Recommended.
   - **Cement** (live → cemented): promote via `cement-memory.sh <filenames>`.
   - **Re-sync** (cemented → live): `cp` the seed over the live file.
   - **Skip**: leave the divergence.

7. Apply the selected actions.
   `cement-memory.sh` regenerates `MEMORY.md` from frontmatter and refuses any file marked `cement: false`.

8. Run `git -C "$CLAUDE_ROOT" status` so DBH can see what's staged. **Do not commit** — leave the working state clean for DBH's review.
