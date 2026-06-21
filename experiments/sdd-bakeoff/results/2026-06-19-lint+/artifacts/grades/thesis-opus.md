## Compliance: 12/12

| # | Item | Verdict | Citation |
|---|------|---------|----------|
| 1 | check exit contract | **met** | `engine.go` `exitCodeFor` returns 1 on any `!Passed` in check mode; `printResults` emits `path [rule]\nmessage`; `engine_test.go:TestEngineCheckFails` asserts exit 1 + per-violation output. |
| 2 | fix transforms | **met** | `scheduler.go` `RunPairs` ModeFix runs `Rule.Fix`; `rules_test.go:TestRuleFixtures` copies each `bad` fixture and asserts byte-equality with `fixed` for all rules; `engine_test.go:TestEngineFixMutates`. |
| 3 | staged adapter | **met** | `adapters.go:sourceStaged` materializes `git show :FILE` blobs to temp files (`ContentPath != Path`), not the worktree; `adapters_test.go:TestSourceStaged`; default policy blocks via `exitCodeFor`. |
| 4 | changed adapter | **met** | `adapters.go:sourceChanged` runs `git diff --name-only --diff-filter=ACM <ref>`, default HEAD; `adapters_test.go:TestSourceChangedDefaultsHEAD`. (See spec-gap on REF parsing.) |
| 5 | hook adapter | **met** | `adapters.go:sourceFromHook` decodes `hookPayload.ToolInput.FilePath`; `engine.go:exitCodeFor` returns 0 when `warn`; `adapters_test.go:TestSourceFromHook`, `engine_test.go:TestEngineWarnAlwaysZero`. |
| 6 | five rules | **met** | `lint/rules.d/{shellcheck,settings-sort,md-shape,gofmt,json-fmt}.toml`, each with `select.*` (extensions/shebangs/globs); `manifest_test.go:TestLoadAllManifests` asserts exactly 5. |
| 7 | fix-command output | **met** | Each manifest `check` echoes a `fix: …` command on failure (e.g. `shellcheck.toml`, `gofmt.toml`); `rules_test.go` asserts nonempty message on `bad`. |
| 8 | config inheritance | **met** | `config.go:ActiveRulesFor` walks dir→baseDir returning the nearest layer with `hasRules`, else base; `hasRules` (via `md.IsDefined`) lets an omitted `rules` key fall through to parent; wired in `engine.go:Run`→`SelectPairs`; `config_test.go:TestConfigNearestWins`. |
| 9 | concurrent dispatch | **met** | `scheduler.go:RunPairs` spawns `jobs` workers over a channel; `main.go` `--jobs` defaults `runtime.NumCPU()`. |
| 10 | deterministic output | **met** | `scheduler.go` `sort.Slice` by `(Path, Rule)` after the pool drains; `scheduler_test.go:TestSchedulerDeterministicOrder` asserts jobs=1 vs jobs=8 element-identical and sorted. |
| 11 | sound cache | **met** | `cache.go:key` = sha256(contentHash ∥ name ∥ manifestHash); `scheduler.go` calls `Put` only on a passing check; `cache_test.go:{TestCacheColdThenWarm,TestCacheContentChangeInvalidates,TestCacheRuleIdentityInKey,TestCacheFailuresNotCached}`. |
| 12 | tests green, none skipped | **met** | Gate green; no `t.Skip` anywhere; `rules_test.go:TestMain` injects `lint/testdata/_stubs` onto PATH so fixtures run rather than skip; tests cover classifier, selector, scheduler, cache, config, all five rule fixtures. |

## Design soundness: 4

The module boundaries map one-to-one onto the spec's six pieces (adapter/classifier/selector/scheduler/cache/config) with a clean `Path`/`ContentPath` split that makes staged-blob linting fall out naturally, marred only by cosmetic friction (the `internal/meta` package exists solely to dodge a build-output collision; `sanitizeForTemp`'s `i` parameter is unused).

## Spec-gap findings

- **`--changed [REF]` positional ref is unimplemented and silently ignored.** The spec writes the ref as a positional (`lint --changed [REF]`), but `main.go` exposes it only as a separate `--changed-ref` flag; `lint --changed main` parses `main` into `fs.Args()` (discarded for non-`args` sources) and lints against HEAD with no error. The spec named the form but never pinned the parsing, so the divergence passes with impunity. Worth promoting to a checklist MUST with a fixture that passes an explicit ref and asserts it is honored.
- **Config inheritance granularity is whole-key, not per-key.** Spec and checklist say "a key absent from a nearer layer inherits from the parent," but the schema has exactly one key (`rules`), so "key-level inheritance" is untestable as distinct from layer-level fallback; no fixture exercises a nested `lint.toml` that *omits* `rules` to inherit the parent's set (tests cover override and `rules = []`, not omission). The spec is under-specified at an altitude where the property looks richer than the single-key reality.