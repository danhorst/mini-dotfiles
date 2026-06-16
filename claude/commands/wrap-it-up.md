End-of-session memory triage: compare live memory against the cemented seed set, then promote the files DBH chooses.

## Steps

1. Compute paths:
   - Cemented seeds: `~/git/danhorst/dotfiles/claude/memory/`
   - Live memory: `~/.claude/projects/<encoded-cwd>/memory/` where `<encoded-cwd>` is `$PWD` with `/` replaced by `-`.

2. Classify each `*.md` in live (excluding `MEMORY.md`):
   - **New** — present in live, absent from cemented seeds
   - **Changed** — present in both, content differs
   - **Excluded** — cemented version has `cement: false` in its frontmatter (templated or otherwise non-cementable); report it briefly, do not offer it
   - **Unchanged** — identical; ignore silently

3. If no candidates remain after exclusions, report "no memory changes to cement" and stop.

4. For each new or changed candidate, show DBH:
   - The filename
   - The `description:` from its frontmatter
   - For changed files: a short diff (`difft` preferred, or `git diff --no-index --stat` for a brief summary)

5. Use `AskUserQuestion` (multiSelect: true) to ask which files to cement. One option per candidate, plus a "none of these" option.

6. Run `cement-memory.sh` with the selected filenames as positional args. It will refuse anything marked `cement: false` and regenerate `MEMORY.md` from frontmatter.

7. Run `git -C ~/git/danhorst/dotfiles status` so DBH can see what's staged. **Do not commit** — the cement step ends with a clean working state for DBH to review and commit deliberately.
