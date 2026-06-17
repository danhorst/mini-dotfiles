# spec bake-off

A harness that decides the spec-granularity question empirically: how much design and implementation detail a large model must commit before a cheaper model can implement reliably, and whether that front-loading pays for itself.

## Goals

- Compare the whole spec-to-code pipeline across model arms on a single axis: cost in dollars at fixed quality.
- Measure the *whole* pipeline — spec authoring, review, implementation, and every fix-loop round — not implementation alone.
- Ship a re-runnable rig, not a one-time number; the answer expires every model release, so swapping the implementer model is one field.
- Locate the crossover by task size and parallelism, not crown a winner.

## Model

Four pieces.

- **Cells** are the arms under comparison.
  Each cell is a full pipeline from a starting spec to code that passes the gate, run non-interactively so its cost is captured per-run.
- **Fixtures** are the tasks being implemented.
  A fixture is a triple: a starting artifact, a deterministic gate, and a normative checklist that serves as the compliance oracle.
- **Metrics** are dollars-to-green and a blind quality grade.
- **The grader** is a large model scoring finished code against a fixed rubric, blind to which cell produced it.

## The cells

Four arms.
The control is the null hypothesis the whole pipeline must beat to justify itself.

| Cell       | Pipeline                                                                                           | Implementer    |
| ---------- | -------------------------------------------------------------------------------------------------- | -------------- |
| control    | one context, spec and code together, no handoff                                                    | Opus           |
| challenger | Opus drafts a high-level spec → handoff → implement                                                | Sonnet         |
| thesis     | Opus drafts a decomposed work order → Opus antagonistic spec review → refine → handoff → implement | Haiku or local |
| diagnostic | Opus drafts a high-level spec → handoff → implement                                                | Haiku or local |

The first three cells are the real workflows under decision: which actual pipeline is cheapest at fixed quality.
The diagnostic cell exists only to break one confound.
Thesis and diagnostic share the cheap implementer and differ only in spec granularity, so thesis-minus-diagnostic isolates whether decomposition pays, separately from the model merely being cheaper.

The antagonistic review in the thesis cell reviews the *spec*, before implementation — it is part of that arm's pipeline and its tokens count toward cost.
It is not the output grade.
Output quality is measured once, uniformly, by the blind grader, and is never part of any cell's pipeline.

## Metrics

### Cost

- Dollars, not tokens.
  Opus, Sonnet, Haiku, and local tokens are not the same price; cross-vendor token counts are not comparable.
- Whole pipeline.
  Spec authoring and spec review count, or the thesis cell's largest line item is hidden.
- Cost-to-green, including the fix loop.
  First-attempt cost is a lie for cheap models; the real cost is expected rework.

### Quality

Two axes.

- **The deterministic gate** is build plus `go test ./...` plus lint.
  Binary, free, and the definition of *green*.
- **The graded score** is the blind rubric: MUST-compliance scored binary per checklist item, plus design soundness scored on a fixed scale.

### Eligibility

"Cost at fixed quality" needs the quality bar fixed before any cell runs, or a cheap-but-shoddy cell wins on dollars alone.

- A cell is **eligible** only if it is green, scores 100% compliance, and scores design soundness ≥ 4.
- Dollars are compared only among eligible cells.
- An ineligible cell is reported with its cost but ranked below every eligible cell, never declared a winner on price.

## The fix loop

A cell runs to green or to a retry cap.

- On a gate failure the implementer model receives the gate output and retries.
- Retries are capped at three.
- A cell that is not green at the cap is recorded as **non-convergent** — a first-class outcome, and the cheap path's characteristic failure mode.
- Every round's cost accrues to that cell's dollars-to-green.
- A non-convergent cell has `dollars_to_green = null` and is ranked below every green cell; its accrued cost is still recorded, so a cheap model's rework is visible rather than hidden.

## Pinned decisions

- **The gate is the trust boundary, and the gate itself is immutable.**
  Cheap and local output is trusted only through build, test, and lint, never on inspection.
  Each cell runs from a clean checkout, and any diff touching the tests, lint config, gate command, fixture artifact, or checklist fails the run — a model that greens by deleting a test has gamed the boundary, not passed it.
- **Every stage is machine-driven from a fixed prompt; no hand-edits.**
  The spec drafting, antagonistic review, and refinement in each cell run from pinned prompts with their raw outputs stored, never touched by a human between stages.
  Manual selection or editing of an intermediate spec would leak uncounted effort into the comparison and is the failure the non-interactive constraint exists to prevent.
- **Cost is captured per-run.**
  Claude arms run via `claude -p --output-format json`, which reports `total_cost_usd` directly.
  Local arms run via `codex exec --oss --json`, which reports token usage; dollars come from a per-model rate table, with local compute counted at zero.
  While local compute is zero, the column is labelled *cash API spend*, not total cost, so a slow local model is not mistaken for a cheap one — wall-clock is recorded alongside.
- **Every result pins its versions.**
  Each result directory records exact model IDs, CLI versions, the rate-table version, and the date, so a re-run after a model release is comparable rather than merely re-run.
- **The grader is blinded and fixed.**
  It does not see which cell produced the code, uses one rubric, and is the same model across all cells in a run.
  It is given a clean diff against the fixture baseline, not the working tree, so work-order residue or comment style cannot leak the cell's identity.
- **n=1 is directional.**
  The first fixture debugs the harness; conclusions need more fixtures.
  The deliverable is the rig, not the verdict.

## The fixture

`lint/SPEC.md` is fixture one.
It is bounded, real, and already carries both halves of a fixture: its `Done` section is the normative checklist, and `go test ./...` is the gate.
Further fixtures vary size and parallelism — the two axes expected to govern the crossover — so the rig can find where the thesis cell overtakes the challenger rather than asserting it.

Fixtures are versioned immutably.
A spec-gap finding does not edit a fixture in place; it cuts a new revision, and results stay bound to the revision they ran against, so the checklist never moves under a comparison.

## Layout

```
bakeoff/SPEC.md                 this doc
bakeoff/rubric.md               the blind grader's fixed rubric
bakeoff/fixtures/<name>/        starting artifact, gate command, normative checklist
bakeoff/run.sh                  drives a cell to green or retry-cap, emits cost + grade
bakeoff/results/<date>/         per-cell raw cost and grade, plus a rolled-up table
```

The harness starts as a runbook and a thin driver script, not a framework.
It earns automation only if the crossover question outlives the first few runs.

## Done

- All four cells run against `lint/SPEC.md` to green or the retry cap.
- Each cell reports dollars-to-green and a blind rubric grade in one comparison table, with eligibility resolved before dollars are compared.
- The implementer model is a single field; re-running an arm with a different model needs no other change.
- Non-convergence is recorded distinctly from a low grade.
- Thesis-minus-diagnostic is reported as the granularity effect, isolated from the model-price effect.

## Growth

- Add fixtures of varying size and parallelism to locate the crossover.
- If the challenger ties on quality and wins on cost, the decomposition machinery is never built and `/spec` targets the high-level altitude.
- If the thesis wins only under parallelism, that defines when to fan implementation out across cheap workers.
- The rig becomes the standing answer to "which model for this stage," re-run per model release.
