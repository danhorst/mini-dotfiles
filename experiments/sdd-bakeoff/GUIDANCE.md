# SDD guidance

When spec-driven development pays, when it doesn't, and what to build because of it.

Drawn from the bake-off in `results/`, n=3 fixtures.
The findings are directional, not settled.
Read Confidence before quoting a number.

## The rule

Decompose-then-cheap-implement pays in a middle band of task complexity.
Outside the band, use one model directly.

| Task size | Approach                                             | Why                                                                                                                 |
| --------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Small     | Cheapest model that clears the bar, no spec pipeline | The cheap model already passes. Decomposition lifts nothing it can credit.                                          |
| Medium    | Capable model decomposes, cheap model implements     | The cheap model fails on its own. Decomposition is the bridge, and it costs less than the capable model alone.      |
| Large     | One capable model, no handoff                        | The cheap model's decomposed output passes tests but its design slips below the bar. The capable model still copes. |

"The bar" means: passes the deterministic gate, 100% MUST-compliance, design ≥ 4 on the blind grade.

Default to one capable model.
Reach for decomposition only after a cheap direct attempt fails the bar on a task that size.

## The evidence

Three fixtures, small to large.
Each cell is a full pipeline run to green or a retry cap, priced in dollars, then graded blind.
Full per-run tables and cost breakdowns are in each `results/<date>/findings.md`.

| Cell                     | json-sort (small)                            | lint (medium)                      | lint+ (large)                                  |
| ------------------------ | -------------------------------------------- | ---------------------------------- | ---------------------------------------------- |
| Cheap-direct (Haiku)     | $0.22, 6/6, design 4 — **cheapest eligible** | $0.78, 3/9 — fails bar             | $1.73, 10/12 — fails bar                       |
| Decompose → Haiku        | $1.02, 6/6 — dearest eligible                | $2.13, 9/9 — **cheapest eligible** | $3.17, 12/12, **design 3** — fails bar         |
| One capable model (Opus) | $0.50, 6/6, design 5                         | $3.73, 9/9 — eligible, dearer      | $4.52, 12/12, design 4 — **cheapest eligible** |

Read the decompose row across.
It rises into the lead at medium, then falls out at large.
That is the band, bounded on both sides.

## Why

Four mechanisms explain the band.
They generalize better than the dollar figures, which expire every model release.

**Capability and granularity close the same gap.** A high-level spec leaves load-bearing ambiguities: inert config, no fix-command output, unpinned defaults.
A capable model infers them from the prose.
A cheap model doesn't.
Decomposition writes them down, so the cheap model resolves them the way raw capability would.
The same Haiku scored 3/9 on the bare `lint` spec and 9/9 on the decomposed work order.

**Below the band there is nothing to lift.** On `json-sort` every cell cleared the bar unaided.
The two decomposition stages cost $0.68 — more than the entire monolithic Opus run at $0.50.
You pay more to plan the task than to do it well.

**Above the band the handoff breaks on design, not convergence.** On `lint+` Haiku converged: green, 12/12 compliance.
The blind grade still dropped it to design 3 — a keyless-config-override bug the tests never trip.
Decomposition bought the cheap model compliance but not design.
The decompose tiers that held design ≥ 4 used Sonnet or Opus, and both cost more than handing the whole spec to Opus.
The plainest case is Opus implementing a work order Opus wrote: same grade as the direct Opus run, $0.66 more.

**When it pays, it pays by splitting token tiers.** On `lint` the capable model is billed only for the thinking and the cheap model does the typing.
Same eligible result as monolithic Opus — about 43% cheaper.
That gap is the whole case for the pipeline, and it only opens inside the band.

## What to build

This is the input to our SDD tooling, not just a report.

Don't make SDD the default path.
`/spec` and the implement skills should treat decompose-then-cheap-implement as one tool among three, chosen by task size and demonstrated need.

Build the altitude selector around the rule above.
Start every task assuming one capable model.
Escalate to decomposition only when a cheap direct attempt fails the bar at that size, and stop escalating once the implementer is capable enough to clear the bar on its own.

Keep the gate as the trust boundary at every altitude.
Cheap and local output is trusted through build, test, and lint, never on inspection.

Add a blind quality check above the gate.
The gate alone passed green-but-hollow output in every run.
On `lint+` it waved through code at 12/12 compliance whose design had slipped.
A deterministic gate cannot catch design; a blind grade can, and it is the only thing that caught the upper bound.

Price the human, not just the API.
The dollar crossover is a floor.
Once run, retry, and review time is counted, the practical band is narrower than the dollars say.

## The reusable structure

The rig is the template for the tooling, independent of the verdict.

- **Deterministic gate as the trust floor.** Build plus tests plus lint, immutable, run from a clean checkout. Any diff touching the tests, lint config, gate, fixture, or checklist fails the run, so a model can't green by deleting a test. The gate also fails on absent rule-fixture tests, not only skipped ones, or a cheap model greens by writing no tests at all.
- **Blind grade as the ceiling the gate can't reach.** One fixed rubric, same grader model across cells, scored against a clean diff so work-order residue and comment style can't leak the cell's identity.
- **Pinned prompts, clean rooms, versioned results.** Every stage runs from a fixed prompt with raw outputs stored and no hand-edits, so no uncounted human effort leaks into the comparison. Each result pins exact model IDs, CLI versions, and the date, so a re-run after a model release is comparable rather than merely repeated.

This structure earns its complexity only where trust, reuse, or cost control is needed.
Where none is, it is overhead, which is itself the lower bound of the envelope.

## Methodology lessons

Lessons from running the rig, worth carrying into the tooling.

- **Void infra failures; don't count them as model failures.** A run that errors for a session limit or crash is discarded and rerun from clean, never scored as a retry or non-convergence. `lint+` voided two full parallel waves to session limits; without the rule they would have corrupted both the implementations and the costs. Run cells serially, each gated before the next launches.
- **Fixtures are immutable; revise, don't edit.** A spec-gap finding cuts a new revision in a sibling directory, never edits a fixture in place, so past results stay bound to the version they ran against and the checklist never moves under a comparison.
- **Promote latent-correctness properties to MUST items.** `json-sort` shipped two cells with a silent idempotency bug because no fixture exercised numbers. If a property is load-bearing but only judged as design, the bar can't credit what decomposition adds. Write it into the checklist as a MUST and ship a fixture that trips it.
- **Blind the grader against residue, not just the cell label.** Grade a copied source tree, scrubbed of seed specs, work orders, run JSON, and stray comments referencing the work order. On `lint+` a source comment naming "WORKORDER §1" had to be scrubbed before grading.

## Confidence

The shape is more robust than the magnitudes.

- **n=1 per cell, no variance repeats.** Each fixture ran once per cell. Treat the dollar figures as directional.
- **Each bound is one bracketing pair.** The lower bound sits somewhere between `json-sort` and `lint`; the upper, between `lint` and `lint+`. We have two line segments, not a located crossover.
- **Cost is cash API spend only.** Human run, retry, and review time is recorded but not priced. `lint+` alone needed retries on every cell across two voided session windows. The practical "don't bother with SDD" threshold sits above the dollar crossover.
- **The result is domain-bounded.** Every fixture is a file-transformer or checker with a clean in/out oracle, which is exactly where a deterministic gate can bite. The guidance applies where a gate has something to verify. It says nothing about fuzzy-oracle work.
