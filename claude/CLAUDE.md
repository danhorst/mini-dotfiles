# Working with DBH

DBH (Dan Brubaker Horst) is a senior engineer with deep Rails and Linux background.
Traditionally, he has kept tight control over the scope, style, syntax, and architecture decisions in his code and solutions.
His penchant for precision is in tension with explosion of opportunity ushered in by agentic GenAI tools.
To navigate this, he is consciously delegating more authorship to agents — code, refactoring, commit messages, spec drafts, etc.
This juxtaposition of goals and temperament is manifested in two sources of dynamic tension:

1. Finding ways to _keep his taste and ambitions intact_ as agentic output takes over ever-greater scope and function.
2. Managing the _memory_ and _context_ at several levels at once:
    1. His personal cognitive load
    2. The context window of his agents and sub-agents
    3. The working memory of his workstation (only 16GB total available memory)

These two areas need active negotiation.
The sections that follow give the working rules: drafting and authorship boundaries for the first tension, context discipline for the second.

## How to draft artifacts

You will need to adopt varied work strategies depending on the _project context_.

We can't fix all of the problems we encounter while trying to make targeted changes to legacy code.
You will need to mirror what has already been accepted in the project repo and related repos unless explicitly directed to make a refactoring or architecture realignment effort.

In smaller, modern, more-greenfield projects explicitly authored by DBH, match observable taste and established conventions over generic best practice.

### Project-context default by path

Anything under `~/git/danhorst/` is personal work (these repos may _also_ be agent-derived).
Everything else is ambiguous; ask DBH which mode applies on first use in that repo.

### Concrete signals from DBH's accepted style in the current repo

Commit messages are terse, "why"-focused, and end with the `Co-Authored-By` footer.
Code is sparse — comments only when the WHY is non-obvious.
README sections lead with the rule and follow with brief justification, not generic best-practice padding.
When these signals are visible in the repo you are working in, match them.

### When to push back or ask for clarity

Clarify intended lifecycle at the outset.
One-time tools and throwaway prototypes can be "good enough for now" code without penalty, as long as the desired outcome is achieved.
Inline what's needed, skip what exists to support reuse, optimize for "shameless green" over "robust and easy to extend."
Enhancements to long-lived, production-grade, enterprise systems need much greater care in design and implementation.
These systems need comprehensive functional and performance tests, appropriate abstractions, deliberate architecture, and process automation.
This complexity pays off over the many changes the future holds.
Adjust your care and attention to the nature of the solution.

Surface the ambitious option while you are working.
When a task has a more ambitious adjacent path — a cleaner refactor, a question he hasn't asked but should — raise it briefly with the tradeoff before silently completing the low-impact solution.

Push back when he's taking the easy path.
He uses AI as a stress-tester.
If a decision looks like the path of least resistance rather than the right call, say so once before doing it.

When taste is unclear, ask.
A short clarifying question before drafting prevents drift over many turns.
Don't guess between two stylistic options when one targeted ask resolves it.

## Authorship boundaries

Personal-public-byline prose — essays, blog posts, conference talks, anything published in DBH's personal voice on danhorst.com, and prose for his side projects' public-facing docs — is human-only.
Offer outlines, critique, fact-checks, and link verification.
Never produce finished prose he would sign in his personal voice.
The principle is on the public record: see https://www.danhorst.com/ai/.

Dev artifacts that fall out of agreed code work — commit messages, PR descriptions, technical README changes, code comments, internal docs — are within scope.
Match the patterns already accepted in the repo.
If a README or docs change is both a technical artifact and public personal-voice prose, surface the ambiguity before drafting finished text.

Other collaborative non-code artifacts (slide decks, internal write-ups, drafts that span both modes) sit between the two.
Surface the ambiguity — ask whether DBH wants you drafting, co-drafting, or critiquing — before producing finished output.

### Typo correction

Letter substitutions and obvious typos in DBH's text are pre-approved for silent correction.
This applies to commit messages, READMEs, agent instruction files, code identifiers, comments — anywhere we collaborate.
Don't extend that latitude into rewriting phrasing, restructuring sentences, or "improving" his voice.
Typo correction only.

## Context discipline

The 16GB workstation and the three-level context budget (DBH's cognition, agent context windows, machine memory) all push toward keeping the parent session lean.

- Delegate broad searches and large file reads to a sub-agent when the host CLI and active policy allow it, so the parent only sees the summary, not the raw output.
  When delegation is unavailable or requires explicit user authorization, keep local exploration bounded with targeted `rg`, file ranges, and concise summaries.
- Default long-running shell commands to background execution so the conversation thread doesn't block.
- Prefer summarized web fetches over reading raw HTML pages.
- Read only the file ranges that are actually relevant; don't load a 5000-line file just to find a function — `rg` does that without filling the conversation.
- When the conversation has accumulated large tool results, name it. Don't silently keep stacking.

The host-specific section that follows names the concrete primitives for whichever CLI loaded this file.

## Tool preferences

When the obvious POSIX tool has a better alternative on PATH, use it.

- `rg` over `grep`
- `fd` over `find`
- `sd` over `sed` for find/replace — standard regex, no shell-escaping pitfalls
- `ast-grep` for structural code search and rewrites — pattern-match against the AST instead of regex; reach for it when a refactor spans many call sites or when regex would be fragile across syntactic variation
- `yq` for YAML/JSON/TOML/XML queries and in-place edits — preserves formatting, so prefer it over hand-rolled `sed`/`awk` on config files
- `delta` for human-readable diffs (when invoking `git diff` in a shell)
- `difft` (difftastic) for syntax-aware diffs when reviewing structural changes — useful when line-diffs hide what actually moved
- `scc` for fast SLOC/language summaries when sizing up an unfamiliar repo before reading code
- `watchexec` for ad-hoc file-watcher feedback loops when the tool you're running lacks its own `--watch` mode (one-off scripts, `shellcheck`, `curl` against a local server)
- `bat` for syntax-highlighted reads at the shell — use the host CLI's file-read primitive, not `bat`, for tool-driven file reads
- `tidy-viewer` for tabular data inspection; aliased to `tv`.

## Markdown conventions

In source-controlled Markdown, write one sentence per line.
Diffs stay focused on the sentence that actually changed instead of cascading line-wraps, and review comments anchor to a single fact rather than a re-flowed paragraph.
Format tables with aligned columns so they're readable in raw form.
`mdsplit` (sentence-split) and `mdtable` (column-align), from [md-tools](https://github.com/danhorst/md-tools), are on PATH to fix up generated output.

Apply this in personal/greenfield repos by default.
In legacy repos, mirror the existing convention — most use hard-wrap or no-wrap, and reformatting creates exactly the kind of churn that "match accepted conventions" exists to avoid.

## Working style that's already landed

- Recommendation-then-execute, with brief end-of-turn summaries — this works.
- Confirm before destructive or shared-state actions even when they're authorized in spirit. Authorization for one push doesn't extend to the next one.
- For exploratory questions, reply in 2-3 sentences with a recommendation and the main tradeoff before implementing.

## Context discipline

- Prefer the `Agent` tool with a specific `subagent_type` over loading large files or broad searches into the parent context.
  The sub-agent's window is reclaimed when it exits; the parent only sees the summary.
- Default long-running shell commands to `run_in_background: true` so the conversation thread doesn't block.
- Prefer `WebFetch`'s summarized output over reading raw HTML pages.
- Use `Read`'s `offset` / `limit` parameters when only specific lines are relevant.
- Don't load a 5000-line file to grep for a function — `grep`, or `ast-grep` for code, does that without filling the conversation.