# bake-off run — fixture `lint+`, 2026-06-19

Third run of the spec-granularity bake-off, and the n=3 point that closes the envelope from above.
`json-sort` (small) found the thesis pipeline *loses* below the floor; `lint` (medium) found it the cheapest eligible path; this fixture (`lint+`, the deliberate upper bound) tests where the spec-to-implementer handoff stops paying.
It stops here: at large size the decomposition handoff breaks on *design* for the cheap implementer, and the thesis tiers that clear the bar all cost more than just using one capable model directly.

(Run lives in `2026-06-19-lint+/` because `json-sort` already holds `2026-06-19/`; both ran the same day.)

## Method

One fixture (`fixtures/lint+/`): a high-level `SPEC.md` (a pluggable lint engine — five rules, declarative manifests, worker-pool dispatch, content-addressed cache, layered nearest-wins config, three invocation surfaces), a deterministic `gate.sh` (build, vet, gofmt, `go test` with no skips and every rule's `ok/bad` fixtures exercised), and a 12-item tool-level `checklist.md` that — per the `json-sort` spec-gap discipline — promotes the latent-correctness properties (deterministic ordering under concurrency, sound cache invalidation) to MUST items rather than leaving them to design judgment.

Six implementer cells, each an isolated clean-room run taken to green or a three-retry cap:

- **control** — Opus, one context, spec and code together, no handoff.
- **challenger** — high-level spec → Sonnet implements.
- **diagnostic** — high-level spec → Haiku implements.
- **thesis sweep** — Opus drafts a decomposed work order → Opus adversarially reviews/refines it → that one work order is implemented by **Haiku, Sonnet, and Opus** in three independent clean rooms (`thesis-haiku/sonnet/opus`), each gated and graded separately. The sweep maps the upper bound as a surface across implementer capability, not a single point.

Each implementer ran headless via `claude -p --output-format json`; cost is `total_cost_usd` summed across the cell's runs (cash API spend).
Each green cell was scored by a separate blind Opus grader against `checklist.md` and `rubric.md`, run in a **copied** clean source tree (never the working room) so the seed `SPEC.md`/`WORKORDER.md` and run artifacts could not leak the cell.
Eligibility = green + 12/12 compliance + design ≥ 4.

## Results

| Cell          | Spec altitude | Implementer | Cost-to-green | Compliance | Design | Eligible |
| ------------- | ------------- | ----------- | ------------- | ---------- | ------ | -------- |
| diagnostic    | high-level    | Haiku       | $1.7253       | 10/12      | 2      | no       |
| challenger    | high-level    | Sonnet      | $3.1618       | 10/12      | 3      | no       |
| thesis-haiku  | decomposed    | Haiku       | $3.1667       | **12/12**  | **3**  | no       |
| **control**   | high-level    | Opus mono   | **$4.5241**   | 12/12      | 4      | **yes**  |
| thesis-sonnet | decomposed    | Sonnet      | $5.0714       | 12/12      | 4      | yes      |
| thesis-opus   | decomposed    | Opus        | $5.1863       | 12/12      | 4      | yes      |

**Cheapest eligible cell = control (monolithic Opus) at $4.52.** No thesis tier beats it.

Cost breakdown:
- Shared thesis spec stages (count once per swept tier): Opus decompose $0.4306 + Opus review $0.6739 = **$1.1045**.
- thesis-haiku = $1.1045 + impl ($1.3489 + $0.7133) = $3.1667.
- thesis-sonnet = $1.1045 + impl ($2.7247 + $1.2422) = $5.0714.
- thesis-opus = $1.1045 + impl ($3.0173 + $1.0645) = $5.1863.
- control = $3.7369 + $0.7872; challenger = $2.5153 + $0.6465; diagnostic = $1.1485 + $0.2787 + $0.2981.
- Six blind grades: $2.1491 total.
- **Attributed total ≈ $22.78.** On top of that, ~$10.3 of *voided* session-limit reruns (see Harness) was real cash the methodology discards — actual burn ≈ $33.

## Findings

- **The upper bound is here, and it failed the way we predicted: green but design-degraded, not non-convergent.** The cheap thesis arm (thesis-haiku) *converged* — green at full 12/12 compliance — yet the blind grade put its design at **3**: a dead `containsRulesKey` helper makes a present-but-keyless nested config replace the parent's rules instead of inheriting, so "unspecified key inherits" silently breaks the moment a second config key exists. A deterministic gate cannot catch that; the blind grade can. At this size the decomposition handoff to the cheap model doesn't fall over by failing to compile; it ships plausible green code whose design has slipped below the bar.
- **No thesis tier is cheapest-eligible — the decomposition tax is never recouped at large size.** The two thesis tiers that clear design ≥ 4 (sonnet, opus) cost $5.07 and $5.19 — both *above* monolithic Opus's $4.52, because each pays the $1.10 spec tax on top of an implementer already at or near control's capability. The plainest case is thesis-opus: Opus implementing a work order Opus wrote, graded identically to control (12/12, design 4), for $0.66 more. When the implementer is already capable enough to clear the bar, decomposition is pure overhead; when it is cheap enough to matter (Haiku), its output no longer clears the bar.
- **Decomposition still helped the cheap model — just not enough.** thesis-minus-diagnostic isolates the granularity effect: Haiku-direct (diagnostic) is 10/12, design 2, with gamed placeholder rules (`md-shape` fix is a constant `echo '# Fixed'`); the same Haiku on the decomposed work order (thesis-haiku) is 12/12, design 3. Decomposition bought +2 compliance and +1 design — real lift, consistent with the `lint` finding that capability and granularity substitute for the same gap — but at `lint+` size the lift lands one design point short of eligibility, so it buys nothing the bar can credit.
- **Monolithic Opus is the right tool at the top of the envelope.** control is the only cheap-relative eligible cell: 12/12, design 4, $4.52, and the one cell whose design held without a handoff. A single capable model still copes with the whole spec at a size where the cheap-implementer handoff has started to degrade. That is the upper bound.
- **The handoff degraded between `lint` and `lint+`.** On `lint` (medium) the Haiku thesis arm was eligible and cheapest ($2.13, 9/9). On `lint+` (large) the Haiku thesis arm is 12/12 but design 3 — it crossed from eligible to ineligible. The cheap-implementer thesis arm's eligibility is the moving surface, and it goes under the bar somewhere between `lint` and `lint+` complexity. That crossing is the upper bound.

## The envelope, closed from above

| Cell           | `json-sort` (small)       | `lint` (medium)           | `lint+` (large)                        |
| -------------- | ------------------------- | ------------------------- | -------------------------------------- |
| diagnostic     | $0.22, 6/6 — **cheapest** | $0.78, 3/9 — ineligible   | $1.73, 10/12 — ineligible              |
| thesis (Haiku) | $1.02, 6/6 — dearest      | $2.13, 9/9 — **cheapest** | $3.17, 12/12 **design 3** — ineligible |
| control (Opus) | $0.50, 6/6 design 5       | (eligible, dearer)        | $4.52, 12/12 design 4 — **cheapest**   |

Read left to right, the thesis (Haiku) arm rises into eligibility at `lint`, then falls out of it again at `lint+` — eligible only in the middle band.
Below the band the cheap direct path already clears the bar (decomposition has nothing to lift); above it the decomposed cheap output drops below the design bar (decomposition can't lift enough), and the capable model alone is cheapest-eligible.
**SDD's decompose-then-cheap-implement pays in a band of task complexity, bounded on both sides.**

## Spec-gap findings (feed the fixture, not the cells)

Three load-bearing gaps surfaced repeatedly across graders and are candidates for a `lint+-r2` revision:

- **`io = "stdin"` is defined but never exercised.** The spec pins stdin-mode rules (and ties `--staged` blob piping to them), but all five starting rules are `io = "path"`, so no fixture drives the stdin branch; challenger and diagnostic left `materializeStaged` as dead code and shipped a working-tree `--staged` with impunity (both scored `staged adapter` NOT MET). Promote a stdin-io rule + a `--staged` materialization fixture to MUST.
- **Per-key config inheritance is untestable at one key.** The spec says "a key absent from a nearer layer inherits from the parent," but the schema has exactly one key (`rules`), so layer-fallback and key-level inheritance are indistinguishable — which is how thesis-haiku's keyless-override bug stayed green. Add a second config key and a present-but-keyless override fixture.
- **`--changed [REF]` ref form is unpinned.** Spec writes a positional `[REF]`; several cells implemented a `--changed-ref` flag and silently ignore a positional ref. Pin the form and assert an explicit ref is honored.
- **fix-command output is unenforced.** The manifest contract ("a failing check prints a copy-pasteable fix command") has no gate check; `shellcheck` cannot honor it (native output is wiki URLs), and challenger/diagnostic emit none — both scored NOT MET. A fixture should assert fix-command emission through `lint check` itself.

## Harness

The expensive run exercised the parts the first two could not.

- **Session limits voided two full parallel waves.** Launching all six large-fixture implementers concurrently exhausted the ~5-hour usage window mid-build; every run returned `is_error` with "hit your session limit," so all were **void** per the SPEC rule: discarded, rerun from clean, never counted as a retry or as non-convergence. Without it, the interrupted builds would have corrupted both the implementations and the costs. The fix was operational: after reset, run **strictly serially**, one cell gated before the next launches. ~$10.3 of discarded reruns is the infra-failure tax, recorded but not attributed.
- **One run produced files but no result JSON** (cut off before writing `total_cost_usd`); with no captured cost or status it was treated as void and rerun from clean, same as a session-limit run.
- **The retry loop engaged on every single cell.** Unlike `json-sort` (all first-try green), `lint+` tripped a coordination trap every cell hit at least once: `cmd/lint` builds an executable named `lint` that collides with the committed `lint/` directory (`go build` refuses), and the gofmt rule's `bad/` fixture must be malformed Go yet `gate.sh` runs `gofmt -l .` tree-wide, flagging it. Even control needed a retry. Both are legitimate, immutable-gate discriminators introduced by the larger fixture; the eligible cells solved them (an `internal/meta` package to force multi-package builds; storing the gofmt bad input as `.txt` and pointing the rule's check at it explicitly).
- **Blinding caught a real leak.** thesis-opus shipped a source comment referencing "WORKORDER §1 layout"; the pre-grade leak scan flagged it and it was scrubbed from the copied grade tree before grading. The rubric's own "challenger cell" phrase appears in every input identically and identifies nothing.

## Versions

- CLI: `claude` 2.1.170 (Claude Code); toolchain go1.26.4; python 3.14.6.
- Implementer model IDs: control `claude-opus-4-8`; challenger `claude-sonnet-4-6`; diagnostic `claude-haiku-4-5-20251001`; thesis decompose+review `claude-opus-4-8`; thesis sweep implementers `claude-haiku-4-5-20251001` / `claude-sonnet-4-6` / `claude-opus-4-8`.
- Grader: `claude-opus-4-8`, read-only (`--allowedTools "Read Glob Grep"`).
- Rate table: vendor `total_cost_usd` as reported per run; no local arms this run.
- Raw grades, grade JSONs, the shared work order, and a per-run cost breakdown are in `artifacts/`.

## Recommendation

The thesis altitude is a band, now bounded on both sides.
At `lint+` size, abandon the spec-pipeline-to-a-cheap-model: hand the whole spec to one capable model (control, monolithic Opus — cheapest eligible and the only design-4 cell without a handoff).
Decomposition buys the cheap model compliance but not design at this complexity, and the thesis tiers whose design holds cost more than control because they pay the spec tax on top of a capable implementer.

The standing rule across n=3: **decompose-then-cheap-implement earns its overhead only in the middle band** — where the task is complex enough that the cheap direct path drops below the bar (above `json-sort`), but not so complex that the decomposed cheap output also drops below it (below `lint+`).
Outside the band, use one model directly: the cheapest that clears the bar below it, the most capable above it.
And because cost here is cash API spend only — the human time to run, retry, and review the pipeline is zeroed, and this run alone needed retries on every cell across two voided session windows — the practical band is narrower than the dollar figures suggest.
