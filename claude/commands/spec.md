Draft a formal spec at DBH's house altitude, built so a cheaper model can implement it without the conversation that produced it.
The spec is the artifact that threads the whole workflow — outside review reads it, the implementer consumes it, compliance review grades against it — so its structure is load-bearing, not cosmetic.

No script backs this command.
Spec drafting is generative judgment with no stable procedural part to extract; scripting it would be ceremony.

## Skeleton

Mirror `lint/SPEC.md` and `bakeoff/SPEC.md`.
The spine, in order:

- **Goals** — what the system is for, in a few rules-first bullets.
- **Model** — the conceptual pieces and how they relate. The seams live here.
- **Domain sections** — the specifics, named for the thing they cover.
- **Pinned decisions** — the choices made and their one-line why, so they are not relitigated.
- **Testing** — how each piece is proven.
- **Layout** — where the files land.
- **Done** — the normative checklist (see below).
- **Growth** — where this extends if it outlives its first home.

## What every spec must carry

These are the parts that are easy to omit and expensive to lack.

1. **A normative checklist — the `Done` section.**
   Verifiable items, each a claim someone can prove true or false against the finished code.
   This is the compliance oracle the implementer aims at and review grades against. Every spec ends with one.
2. **MUST / SHOULD tagging.**
   Mark which constraints are normative — graded, non-negotiable — and which are advisory — the implementer's discretion.
   A `Done` item is automatically a MUST; a pinned decision may be either. Do not mix a requirement and a preference silently, or review cannot tell a violation from a free choice.
3. **An eligibility bar, when the spec will be measured or compared.**
   Define what "good enough" means before any work starts — the acceptance threshold, not a vibe.
4. **Context-free framing.**
   The implementing model has none of the conversation that produced this. Externalize every implicit decision, or it is lost at the handoff.
   Same discipline as a memory seed: write for the reader who arrives cold.

## Style

Match the repo.
One sentence per line, terse, rules-first, sparse prose.
Pin decisions with a brief why; do not narrate alternatives you discarded.

## After drafting

State what "done" looks like for the spec itself, then offer the next step: outside review via `/second-opinion`, which reads exactly the artifact this produced.
