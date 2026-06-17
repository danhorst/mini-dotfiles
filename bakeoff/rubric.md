# grading rubric

The fixed rubric the blind grader applies to finished code.
One grader model, one rubric, every cell.
The grader sees the fixture's spec, its normative checklist, and the code — never which cell produced it.

## Inputs

- The fixture's starting artifact (the spec under implementation).
- The fixture's normative checklist (the `MUST` items; for `lint/SPEC.md` this is the `Done` section).
- The code as produced, after it reached the gate or the retry cap.
- The gate result: green, or non-convergent with the last failure.

The grader is told the gate result but does not re-run it.
Build and test pass-or-fail is the deterministic gate's job, not the grader's; the grader judges what tooling cannot.

## Score

Two independent scores, never blended into one number.

### Compliance

One binary judgment per checklist item: **met** or **not met**.

- An item is met only if the code demonstrably satisfies it; absence of evidence is not met.
- Partial credit is not available — a checklist item is normative or it would not be on the list.
- The score is the fraction of items met, reported as the raw tally (e.g. 4/6), not a percentage.
- The grader cites the file and symbol that satisfies each met item, so the judgment is auditable.

### Design soundness

A single score on a fixed five-point scale, judging only what compliance cannot see.

| Score | Meaning                                                                              |
| ----- | ------------------------------------------------------------------------------------ |
| 5     | Abstractions match the spec's seams; a competent reader extends it without surprise. |
| 4     | Sound, with cosmetic friction — naming, placement, a redundant helper.               |
| 3     | Works, but a load-bearing choice is questionable and will cost the next change.      |
| 2     | A wrong abstraction or leaked boundary that compliance missed; rework is likely.     |
| 1     | Passes the gate by accident of the tests; the design does not hold.                  |

Design soundness is graded even when compliance is perfect, and especially when it is — green code with a 2 is exactly the failure deterministic tooling cannot catch, and the reason a large model grades at all.

## Spec-gap finding

Separate from both scores, the grader names anything the *spec* failed to require that the code therefore got wrong or omitted with impunity.

- This grades the spec, not the cell.
- It is the signal that the starting artifact was too vague for its altitude — the challenger cell's characteristic risk.
- A gap found here feeds back into the fixture, not the cell's score.

## Output

The grader returns, per cell:

- Compliance tally with per-item citations.
- Design soundness score with the one sentence that justifies it.
- Any spec-gap findings.

No prose praise, no summary paragraph.
The comparison table in `results/` reads these three fields directly.
