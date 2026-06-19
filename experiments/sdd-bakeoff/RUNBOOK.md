# bake-off runbook

How to run a fixture through the four cells by hand.
This is the procedure that produced `results/2026-06-17/`; it is not yet a script (`run.sh` is deferred).
Read `SPEC.md` for the design and `rubric.md` for grading.
To kick off a fresh session, paste `seed-run.md`.

## Before a run

- **A fixture** at `fixtures/<name>/`: a `SPEC.md` (the starting artifact), a `checklist.md` (tool-level MUST items, isolation-gradeable — do not reuse a project's repo-integration Done items), and a `gate.sh <impl-dir>` that exits nonzero unless the project builds, tests pass with no skips *and no absent fixture tests*, and the formatter/linter is clean. Copy `fixtures/lint/` as the template — but its "rule fixtures exercised" check hardcodes lint's component names (`shellcheck settings-sort md-shape`); a naive copy checks for those in a non-lint project and always fails. Adapt that loop to the new fixture's own components (each ships `ok/`+`bad/` fixtures, a test reads them); the build/vet/fmt/test/no-skip scaffolding copies as-is.
- **The implementer permission grant.** Implementer and retry launches use `claude -p … --permission-mode bypassPermissions`, which the auto-mode classifier blocks unless an allow rule matches. Run `experiments/sdd-bakeoff/grant.sh on` (DBH runs it — the classifier blocks the agent from granting it), and `experiments/sdd-bakeoff/grant.sh off` after. Shape every launch so the `claude -p …` segment matches the rule (`cd "$W" && claude -p …` works — the matcher splits on `&&`). Grader and the two Opus thesis stages are read-only (`--allowedTools "Read Glob Grep"`) and need no grant.
- **Toolchain** for the fixture's stack (e.g. `go`), plus `claude` and `python3`.

To keep generalization clean, vary **task size**, not language — hold the stack constant so size is the only moving variable.

## Paths (set once per run)

```
R=$(git rev-parse --show-toplevel)     # repo root, so commands survive `cd "$W"`
F="$R/experiments/sdd-bakeoff/fixtures/<name>"         # the fixture
```

Every clean room is `W=/tmp/sdd-bakeoff/<cell>`.
All prompt/rubric paths below are absolute (`$R/...`) on purpose: the launches `cd` into `$W`, so a repo-relative path would resolve against the clean room and fail.

## Cells and model assignment

| Cell       | Implementer         | Pipeline                                                       |
| ---------- | ------------------- | -------------------------------------------------------------- |
| control    | opus                | implement `SPEC.md` directly                                   |
| challenger | sonnet              | implement `SPEC.md` directly                                   |
| diagnostic | haiku               | implement `SPEC.md` directly                                   |
| thesis     | opus → opus → haiku | decompose `SPEC.md` → review/refine → implement the work order |

## Per-cell mechanics

**1.
Clean room.**

```
W=/tmp/sdd-bakeoff/<cell>; rm -rf "$W"; mkdir -p "$W"; cp "$F/SPEC.md" "$W/SPEC.md"
```

**2.
Implement** (control / challenger / diagnostic).
Background; the JSON result holds `total_cost_usd` and `session_id`.

```
cd "$W" && claude -p --model <opus|sonnet|haiku> --output-format json \
  --permission-mode bypassPermissions < "$R/experiments/sdd-bakeoff/prompts/implement.txt" \
  > "$W/run1.json" 2> "$W/run1.err"
```

**3.
Gate.** Capture full output for any retry.

```
bash "$F/gate.sh" "$W" > "$W/gate1.txt" 2>&1; echo "exit=$?"
```

**4.
Retry loop** (cap 3).
On a RED gate, resume the same session with the gate output appended to the retry prompt:

```
SID=$(python3 -c "import json;print(json.load(open('$W/run1.json'))['session_id'])")
{ cat "$R/experiments/sdd-bakeoff/prompts/retry.txt"; echo; cat "$W/gate1.txt"; } > "$W/retry.txt"
cd "$W" && claude -p --resume "$SID" --model <model> --output-format json \
  --permission-mode bypassPermissions < "$W/retry.txt" > "$W/run2.json" 2> "$W/run2.err"
```

Re-gate; repeat to cap 3.
Not green at cap → **non-convergent** (`dollars_to_green = null`, ranked below every green cell).

**5.
Cost.** Sum `total_cost_usd` across run1 + every retry.
**Void any run whose `is_error` is true for an infrastructure reason** (a session/usage limit, a crash — its `result` says so): discard it and rerun from clean.
Infra failure is not non-convergence, and a mid-build interruption corrupts the impl.

## Thesis pipeline (replaces step 2)

Both Opus stages are read-only and emit the artifact as the JSON `result`; extract it.

**Decompose** (Opus drafts the work order):

```
{ cat "$R/experiments/sdd-bakeoff/prompts/decompose.txt"; cat "$F/SPEC.md"; } > "$W/draft-prompt.txt"
claude -p --model opus --output-format json --allowedTools "Read" \
  < "$W/draft-prompt.txt" > "$W/draft.json"
python3 -c "import json;open('$W/WORKORDER-draft.md','w').write(json.load(open('$W/draft.json'))['result'])"
```

**Review / refine** (Opus adversarially hardens it):

```
{ cat "$R/experiments/sdd-bakeoff/prompts/review-refine.txt"; echo; cat "$F/SPEC.md"; \
  echo '===== DRAFT WORK ORDER ====='; cat "$W/WORKORDER-draft.md"; } > "$W/review-prompt.txt"
claude -p --model opus --output-format json --allowedTools "Read" \
  < "$W/review-prompt.txt" > "$W/final.json"
python3 -c "import json;open('$W/WORKORDER.md','w').write(json.load(open('$W/final.json'))['result'])"
```

Then **implement the work order** with Haiku (clean room holds only `WORKORDER.md`, not `SPEC.md`), using `$R/experiments/sdd-bakeoff/prompts/implement-workorder.txt`, then gate + retry as above.
Thesis cost-to-green = draft + review + impl + retries.

## Blind grade (every green cell)

Assemble the grader input from the grade prompt plus the fixture's `SPEC.md`, `checklist.md`, `rubric.md`, and the concatenated source; run a separate Opus grader, read-only, blind to the cell:

The grader must see only produced source.
Never grade the working clean room: it holds the seed `SPEC.md` or `WORKORDER.md` and the run JSON and gate files, any of which unblinds the grader — the thesis room's `WORKORDER.md` is the plainest leak.
Copy the produced source into a fresh tree and grade that.

```
G="/tmp/sdd-bakeoff/grade/<cell>"; rm -rf "$G"; mkdir -p "$G"
for p in cmd testdata go.mod go.sum install.sh .gitignore; do cp -R "$W/$p" "$G/" 2>/dev/null; done
IN="/tmp/sdd-bakeoff/grade/<cell>-input.txt"
{ cat "$R/experiments/sdd-bakeoff/prompts/grade.txt"; cat "$F/SPEC.md";
  echo '================= CHECKLIST ================='; cat "$F/checklist.md";
  echo '================= RUBRIC ================='; cat "$R/experiments/sdd-bakeoff/rubric.md";
  echo '================= IMPLEMENTATION SOURCE ================='
  while IFS= read -r f; do echo "----- ${f#"$G"/} -----"; cat "$f"; echo; done \
    < <(find "$G" -type f \( -name '*.go' -o -name '*.toml' \) | sort)
  echo '----- file tree -----'; (cd "$G" && find . -type f | sort); } > "$IN"
cd "$G" && claude -p --model opus --output-format json --allowedTools "Read Glob Grep" \
  < "$IN" > "$G/grade.json"
python3 -c "import json;d=json.load(open('$G/grade.json'));print(d['total_cost_usd']);print(d['result'])"
```

Adapt the copied paths and the source `find` filter to the fixture's stack.
Before launching, grep the assembled input for leak terms — work order, junior, decompose, the model and cell names — since source comments can unblind even when filenames do not.

## Eligibility and reporting

A cell is **eligible** only if green + 100% compliance + design ≥ 4 (`SPEC.md`).
Compare dollars-to-green only among eligible cells; the cheapest eligible cell wins.
Record the four-cell table, per-cell cost breakdown, and the blind grades in `results/<date>/`, pinning model IDs and CLI versions.

## Gotchas (learned 2026-06-17)

- The deterministic gate cannot see *missing* tests — `gate.sh` now fails on absent rule-fixture coverage, but the blind grade remains the real backstop for hollow-but-green code.
- `/tmp/sdd-bakeoff/*` is volatile; only `results/<date>/` and committed fixtures survive.
- Don't grade against a project's real `Done` if it carries repo-integration steps no clean room can perform — that is why the fixture ships its own tool-level `checklist.md`.
