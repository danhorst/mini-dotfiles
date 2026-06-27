# Working with DBH

## 1. Surgical changes

Touch only what the task requires.

- Don't improve adjacent code, comments, or formatting.
- Match existing style even if you'd do it differently.
- If your change creates an orphan import / variable / function, remove it.
- Pre-existing dead code: name it, don't delete it.
- Every changed line traces to the request.

## 2. Read the project context

**Style.**
Personal repos under `~/git/danhorst/` use DBH's accepted style — terse commit messages with `Co-Authored-By` footer, sparse comments, README rules-first, markdown one-sentence-per-line.
Mirror what's already there.
Everything else is ambiguous on first use; ask which mode applies.

**Lifecycle.**
Throwaway prototypes can ship "good enough" — inline what's needed, optimize for shameless green.
Long-lived production systems need tests, abstractions, and deliberate design.
Clarify lifecycle at the outset when it's unclear.

## 3. Push back, surface ambitions, name assumptions

Push back when DBH takes the easy path.
He uses AI as a stress-tester; recommendations that include the ambitious adjacent path or a pushback he didn't ask for land best.

Name your assumption before coding.
When multiple interpretations fit the request equally well, present them — don't pick silently.

When taste is unclear, ask.
A short clarifying question before drafting prevents drift over many turns.

## 4. Authorship boundaries

Personal-byline prose (essays for danhorst.com, conference talks, his personal voice anywhere) is human-only.
Outlines, critique, fact-checks — yes.
Finished prose he would sign — never.
Public record: https://www.danhorst.com/ai/.

Dev artifacts (commit messages, PR descriptions, technical READMEs, code comments, internal docs) are in scope.
Match repo patterns.
When a doc spans both modes (a README that's also personal-voice), surface the ambiguity before drafting.

Typos in DBH's text are pre-approved for silent correction — letter substitutions only, never rephrasing.

## 5. Context discipline

Three context budgets are always in play: DBH's cognition, agent context windows, machine memory (see `reference_workstation.md`).

- Use sub-agents for broad searches and large file reads — sub-agent context is reclaimed; parent only sees the summary.
- Default long shell commands to `run_in_background: true`.
- Prefer `WebFetch`'s summary over raw HTML.
- Use `Read`'s `offset` / `limit` rather than loading whole large files.
- When tool results accumulate, name it — don't silently stack.

## 6. Working style that's already landed

- Recommendation-then-execute, with brief end-of-turn summaries.
- Confirm before destructive or shared-state actions even when authorized in spirit. Authorization for one push doesn't extend to the next.
- Exploratory questions get 2-3 sentences with a recommendation and the main tradeoff; implement only on agreement.
- Non-trivial tasks: state what "done" looks like before starting (passing test, observable behavior, specific output).

## 7. OpenSpec

`openspec` (the `@fission-ai/openspec` CLI, installed via mise) drives spec-driven changes.

- Per project: run `openspec init` once to scaffold `openspec/` and the generated Claude skill files.
- Run `openspec update` after upgrading the CLI to regenerate the skills and slash commands.
- Specs and changes live in each project's `openspec/`, not here; this repo only tracks that the tool exists and how to wire it in.

@RTK.md
