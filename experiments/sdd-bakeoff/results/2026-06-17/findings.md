# bake-off run — fixture `lint`, 2026-06-17

First run of the spec-granularity bake-off. n=1: directional, not a verdict.

## Method

One fixture (`experiments/sdd-bakeoff/fixtures/lint/`): the high-level `SPEC.md`, a deterministic `gate.sh` (build, vet, gofmt, `go test` with no skips), and a tool-level `checklist.md` of nine MUST items.

Four cells, each an isolated clean-room implementation taken to green (or a three-retry cap):

- **control** — Opus, one context, spec and code together, no handoff.
- **challenger** — high-level spec → Sonnet implements.
- **diagnostic** — high-level spec → Haiku implements.
- **thesis** — Opus drafts a decomposed work order → Opus adversarially reviews and refines it → Haiku implements that.

Each implementer ran headless via `claude -p --output-format json`; cost is `total_cost_usd` summed across the cell's runs (cash API spend).
Each green cell was scored by a separate blind Opus grader against `checklist.md` and `rubric.md`.
Eligibility = green + 100% compliance + design ≥ 4.

## Results

| Cell       | Spec altitude | Model     | Cost-to-green | Compliance | Design | Eligible |
| ---------- | ------------- | --------- | ------------- | ---------- | ------ | -------- |
| diagnostic | high-level    | Haiku     | $0.78         | 3/9        | 2      | no       |
| challenger | high-level    | Sonnet    | $2.32         | 7/9        | 3      | no       |
| thesis     | decomposed    | Haiku     | $2.13         | 9/9        | 4      | **yes**  |
| control    | high-level    | Opus mono | $3.73         | 9/9        | 4      | yes      |

Thesis cost-to-green = Opus draft $0.39 + Opus review $0.64 + Haiku impl $0.88 + Haiku retry $0.21.
Total experiment spend ≈ $11.5 (implementations, voided infra runs, and all blind grades).

## Findings

- **The pipeline beats monolithic Opus.** Two cells cleared the bar; among them the thesis is cheaper — same quality (both 9/9, design 4) for ~43% less than control ($2.13 vs $3.73). The original null hypothesis — "does any of this beat just handing it to Opus?" — is answered yes.
- **Why: split the token tiers.** Monolithic Opus pays premium rates for both the conceptual work and the mechanical typing. The thesis pays premium only for decomposition ($1.03) and cheap for implementation ($1.10). Same eligible result, less money.
- **The cheap model cannot do it alone.** Haiku on the high-level spec scored 3/9; the decomposed work order lifted the *same model* to 9/9 eligible. Decomposition is the bridge that makes a cheap implementer viable.
- **Capability and granularity are substitutes for the same gap.** The two failures both high-level cheap cells shared — inert `lint.toml`, no fix-command output — were recoverable spec ambiguities: Opus inferred them from the prose, Sonnet and Haiku did not. Decomposition resolves them for the cheap model the way raw capability resolves them for Opus.
- **The original suspicion is falsified.** "High-level spec + medium model is cheaper" loses twice: Sonnet-on-high-level is both ineligible (7/9) and pricier than the thesis.
- **Residual spec gaps are real.** `--changed`'s default ref and the check-only fix-command contract were left undirected by `lint/SPEC.md`; every cell, including control, resolved them by guessing. These grade the spec, not the cells.

## Harness

Every path fired: clean-room isolation, headless implementers, cost capture, the skip-aware gate, the blind grader, the retry loop (thesis converged after one round), and both eligible and ineligible outcomes.
The two-layer gate-plus-grade proved essential — the gate passed a green-but-hollow Haiku with zero rule coverage that the blind grade caught.

Two upgrades the run forced, now applied:

- The gate fails on *absent* rule-fixture tests, not only skipped ones (`gate.sh`); the diagnostic went green with no rule coverage.
- An implementer run that returns `is_error` for an infrastructure reason (a usage limit, a crash) is void, not non-convergence (`SPEC.md`, the fix loop); a session-limit interruption corrupted the first diagnostic mid-build.

## Recommendation

Build the pipeline's back half at the **decomposed work-order altitude** — that is the altitude the data endorses, and `/spec` should target it.
The implement and spec-compliance skills now have an evidence-based shape: decompose with an expensive model, implement with a cheap one, gate deterministically, grade blind.

Before trusting the magnitude, firm up the evidence: this is n=1, one run per cell, no variance repeats.
A second fixture of a different size would test whether the win generalises and begin to locate the crossover by task size and parallelism.
The hand-run rig should also be codified into `experiments/sdd-bakeoff/run.sh` carrying both upgrades above.
