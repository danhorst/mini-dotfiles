## Compliance: 10/12

- **check exit contract** — MET. `run()` sets `anyFail` and calls `os.Exit(1)` on violation, prints `FAIL [%s] %s\n%s` per failing result; clean input returns `nil` (exit 0). `cmd/lint/main.go`.
- **fix transforms** — MET. `verb == "fix"` branch calls `execFix(p.Rule, p.File)`; `TestRuleFixtures`/`fix` subtest asserts `bad`→`fixed` byte-equality. `cmd/lint/main.go`, `cmd/lint/rules_test.go`.
- **staged adapter** — **NOT MET.** `case *staged:` calls `stagedFiles()` (a `--name-only` list) and feeds those working-tree paths straight to `SelectPairs`/`classifyFile`; `materializeStaged` exists in `adapters.go` but is never called. The pinned "staged content, not working tree" decision is unimplemented — staged blobs are not materialized. `cmd/lint/main.go`, `cmd/lint/adapters.go`.
- **changed adapter** — MET. `changedFiles(ref)` runs `git diff --name-only REF`, defaulting to `HEAD`. `cmd/lint/adapters.go`, `cmd/lint/main.go`.
- **hook adapter** — MET. `filesFromHook` unmarshals `tool_input.file_path`; `--warn` makes `anyFail && !*warn` false so `run()` returns `nil` (exit 0). `cmd/lint/adapters.go`, `cmd/lint/main.go`.
- **five rules** — MET. `shellcheck.toml`, `settings-sort.toml`, `md-shape.toml`, `gofmt.toml`, `json-fmt.toml`, each with `select.extensions`/`select.shebangs`/`select.globs`. `lint/rules.d/`.
- **fix-command output** — **NOT MET.** No provided source emits a copy-pasteable fix command. The orchestrator only passes `r.Output` through (`main.go`), and the rules' `check` commands (`json-check`, `gofmt-check`, `md-check`, `settings-check`) are helper scripts absent from the tree; nothing demonstrable produces the fix command. `lint/rules.d/*.toml`, `cmd/lint/run.go`.
- **config inheritance** — MET. `LoadConfig` walks `dir`→`root`, applies root-first then overrides with nearer non-empty `Rules`; wired via `configFn` in `run()`. `TestConfigNestedOverride`/`TestConfigInheritsMissingKeys`. `cmd/lint/config.go`.
- **concurrent dispatch** — MET. `RunChecks` spawns `min(jobs, len(pairs))` workers over a channel; `--jobs` defaults to `runtime.NumCPU()`. `cmd/lint/scheduler.go`, `cmd/lint/main.go`.
- **deterministic output** — MET. Results `sort.Slice` by `(File, Rule)` after the pool drains; `TestSchedulerDeterminism` compares `jobs=1` vs `NumCPU` across 5 runs with random delays. `cmd/lint/scheduler.go`.
- **sound cache** — MET. Key is `sha256(contentHash|ruleID)`; `checkFn` reuses only on `Get` hit, else runs and `Put`s; `ruleID` folds manifest hash. `TestCacheInvalidatesOnContentChange`/`TestCacheKeyIncludesRuleIdentity`. `cmd/lint/cache.go`, `cmd/lint/main.go`.
- **tests green, none skipped** — MET. Gate green per instructions; no `t.Skip` present; suites cover classifier, engine, scheduler, cache, config, all five fixtures. `cmd/lint/*_test.go`.

## Design soundness: 3

The manifest/selector/engine/scheduler/cache/config seams cleanly match the spec, but the staged path is wired to working-tree names with `materializeStaged` left as dead code and the declared `io = "stdin"` mode is entirely absent from `run.go` — load-bearing pinned decisions the next change must retrofit.

## Spec-gap findings

- **`io = "stdin"` mode is unrequired and unimplemented.** The spec defines `io = "stdin"` (and ties `--staged` blob piping to it), but no checklist MUST exercises it; `execCheck`/`execFix` only `{file}`-expand and never branch on `rule.IO`, so a stdin rule would silently misbehave. Promote a stdin-io fixture to a MUST.
- **fix-command output is delegated out of the gradeable binary.** The contract lives in helper scripts (`json-check`, `gofmt-check`, etc.) that are not part of the committed source, so the MUST cannot be verified from the binary; the fixture should assert fix-command emission through `lint check` itself.
- **`--changed [REF]` optional ref is ergonomically unreachable.** Modeled as `flag.String("changed", "", …)`, so bare `--changed` consumes the next arg as the ref rather than defaulting to `HEAD`; the spec's optional-ref form isn't pinned and the code's default-to-HEAD only triggers for `--changed=""`.