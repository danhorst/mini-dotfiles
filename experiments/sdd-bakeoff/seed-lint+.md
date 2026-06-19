# seed prompt — lint+ upper-bound run

Paste the block below into a fresh Claude Code session in this repo to run the `lint+` fixture.
The fixture is already written (`fixtures/lint+/`); this run is execution, not authoring.
First read `bakeoff` orientation: `experiments/sdd-bakeoff/README.md`, then `SPEC.md` and `RUNBOOK.md`.
Confirm `experiments/sdd-bakeoff/grant.sh status` is `present` before launching implementers — DBH runs `grant.sh on` (the classifier blocks the agent from granting it), and `grant.sh off` after.

---

We are running the `lint+` fixture through the spec-granularity bake-off to map the **upper bound** of SDD's operating envelope — the task complexity at which the spec-to-implementer handoff stops converging.
This is the n=3 point. n=2 (`json-sort`, small) found the thesis *loses* below the floor; `lint` (medium) found it wins; `lint+` (large) tests where it breaks.
See `experiments/sdd-bakeoff/results/README.md` for the envelope so far.

The fixture is `experiments/sdd-bakeoff/fixtures/lint+/` (SPEC.md, checklist.md, gate.sh already written).
Read `RUNBOOK.md`, then execute the four base cells — control (Opus), challenger (Sonnet), diagnostic (Haiku), thesis — exactly per the runbook, **and** run the thesis **implementer sweep** (RUNBOOK "Implementer sweep"): decompose/review once, then implement that work order with Haiku, Sonnet, and Opus, each gated and graded independently.

- clean-room each cell, launch the implementer headless, gate with the fixture's `gate.sh`, retry to a cap of 3, voiding any `is_error` infrastructure run;
- blind-grade each green cell with a separate read-only Opus grader against a **copied clean source tree** (never the working clean room — it carries the seed `WORKORDER.md`/`SPEC.md` and run JSON that unblind the grader), grepping the assembled input for leak terms first, never naming the cell;
- resolve eligibility (green + 100% compliance + design ≥ 4) and compare dollars-to-green only among eligible cells.

This is the expensive run: large fixture, plus the sweep's extra thesis implementations, plus likely retries (Haiku may go non-convergent — that is itself the upper-bound signal).
Budget well above `json-sort`'s ~$2.80; if usage is tight, run the four base cells first and defer the Sonnet/Opus sweep arms.

Write the cell table (with the per-tier thesis sweep), per-cell cost breakdown, and grades to `experiments/sdd-bakeoff/results/<date>/findings.md`, pinning model IDs and CLI versions.
Then update `results/README.md` (the envelope roll-up), mark `lint+` done in `fixtures/CANDIDATES.md`, and refresh the `project_spec_pipeline` memory.
Report whether the handoff converges across tiers and where it breaks — this is the n=3 point that closes the envelope from above.

---
