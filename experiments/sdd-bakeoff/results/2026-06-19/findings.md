# bake-off run — fixture `json-sort`, 2026-06-19

Second run of the spec-granularity bake-off, and the n=2 point.
Fixture one (`lint`, medium) found the thesis cell — Opus decomposes a work order, a cheap model implements it — the cheapest *eligible* path, beating monolithic Opus by ~43%.
This fixture (`json-sort`, the deliberate lower bound) tests whether that holds at small task size.
It does not.

## Method

One fixture (`fixtures/json-sort/`): a high-level `SPEC.md` (sort JSON object keys in place, idempotently, mode-preserving, no `jq`), a deterministic `gate.sh` (build, vet, gofmt, `go test` with no skips and an exercised `sort` fixture component), and a tool-level `checklist.md` of six MUST items.

Four cells, each an isolated clean-room implementation taken to green (or a three-retry cap):

- **control** — Opus, one context, spec and code together, no handoff.
- **challenger** — high-level spec → Sonnet implements.
- **diagnostic** — high-level spec → Haiku implements.
- **thesis** — Opus drafts a decomposed work order → Opus adversarially reviews and refines it → Haiku implements that.

Each implementer ran headless via `claude -p --output-format json`; cost is `total_cost_usd` summed across the cell's runs (cash API spend).
Each green cell was scored by a separate blind Opus grader against `checklist.md` and `rubric.md`, run in a cleaned source tree so work-order residue and run artifacts could not leak the cell.
Eligibility = green + 100% compliance + design ≥ 4.

## Results

| Cell       | Spec altitude | Model     | Cost-to-green | Compliance | Design | Eligible |
| ---------- | ------------- | --------- | ------------- | ---------- | ------ | -------- |
| diagnostic | high-level    | Haiku     | $0.22         | 6/6        | 4      | **yes**  |
| challenger | high-level    | Sonnet    | $0.45         | 6/6        | 4      | **yes**  |
| control    | high-level    | Opus mono | $0.50         | 6/6        | 5      | **yes**  |
| thesis     | decomposed    | Haiku     | $1.02         | 6/6        | 4      | **yes**  |

Every cell went green on run 1 — no retries, no voided infra runs.
Thesis cost-to-green = Opus draft $0.20 + Opus review $0.48 + Haiku impl $0.35.
Total experiment spend ≈ $2.80 (all implementations and all blind grades).

## Findings

- **The thesis win does not hold at this size.** On `lint` the thesis was the cheapest eligible cell; here it is the *most expensive* eligible cell — $1.02 against diagnostic's $0.22, a 4.7× premium for the same eligibility (both 6/6, design 4). The cheapest eligible cell, and so the winner under the rubric, is diagnostic: Haiku on the bare high-level spec.
- **Quality saturated, so decomposition had nothing to buy.** On `lint` the bar discriminated hard (diagnostic 3/9, challenger 7/9). Here all four cells cleared 6/6 with design ≥ 4. When the task is small enough that the cheap, direct path already clears the bar, the decomposition that exists to *lift* a cheap model over it is pure overhead.
- **The decomposition tax alone exceeds the whole monolithic run.** The two Opus spec stages cost $0.68 — more than control's entire $0.50 monolithic implementation, and 3× the complete diagnostic cell. At this size you pay more to *plan* the work than to just do it with the best model.
- **The cheap model needed no bridge here.** On `lint`, Haiku-direct was ineligible (3/9) and decomposition was what made it viable. On `json-sort`, Haiku-direct is eligible on its own. Capability and granularity are substitutes for the same gap (the `lint` finding), and at this size there is no gap to close.
- **Decomposition still added robustness — just nothing the bar can see.** Every grader flagged the same unspecified-but-load-bearing requirement: number-literal byte-stability (a naive `float64` decode silently rewrites large integers and `1.10`). Control and thesis used `json.Number` and are robust; challenger and diagnostic decode to `float64` and carry a latent idempotency bug the fixtures never trip. Only the thesis both handled it *and* shipped a `numbers.json` fixture proving it — the Opus decomposition surfaced the gap as concrete coverage, exactly as the decompose prompt intends. But since compliance and design score both cells 6/6 and 4, this robustness is invisible to eligibility, so at the lower bound it is real value you cannot justify paying for under a fixed-quality comparison.

## The crossover, bracketed

This is the n=2 point, and it brackets the lower bound of SDD's operating envelope.

| Cell       | `lint` (medium)                     | `json-sort` (small)                 |
| ---------- | ----------------------------------- | ----------------------------------- |
| diagnostic | $0.78, 3/9 — ineligible             | $0.22, 6/6 — **eligible, cheapest** |
| thesis     | $2.13, 9/9 — **eligible, cheapest** | $1.02, 6/6 — eligible, dearest      |

Between these two task sizes the thesis flips from cheapest-eligible to most-expensive-eligible, and the diagnostic flips from ineligible to the winner.
The crossover where decomposition starts paying lies between `json-sort` and `lint` complexity.
Below it, skip the spec pipeline and hand the task to a cheap model — or, for the best design at near-cheapest price here, to monolithic Opus (design 5 at $0.50).
And because cost here is cash API spend only — the human time to run and review the pipeline is zeroed — the practical "don't bother with SDD" threshold sits *above* this dollar crossover, not at it.

## Spec-gap finding (feeds the fixture, not the cells)

`json-sort/SPEC.md` asserts byte-for-byte idempotency but never pins number-literal preservation, HTML-character escaping (`<`/`>`/`&`), or duplicate-key handling — all of which `encoding/json` will silently change.
Two of four cells shipped a latent idempotency bug with impunity because no fixture exercises numbers or those characters.
A next revision of the fixture should require number/character byte-stability and ship `numbers`/`special-chars` fixtures; per the harness's immutability rule this is a new fixture revision, not an edit, and these results stay bound to the revision they ran against.

## Harness

Every path fired again, cheaply: clean-room isolation, headless implementers, cost capture, the gate, and four blind grades in cleaned trees.
The retry loop did not engage — every cell converged first try — so the cap and the void-on-infra-error rule were not exercised this run.
The blinding upgrade this run forced, now standard: grade against a copied source tree (produced `*.go`, `testdata`, `go.mod`, `install.sh`) rather than the working clean room, because the clean room carries the seed `SPEC.md` or `WORKORDER.md` and the run JSON/gate artifacts — the thesis room's `WORKORDER.md` alone would unblind the grader.

## Versions

- CLI: `claude` 2.1.170 (Claude Code); toolchain go1.26.4; python 3.14.6.
- Implementer model IDs: control `claude-opus-4-8`; challenger `claude-sonnet-4-6`; diagnostic `claude-haiku-4-5-20251001`; thesis decompose+review `claude-opus-4-8`, implement `claude-haiku-4-5-20251001`.
- Grader: `claude-opus-4-8`, read-only (`--allowedTools "Read Glob Grep"`).
- Rate table: vendor `total_cost_usd` as reported per run; no local arms this run.

## Recommendation

The thesis altitude is not universal — it is the right tool in a complexity band, not a default.
At `json-sort` size, the spec pipeline loses to handing the task straight to a cheap model, and even to monolithic Opus.
This is the second data point and the first that bounds the envelope from below; the upper bound (`lint+`, with an implementer sweep) is the next run and the one that tells you where the handoff *breaks*.
The standing rule emerging: decompose-then-cheap-implement earns its overhead only once a task is complex enough that the cheap, direct path drops below the quality bar — and the human-time overhead the dollar figure omits pushes that threshold higher still.
