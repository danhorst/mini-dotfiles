**Compliance tally: 12/12 met**

1. **check exit contract** — MET. `engine.go:Run` (ModeCheck) prints `"%s [%s]\n%s"` per failing result and returns `1` when `failingResults` is non-empty, `0` otherwise; asserted by `engine_test.go:TestEngineIntegration` (exit 1).
2. **fix transforms** — MET. `scheduler.go:processPair` (ModeFix) runs `rule.Fix`; `rules_test.go:TestRulesFixtures` `fix/*` subtests copy `bad`→temp, fix, and assert byte-equality with `fixed`.
3. **staged adapter** — MET. `adapters.go:sourceStaged` lists via `git diff --cached`, materializes each blob with `git show :PATH` into a temp file pointed to by `ContentPath`; non-warn path returns `1`, so it blocks (`engine.go:Run`).
4. **changed adapter** — MET. `adapters.go:sourceChanged` runs `git diff --name-only … REF` (default `HEAD`).
5. **hook adapter** — MET. `adapters.go:sourceFromHook` decodes `tool_input.file_path`; with `--warn`, `engine.go:Run` returns `0` unconditionally; `adapters_test.go:TestSourceFromHook` + `engine_test.go:TestEngineWarnMode` (exit 0).
6. **five rules** — MET. `lint/rules.d/{shellcheck,settings-sort,md-shape,gofmt,json-fmt}.toml`, each with `select.extensions`/`select.shebangs`/`select.globs`.
7. **fix-command output** — MET. Each manifest's `check` echoes a `fix: …` command on failure (e.g. `gofmt.toml`, `shellcheck.toml`).
8. **config inheritance** — MET (with caveat, see spec-gap). `config.go:ConfigResolver.ActiveRulesFor` walks file→base and returns the nearest layer's rules; `config_test.go:TestConfigResolver` covers root, sub, and nested-empty nearest-wins.
9. **concurrent dispatch** — MET. `scheduler.go:RunPairs` spawns `jobs` worker goroutines over a channel; `main.go` defaults `--jobs` to `runtime.NumCPU()`.
10. **deterministic output** — MET. `scheduler.go:RunPairs` sorts results by `(Path, Rule)` before return; `scheduler_test.go:TestScheduler` asserts identical ordering for `--jobs 1` vs `8`.
11. **sound cache** — MET. `cache.go:key` hashes `contentHash\x00name\x00manifestHash`; `processPair` reuses only on hit and `Put`s only on pass; `cache_test.go:TestCache` covers cold miss, warm hit, content-change invalidation, rule-identity in key.
12. **tests green, none skipped** — MET (per stated gate). `rules_test.go`, `classifier_test.go`, `selector_test.go`, `scheduler_test.go`, `cache_test.go`, `config_test.go` cover the required surfaces; gate reports green with no skips.

**Design soundness: 3** — The six spec pieces map cleanly to separate files, but `config.go:containsRulesKey` is a dead helper that returns `true` for any non-empty file, so a present-but-keyless nested `lint.toml` yields empty rules instead of inheriting — defeating the spec's "unspecified key inherits from the parent" the moment a second config key is added.

**Spec-gap findings:**
- The config "unspecified key inherits from the parent" property has no fixture exercising a nested config that omits `rules`; the spec's single-key model lets the broken `containsRulesKey`/whole-list-replacement pass with impunity. Promote a present-but-keyless override fixture to a MUST.
- `adapters.go:sourceStaged` names temp blobs by `filepath.Base(logicalPath)` only; two staged files sharing a basename across directories silently clobber each other. The spec pins blob materialization but never constrains temp-path uniqueness.
- `scheduler.go:RunPairs` drops a result (sets local `input = nil`, returns) on any `processPair` error, so a hash failure yields fewer results without surfacing — a silent determinism/coverage hole the spec's "concurrency is never observable" never forces a test to catch.