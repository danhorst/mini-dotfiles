# seed prompt — second bake-off run

Paste the block below into a fresh Claude Code session in this repo to kick off a generalization run.
Do two things first: write the new fixture under `experiments/sdd-bakeoff/fixtures/<NAME>/` (copy `fixtures/lint/` as the template — `SPEC.md`, tool-level `checklist.md`, `gate.sh`; vary task **size**, hold the language constant), and run `experiments/sdd-bakeoff/grant.sh on` to enable the implementer permission.
When copying `gate.sh`, adapt its "rule fixtures exercised" check: it hardcodes lint's component names (`shellcheck settings-sort md-shape`), so on a different fixture it must list that fixture's own components or it always fails; the build/vet/fmt/test/no-skip scaffolding copies unchanged.

---

We are running a second fixture through the spec-granularity bake-off to test whether the n=1 result generalizes: on fixture one (`lint`), the thesis cell — Opus decomposes a work order, a cheap model implements it — was the cheapest *eligible* path and beat monolithic Opus by ~43% at equal quality.
See `experiments/sdd-bakeoff/results/2026-06-17/findings.md`.

The new fixture is `experiments/sdd-bakeoff/fixtures/<NAME>/` (SPEC.md, checklist.md, gate.sh already written).
Read `experiments/sdd-bakeoff/RUNBOOK.md` and `experiments/sdd-bakeoff/SPEC.md`, then execute all four cells — control, challenger, diagnostic, thesis — exactly per the runbook:

- clean-room each cell, launch the implementer headless, gate with the fixture's `gate.sh`, retry to a cap of 3, voiding any `is_error` infrastructure run;
- blind-grade each green cell against `checklist.md` with a separate read-only Opus grader, never naming the cell;
- resolve eligibility (green + 100% compliance + design ≥ 4) and compare dollars-to-green only among eligible cells.

Confirm `experiments/sdd-bakeoff/grant.sh status` is `present` before launching implementers.
Write the four-cell table, per-cell cost breakdown, and grades to `experiments/sdd-bakeoff/results/<date>/findings.md`, pinning model IDs and CLI versions.
Report whether the thesis win holds at this task size and how cost-to-green moved — this is the n=2 point that begins to map the crossover.

---
