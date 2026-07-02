# Claude Code configuration

Personal Claude Code config for DBH's workstation.
Three layers — an always-loaded base prompt, a per-project memory system, and a set of harness hooks — cooperate to keep per-session context lean while pushing mechanical rules to enforcement-time.

## Layout

```
bin/          hook scripts and helpers
commands/     slash commands (e.g. /wrap-it-up)
etc/          data files consumed by hooks (extension lists)
fixtures/     reference templates consumed by commands (e.g. release/)
memory/       cemented memory seeds, deployed at SessionStart
CLAUDE.md     always-loaded judgment-driven rules
settings.json harness config: hooks, permissions, model
```

## The layered model

**CLAUDE.md** loads into the system prompt every turn.
Reserved for rules that need LLM reasoning per-task: surgical changes, authorship boundaries, when to push back, project-context judgment.

**Memory** lives at `~/.claude/projects/<encoded-cwd>/memory/`, per-project.
The `MEMORY.md` index always loads; individual memory files load when relevance fires or when explicitly recalled.
Used for identity, workstation facts, and judgment-driven tool choices that hooks can't enforce.

**Hooks** are registered in `settings.json` and executed by the Claude Code harness.
Used for rules that can be mechanically checked at tool-call time.

## Memory: seed and cement

Memory files in `memory/` are *cemented seeds* tracked in git.
At every session start, `bin/seed-memory.sh` (a `SessionStart` hook) populates the live memory dir non-destructively — it only fills gaps, never overwrites live state.

Live edits stay live until deliberately promoted via `/wrap-it-up`, which triages new and changed live files and calls `bin/cement-memory.sh` to copy selected files back into the seed set and regenerate `MEMORY.md`.

Templated seeds carry `cement: false` in their frontmatter.
The cement script refuses to overwrite them, so the template stays canonical (currently used only by `reference_workstation.md` to inject host RAM and arch via `envsubst`).

Write seeds from the agent's runtime point of view, not the dotfiles maintainer's tree view.
After deploy, the live memory lives at `~/.claude/projects/<encoded-cwd>/memory/` with no line of sight to `CLAUDE.md` or the hook scripts — references like `claude/etc/` or `bin/tool-prefs-check.sh` become noise the agent can't act on.
CLAUDE.md is loaded into the system prompt by name, so referring to it works but rarely adds value; hooks deliver their output directly, so naming the script that ran is redundant.

## Hooks

- **`PreToolUse` on `Bash`** — `bin/tool-prefs-check.sh` warns when a command's first word is a POSIX default (`grep`, `find`, `sed`, `awk`) that has an established replacement. Context-aware: extension match on positional args, plus `-r` / `--recursive` heuristic for grep. Extension lists live in `etc/`.
- **`PostToolUse` on `Write` / `Edit`** — `bin/md-format-check.sh` warns when written markdown under `~/git/danhorst/` would be reshaped by `mdsplit | mdtable`. Alongside the existing shellcheck and settings.json sort hooks.
- **`SessionStart`** — `bin/seed-memory.sh` populates the live memory dir from the cemented seeds.

## Attribution

The structural shape of `CLAUDE.md` — numbered imperative sections, "rule first, brief why" — is influenced by the Karpathy-style `CLAUDE.md` at <https://github.com/multica-ai/andrej-karpathy-skills>.
The seed-and-cement workflow, the layered-model split, and the hook architecture are this repo's own.
