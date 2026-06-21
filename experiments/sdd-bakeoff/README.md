# sdd-bakeoff

An experiment that measures *where* spec-driven development earns its overhead, instead of assuming it always does.

Start here, then read `SPEC.md` for the rig's design and `RUNBOOK.md` for how to run it.

## Why this exists

Spec-driven development (SDD) is increasingly promoted as the default way to work with coding agents.
It has real merit, but it is not the only productive way to work, and its ceremony is not free.
This rig stress-tests the claim empirically: it finds the band of task complexity where SDD pays.

Two deliverables come out of it:

- **The operating envelope of SDD** — the lower and upper complexity bounds within which it is the right tool.
- **Better SDD tooling** — the structure proven here (deterministic tooling blended with pinned prompts at chosen model tiers) is the template for maturing the skills that drive the workflow.

## The cells are approaches

Each bake-off cell stands for a real way of working, so the comparison maps onto an actual decision.

| Cell       | Stands for                                                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- |
| control    | Work the spec directly with one capable model, no handoff.                                                                |
| thesis     | The SDD workflow: a capable model decomposes a work order, a cheap model implements it, a deterministic gate verifies it. |
| challenger | A high-level spec handed to a mid-tier model.                                                                             |
| diagnostic | A high-level spec handed to the cheap model — isolates whether decomposition (not just a cheaper model) is what pays.     |

`thesis` vs `control` is the core question: the SDD pipeline against just using a capable agent directly.

## The envelope has two bounds

- **Lower bound** — below it, the direct path matches quality for less total effort; SDD is ceremony with nothing to buy.
- **Upper bound** — above it, the spec-to-implementer *handoff* itself breaks (non-convergent, or green but design degrades) while a single capable model still copes.
  This bound is a surface, not a line: it moves with implementer capability, so the rig sweeps the implementer model to map it.

## Read the dollar number carefully

Cost here is **cash API spend only**; human and wall-clock time are recorded but not priced in.
The real overhead of SDD for a small task is mostly the human running and reviewing the stages — exactly what the dollar figure omits.
So a dollar crossover is a *lower bound* on where to abandon SDD: the practical threshold sits higher.

## Why the structure, not just bigger models

A capable model alone gives a good answer you take on faith, once.
The value here is trust and reuse at lower cost:

- the deterministic gate is the trust floor that lets work be pushed to a cheap or local model and verified, not inspected;
- a blind model grade is the ceiling the gate cannot reach — it catches green-but-hollow output the gate waves through;
- pinned prompts, clean rooms, and versioned results make the answer re-runnable as models change.

Where none of trust, reuse, or cost control is needed, this structure is pure overhead — which is itself the lower bound of the envelope.

## Layout

```
README.md          this doc — why and what
SPEC.md            the rig's design
RUNBOOK.md         how to run a fixture through the four cells
rubric.md          the blind grader's fixed rubric
prompts/           pinned, machine-driven stage prompts
fixtures/<name>/   a task: starting spec, deterministic gate, normative checklist
results/<date>/    per-cell cost, blind grades, and the rolled-up table
grant.sh           toggles the scoped implementer permission for a run
```
