---
name: Spec pipeline status
description: Multi-model spec-driven dev pipeline — front half built; bake-off now n=3, SDD's envelope bounded both sides (thesis pays only in a middle band)
metadata:
  type: project
---

DBH is building a cost-optimized, spec-driven dev pipeline: idea → `/spec` → `/second-opinion` review → refine → cheap-model implement → spec-compliance review.
The bake-off (`experiments/sdd-bakeoff/`) is the experiment deciding the spec-granularity question empirically, to bound where SDD is worth its overhead.
Context behind the mandate is deliberately oblique in the repo (external SDD push) — keep it that way.

**Front half (shipped, branch `review-skills`):** `/spec` (`claude/commands/spec.md`, markdown-only) and `/second-opinion` (`claude/commands/second-opinion.md` + `claude/bin/second-opinion.sh`, wraps `codex exec` with auth-aware fallback).

**Bake-off rig (`experiments/sdd-bakeoff/`, moved here from top-level `bakeoff/` 2026-06-19):** `README.md` (the why-layer), `SPEC.md`, `RUNBOOK.md`, `rubric.md`, `prompts/`, `grant.sh`, `fixtures/<name>/{SPEC.md,checklist.md,gate.sh}`, `fixtures/CANDIDATES.md` (queued fixtures + selection criteria), `results/<date>/findings.md` + `results/README.md` (the standing envelope roll-up).
Cells = real approaches: control (Opus mono) ≈ work directly with a capable model; thesis (decompose→cheap-implement) ≈ the SDD workflow; challenger/diagnostic isolate decomposition from model price.
Eligibility bar: green + 100% compliance + design ≥ 4.

## Bake-off results — the envelope so far (read `results/README.md` for the live table)

- **`lint` (medium), n=1, 2026-06-17:** thesis won — cheapest *eligible* path ($2.13), ~43% under monolithic Opus at equal quality; Haiku-direct was ineligible (3/9), so decomposition was the bridge. Quality bar discriminated hard (3/9 → 9/9).
- **`json-sort` (small), n=2, 2026-06-19:** thesis *lost* — all four cells green first try at 6/6, design ≥ 4 (quality saturated), so the cheap direct path (diagnostic, $0.22) is cheapest eligible and thesis is dearest ($1.02, 4.7×). Decomposition's fixed cost ($0.68) alone exceeded monolithic Opus's whole run ($0.50).
- **`lint+` (large), n=3, 2026-06-19 (`results/2026-06-19-lint+/`):** thesis *lost differently* — the upper bound. Thesis-implementer sweep (Haiku→Sonnet→Opus on one shared work order): the cheap arm (thesis-Haiku) **converges green at 12/12 compliance but design drops to 3** — the handoff breaks on *design, not convergence* (a keyless-config-override bug the single-key fixture can't catch). The thesis tiers that hold design ≥ 4 (Sonnet $5.07, Opus $5.19) both cost *more* than monolithic Opus (**control, $4.52, 12/12, design 4 — cheapest eligible**), because they pay the $1.10 spec tax on a capable implementer. Decomposition still lifted Haiku over direct (diagnostic 10/12 d2 → thesis-Haiku 12/12 d3), just one design point short of the bar.

**Net (n=3):** the thesis altitude pays only in a *middle band*, bounded both sides.
The Haiku thesis arm is eligible only at `lint`: ineligible-because-saturated below (`json-sort`), cheapest in the middle (`lint`), ineligible-because-design-degrades above (`lint+`).
Outside the band use one model directly — cheapest-that-clears below, most-capable above.
Subtle catch (still open): on `json-sort` thesis added latent robustness the bar can't see; the eligibility bar may be too coarse to credit decomposition.

## Harness status — VALIDATED (three runs)

All paths fired: clean-room isolation, headless implementers (need the `bypassPermissions` grant — DBH runs `grant.sh on`; the classifier blocks the agent from granting it; revoke with `grant.sh off` after), cost capture, skip-aware + absent-fixture-aware gate, blind Opus grader, retry loop, `is_error` void rule.
Standing upgrade from `json-sort`: **grade against a copied clean source tree, not the working clean room** (the room's `WORKORDER.md`/run JSON unblind the grader).
`lint+` stress-tested the rest: (1) **session limits are the real operational constraint** — launching 6 large-fixture implementers in parallel exhausted the ~5h usage window mid-build and voided two whole waves; the fix is to **run cells serially** (gate one before launching the next) after reset, and the `is_error` void-and-rerun-from-clean rule held (~$10 discarded, not attributed).
A run that produces files but no result JSON is likewise void.
(2) Every `lint+` cell needed ≥1 retry on two immutable-gate traps the larger fixture introduced: `cmd/lint` building an exe named `lint` collides with the `lint/` dir; the gofmt rule's malformed `bad/` fixture trips tree-wide `gofmt -l .`
(fix: `internal/meta` multi-package trick; store gofmt bad input as `.txt`).
(3) Pre-grade leak scan caught a real `WORKORDER`-referencing source comment in thesis-opus — scrub the copied grade tree, don't regrade the room.
`run.sh` still deferred (hand-run via `RUNBOOK.md`).

## Open threads

- **Envelope is bounded both sides (n=3 done).** Next experimental moves, if continuing: a fixture *inside* the band to confirm the middle (between `lint` and `lint+`), or a parallelism axis (the rig's premise that thesis wins under fan-out is untested — all runs so far are single-implementer).
- **Build the pipeline's back half** at the decomposed work-order altitude — but gate it on task complexity: n=3 says decompose-then-cheap pays only in the middle band, so the back half must *choose* between decompose-then-cheap and direct-to-capable by task size (cheapest-that-clears below the band, most-capable above).
- **Rig-improvement signals** (not yet actioned): eligibility bar too coarse to credit decomposition's latent robustness; **fixture-gap revisions queued** — `json-sort` (number/HTML/dup-key byte-stability) and now `lint+` (`io=stdin` + `--staged` materialization unexercised; single-key config can't test per-key inheritance; `--changed [REF]` form unpinned; fix-command output unenforced) — each needs a *new fixture revision*, not an edit (fixtures are immutable). Codify `run.sh` from the hand-run rig.
- Volatile run artifacts in `/tmp/sdd-bakeoff/*`; durable record is the committed fixtures, `results/`, and this memory.

**Why:** the back-half skills assume a spec altitude, and the bake-off now has n=3 evidence that the decomposed altitude pays only in a middle complexity band — it loses below (saturated) and above (cheap-implementer design degrades).
**How to apply:** build the back half to choose decompose-then-cheap vs direct-to-capable by task complexity, not default to decomposition; cut the queued fixture revisions before trusting the bar to credit decomposition.
