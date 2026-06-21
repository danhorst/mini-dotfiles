**Compliance: 12/12**

1. **check exit contract** — met. `run()` prints `%s\t%s` + indented message per failing result and `return 1` when any failed (else 0); `cmd/lint/main.go` result loop + `Runner.Check` (`run.go`).
2. **fix transforms** — met. `doFix` → `Runner.Fix` mutates in place / stdin-filter (`run.go`); `TestRuleFixtures` asserts bad→fixed and re-check pass (`rules_test.go`).
3. **staged adapter** — met. `stagedTargets` materializes `git show :name` blobs to temp + offers blob on stdin; default policy (no `--warn`) returns 1 (`adapters.go`, `main.go`).
4. **changed adapter** — met. `changedTargets` runs `git diff --name-only ref` (default HEAD) (`adapters.go`).
5. **hook adapter** — met. `hookTargets` unmarshals `tool_input.file_path`; `--warn` suppresses nonzero exit (`adapters.go`, `main.go` `failed && !*warn`).
6. **five rules** — met. `gofmt/json-fmt/md-shape/settings-sort/shellcheck` manifests with `select.extensions|shebangs|paths` (`lint/rules.d/*.toml`).
7. **fix-command output** — met. Wrapper checks emit `fix: …` lines (`lint/libexec/{gofmt,json-fmt,md-shape,settings-sort}-check`). (See spec-gap re: shellcheck.)
8. **config inheritance** — met. `ResolveConfig` walks file→root, applies base..nearest so nearer `rules` wins, unset key inherits; `TestConfigInheritance` covers nested override + omitted-key inherit (`config.go`, `config_test.go`).
9. **concurrent dispatch** — met. `Schedule` runs a bounded pool of `--jobs` workers over a job channel (`schedule.go`, `main.go` `*jobs`).
10. **deterministic output** — met. `Schedule` sorts results by `(Path, Rule)`; `TestScheduleDeterministic` asserts jobs=1 ≡ jobs={2,4,16} and sorted order (`schedule.go`, `schedule_test.go`).
11. **sound cache** — met. Key = sha256(ruleName‖manifestHash‖contentHash); only passes stored; `TestCacheColdWarmInvalidate`/`TestCacheKeyIdentity`/`TestCacheDoesNotStoreFailures` cover skip, content-change miss, rule-identity, no stale fail (`cache.go`, `cache_test.go`).
12. **tests green, none skipped** — met. Gate green; test files cover classifier, selection, scheduler, cache, config, all five fixtures; no `t.Skip` present (`*_test.go`).

**Design soundness: 4** — Abstractions match the spec's seams cleanly (manifest/libexec rules, classifier, pure selection, scheduler, content-addressed cache, layered config), with cosmetic friction only: the tested pure `SelectPairs` is dead in production because `selectJobs` re-implements the same `Matches` loop to thread config scoping.

**Spec-gap findings:**
- The rule-manifest contract ("a failing `check` prints a copy-pasteable fix command") is unenforced and silently violated by `shellcheck.toml`, which invokes `shellcheck {file}` raw — its native output gives wiki URLs, not a copy-pasteable fix command. The spec mandates the contract for every rule but ships a starting rule that cannot honor it and provides no check that a manifest's `check` emits a fix line.
- The spec fixes cache location to `--cache-dir`/XDG but never specifies cache eviction or staleness bounds across rule-manifest *edits to unrelated rules*; here it's safe because the key folds `manifestHash`, but the spec leaves "rule identity" undefined (name vs. manifest bytes), so a correct-by-luck choice was made — worth pinning.
- The spec says fix is working-tree only and the staged hook "blocks and prints, never auto-mutates," but does not require `fix` to refuse `--staged`/`--from-hook`; `doFix` will run against whatever targets the adapter produced, so a `lint fix --staged` invocation mutates temp blobs silently with no guard.