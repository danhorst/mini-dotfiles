# results — the envelope so far

The standing roll-up across fixtures: one row per task size, read left to right as the SDD operating envelope.
Per-run detail (cost breakdowns, grades, spec-gaps, pinned versions) lives in each `<date>/findings.md`.

| Fixture     | Size   | Cheapest eligible | Thesis vs cheapest eligible | Quality spread          | Reading                       | Run                                  |
| ----------- | ------ | ----------------- | --------------------------- | ----------------------- | ----------------------------- | ------------------------------------ |
| `json-sort` | small  | diagnostic $0.22  | thesis $1.02 — 4.7× dearer  | saturated (all 6/6, ≥4) | below the floor — skip SDD    | [2026-06-19](2026-06-19/findings.md) |
| `lint`      | medium | thesis $2.13      | thesis is cheapest          | wide (3/9 → 9/9)        | decomposition pays            | [2026-06-17](2026-06-17/findings.md) |
| `lint+`     | large  | —                 | —                           | —                       | pending — handoff break point | queued                               |

## Reading so far (n=2)

The thesis altitude — Opus decomposes a work order, a cheap model implements it — is the right tool in a *band*, not a default.

- **Lower bound, bracketed.** Between `json-sort` and `lint` complexity the thesis flips from most-expensive-eligible to cheapest-eligible, and the cheap direct path (diagnostic) flips from ineligible to the winner.
  Below that band, quality saturates — every cell clears the bar — so decomposition has nothing to lift and is pure overhead; on `json-sort` its fixed cost ($0.68) alone exceeded monolithic Opus's entire run.
- **Upper bound, unmapped.** `lint+` (with a thesis-implementer sweep across Haiku → Sonnet → Opus) is the next run, and the one that finds where the spec-to-implementer handoff stops converging.
- **The dollar crossover is a floor, not the line.** Cost here is cash API spend only; the human time to run and review the pipeline is zeroed, so the practical "don't bother with SDD" threshold sits above the dollar crossover.
