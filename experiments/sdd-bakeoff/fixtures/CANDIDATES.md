# fixture candidates

Where fixtures come from, and the ones queued to map the SDD complexity envelope.

Don't invent tasks to fit the rig.
Run these criteria over things you already want built, so every run yields a kept artifact *and* a data point.

## Selection criteria

- **Independent value** — you'd want the artifact even with no experiment attached.
- **A natural correctness oracle** — `in → out`, expressible as `ok/bad/fixed` fixtures a test reads.
- **A carve-able core** — the valuable logic doesn't need the surrounding repo; integration is a thin skin you can drop (as `lint`'s checklist dropped its repo-integration Done items).
- **A deliberate size** distinct from the points already run.

## The oracle-shape constraint

The rig naturally fixtures file-transformers and checkers, because that is where a deterministic gate has something to bite — and that is the same domain where harness engineering pays.
Tasks with fuzzy or environment-coupled oracles (system reports, memory orchestration, the rig's own `run.sh`) are both hard to fixture and hard to gate.
Their absence here is a scope signal about where SDD-with-a-gate is the right tool, not a gap to fill.

## Queued

| Fixture     | Bound           | Task                                                                                                                                                            | Oracle                           | Status                                                                                                                                                                                           |
| ----------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `json-sort` | lower           | Go rewrite of `bin/json-sort` (sort JSON keys in place, preserve mode, multi-file, missing-dep and not-a-file errors).                                          | `ok/bad/fixed` sorted JSON       | done (2026-06-19) — quality saturated; diagnostic cheapest eligible, thesis dearest. results/2026-06-19                                                                                          |
| `lint+`     | upper           | `lint` grown per its own Growth note: 5+ rules, worker-pool dispatch, hash-keyed result cache, config inheritance — the step toward extracting `danhorst/lint`. | `ok/bad/fixed` per-rule fixtures | done (2026-06-19) — upper bound mapped: thesis-Haiku converges 12/12 but design 3 (handoff degrades on design, not convergence); control (Opus mono) cheapest eligible. results/2026-06-19-lint+ |
| `lint`      | medium (anchor) | done                                                                                                                                                            | per-rule fixtures                | `results/2026-06-17/`                                                                                                                                                                            |

The upper bound is a surface, not a line, so `lint+` runs the thesis arm across implementer tiers (Haiku → Sonnet → Opus) to find where the spec-to-implementer handoff stops converging.
When authored, `lint+`'s checklist should promote latent-correctness properties (byte-stability and the like) to MUST items from the start, per the spec-gap→checklist discipline `json-sort` surfaced — otherwise the bar cannot credit what decomposition adds.

## Rejected

- **`machine_report`** — large and real, but its oracle is the current machine.
  A fuzzy, environment-coupled oracle at the upper bound would confuse "the handoff broke" with "the test couldn't tell."
  Reconsider only if refactored into pure formatters fed fixture input.
