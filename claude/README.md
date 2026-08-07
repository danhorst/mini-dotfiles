# Claude Code configuration

Personal Claude Code config for DBH's workstation.
Three layers — an always-loaded base prompt, a per-project memory system, and a set of harness hooks — cooperate to keep per-session context lean while pushing mechanical rules to enforcement-time.

## Layout

```
bin/          hook scripts and helpers, incl. bin/memory (adapter for the shared engine)
commands/     slash commands (e.g. /wrap-it-up)
etc/          data files consumed by hooks (extension lists)
fixtures/     reference templates consumed by commands (e.g. release/)
CLAUDE.md     always-loaded judgment-driven rules
settings.json harness config: hooks, permissions, model
```

The memory seed corpus and its engine are harness-agnostic and live one level up, in `../agents/memory/` and `../agents/bin/memory` — see [`../agents/README.md`](../agents/README.md) and "Memory: seed and cement" below.

## Path resolution

Skills reference this directory's own subdirectories (`fixtures/`, `etc/`) without hardcoding a machine-specific path.
`~/.claude/commands` is a symlink to `commands/` here, and is guaranteed to exist wherever Claude Code runs — skills resolve everything else relative to it:

```
CLAUDE_ROOT="$(dirname "$(readlink ~/.claude/commands)")"
```

`$CLAUDE_ROOT` is this directory (`dotfiles/claude`).
Skills use `$CLAUDE_ROOT/fixtures/...`, etc. instead of writing out `~/git/danhorst/dotfiles/claude/...`, so they still resolve correctly if the checkout moves.
The shared `agents/` directory resolves the same way, one level up: `$CLAUDE_ROOT/../agents`.

## The layered model

**CLAUDE.md** loads into the system prompt every turn.
Reserved for rules that need LLM reasoning per-task: surgical changes, authorship boundaries, when to push back, project-context judgment.

**Memory** lives at `~/.claude/projects/<encoded-cwd>/memory/`, per-project.
The `MEMORY.md` index always loads; individual memory files load when relevance fires or when explicitly recalled.
Used for identity, workstation facts, and judgment-driven tool choices that hooks can't enforce.

**Hooks** are registered in `settings.json` and executed by the Claude Code harness.
Used for rules that can be mechanically checked at tool-call time.

## Memory: seed and cement

Memory files in `../agents/memory/` are *cemented seeds* tracked in git — the corpus and its engine (`agents/bin/memory`) are shared across harnesses; see [`../agents/README.md`](../agents/README.md) for the frontmatter schema and the seed/cement/lint model.
`bin/memory` in this directory is Claude Code's adapter: it resolves this harness's seed and live-copy paths and delegates to the shared engine, so every subcommand (`seed`, `cement`, `resync`, `index`, `lint`, `fix`, `triage`) behaves exactly as before.

At every session start, `memory seed` (a `SessionStart` hook) populates the live memory dir non-destructively — it only fills gaps, never overwrites live state.

Live edits stay live until deliberately promoted via `/wrap-it-up`, which triages new and changed live files and calls `memory cement` to copy selected files back into the seed set and regenerate `MEMORY.md`.

Templated seeds carry `cement: false` in their frontmatter.
`memory cement` refuses to overwrite them, so the template stays canonical (currently used only by `reference_workstation.md` to inject host RAM and arch via `envsubst`).

Write seeds from the agent's runtime point of view, not the dotfiles maintainer's tree view.
After deploy, the live memory lives at `~/.claude/projects/<encoded-cwd>/memory/` with no line of sight to `CLAUDE.md` or the hook scripts — references like `claude/etc/` or `bin/tool-prefs-check.sh` become noise the agent can't act on.
CLAUDE.md is loaded into the system prompt by name, so referring to it works but rarely adds value; hooks deliver their output directly, so naming the script that ran is redundant.

## Hooks

- **`PreToolUse` on `Bash`** — `bin/tool-prefs-check.sh` warns when a command's first word is a POSIX default (`grep`, `find`, `sed`, `awk`) that has an established replacement. Context-aware: extension match on positional args, plus `-r` / `--recursive` heuristic for grep. Extension lists live in `etc/`.
- **`PostToolUse` on `Write` / `Edit`** — `bin/md-format-check.sh` warns when written markdown under `~/git/danhorst/` would be reshaped by `mdsplit | mdtable`. Alongside the existing shellcheck and settings.json sort hooks.
- **`SessionStart`** — `memory seed` populates the live memory dir from the cemented seeds.

## Attribution

The structural shape of `CLAUDE.md` — numbered imperative sections, "rule first, brief why" — is influenced by the Karpathy-style `CLAUDE.md` at <https://github.com/multica-ai/andrej-karpathy-skills>.
The seed-and-cement workflow, the layered-model split, and the hook architecture are this repo's own.
