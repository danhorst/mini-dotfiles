# results — the envelope so far

The standing roll-up across fixtures: one row per task size, read left to right as the SDD operating envelope.
Per-run detail (cost breakdowns, grades, spec-gaps, pinned versions) lives in each `<date>/findings.md`.

| Fixture     | Size   | Cheapest eligible | Thesis vs cheapest eligible                                      | Quality spread             | Reading                                   | Run                                        |
| ----------- | ------ | ----------------- | ---------------------------------------------------------------- | -------------------------- | ----------------------------------------- | ------------------------------------------ |
| `json-sort` | small  | diagnostic $0.22  | thesis $1.02 — 4.7× dearer                                       | saturated (all 6/6, ≥4)    | below the floor — skip SDD                | [2026-06-19](2026-06-19/findings.md)       |
| `lint`      | medium | thesis $2.13      | thesis is cheapest                                               | wide (3/9 → 9/9)           | decomposition pays                        | [2026-06-17](2026-06-17/findings.md)       |
| `lint+`     | large  | control $4.52     | no thesis tier eligible-cheaper; thesis-Haiku 12/12 but design 3 | wide (10/12 d2 → 12/12 d4) | above the ceiling — use one capable model | [2026-06-19](2026-06-19-lint+/findings.md) |

## Reading so far (n=3)

The thesis altitude — Opus decomposes a work order, a cheap model implements it — is the right tool in a *band*, now bounded on both sides.

- **Lower bound, bracketed.** Between `json-sort` and `lint` complexity the thesis flips from most-expensive-eligible to cheapest-eligible, and the cheap direct path (diagnostic) flips from ineligible to the winner.
  Below that band, quality saturates — every cell clears the bar — so decomposition has nothing to lift and is pure overhead; on `json-sort` its fixed cost ($0.68) alone exceeded monolithic Opus's entire run.
- **Upper bound, mapped.** At `lint+` the thesis-implementer sweep (Haiku → Sonnet → Opus) shows the handoff breaking on *design, not convergence*: the cheap arm (thesis-Haiku) converges green at 12/12 compliance but the blind grade drops it to design 3, so it falls out of eligibility — while the thesis tiers that hold design ≥ 4 (Sonnet, Opus) both cost more than just handing the whole spec to monolithic Opus ($4.52, the cheapest eligible cell). Above the band, decomposition buys the cheap model compliance but not design, and the spec tax on a capable implementer is never recouped.
- **The band is bounded on both sides.** The thesis (Haiku) arm is eligible only in the middle: ineligible-because-saturated below (`json-sort`), cheapest in the middle (`lint`), ineligible-because-design-degrades above (`lint+`). Outside the band, use one model directly — the cheapest that clears the bar below it, the most capable above it.
- **The dollar crossover is a floor.** Cost here is cash API spend only; the human time to run, retry, and review the pipeline is zeroed (and `lint+` needed retries on every cell across two voided session-limit windows), so the practical band is narrower than the dollar figures suggest.
