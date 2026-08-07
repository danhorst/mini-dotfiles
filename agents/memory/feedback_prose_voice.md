---
name: Prose voice for dev artifacts
description: Match DBH's plain declarative prose for dev artifacts; avoid clever emphatic Claude-isms — essay voice is human-only
metadata:
  type: feedback
---

For dev artifacts (READMEs, GUIDANCE, findings), DBH wants prose tuned to his conventions, not the default verbose Claude register.
Sample of his personal voice: https://www.danhorst.com/ai.txt

Mechanics to mirror: short declarative anchors carrying longer reasoning sentences; plain vocabulary with the occasional precise word; antithesis ("A capable model infers them.
A cheap model doesn't."); idea-stacking paragraphs; one sentence per source line.

Em-dashes: he embraces them, deliberately, to adjust cadence toward spoken word / transcribed thought — appending a clause or a parenthetical (https://www.danhorst.com/writing/dash-it-all.txt).
Do NOT strip them out fearing the "em-dash = AI" trope; he explicitly rejects that.
The only fault is clause-chaining (three clauses dashed into one breathless sentence) and overuse.
A single purposeful dash is his style.

Reads as "Claudy" / avoid: emphatic or clever diction ("the reductio", "earned its keep", "bit as predicted"), dramatic restatement, self-referential grandiosity ("exactly the failure X exists for", "the precise condition the README names"), bold lead-ins on every bullet, em-dash clause-chaining.

**Why:** he uses writing to think and is allergic to AI slop; the existing bake-off docs were "very Claudy." **How to apply:** keep his repo structure (rules-first, tables, bullets) for dev artifacts — his all-prose essay habit is the byline voice, which per [[dbh-profile-and-working-dynamics]] and CLAUDE.md §4 is human-only.
Borrow the mechanics, don't imitate the essay.
