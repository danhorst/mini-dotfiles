## Compliance tally: 12/12

1. **check exit contract** — MET. `engine.go:74-88` check mode sets `hasFailure` and `return 1, nil` when a result fails (else 0), printing `%s [%s]` + message per violation.
2. **fix transforms** — MET. `scheduler.go:processPair` fix-mode runs `pair.Rule.Fix`; `rules_test.go` (`TestSettingsSortRule`/`TestGofmtRule`/etc.) assert bad→fixed per rule.
3. **staged adapter** — MET. `adapters.go:sourceStaged` materializes each blob via `git show :path` into a temp file pointed at by `ContentPath` (working tree untouched); `--staged` runs without `--warn` so it blocks (`main.go`, `engine.go:90`).
4. **changed adapter** — MET. `adapters.go:sourceChanged` runs `git diff --name-only ... <ref>` (ref via `--changed-ref`, default HEAD); `adapters_test.go:TestSourceChangedCustomRef`.
5. **hook adapter** — MET. `adapters.go:sourceFromHook` decodes `tool_input.file_path`; with `--warn`, `engine.go:88` returns 0 unconditionally.
6. **five rules** — MET. `lint/rules.d/{shellcheck,settings-sort,md-shape,gofmt,json-fmt}.toml`, each with declarative `select.*`; `manifest_test.go:TestLoadRulesFiveManifests`.
7. **fix-command output** — MET. Every rule's `check` echoes a `fix: …` line before `exit 1` (`gofmt.toml`, `json-fmt.toml`, `md-shape.toml`, `settings-sort.toml`, `shellcheck.toml`).
8. **config inheritance** — MET. `config.go:ActiveRulesFor` walks from file dir up to base, nearest layer with `hasRules` wins; `config_test.go:TestConfigNearestWins`, `TestConfigNoRulesKeyFallsThrough`.
9. **concurrent dispatch** — MET. `scheduler.go:RunPairs` spawns `jobs` worker goroutines over a channel; `--jobs` flag in `main.go` (default `NumCPU`).
10. **deterministic output** — MET. `scheduler.go:RunPairs` sorts results by `(Path, Rule)` after collection; `scheduler_test.go:TestSchedulerDeterministic` (jobs 1 vs 8) and `TestSchedulerSortOrder`.
11. **sound cache** — MET. `cache.go:key` hashes `contentHash + name + manifestHash`; `processPair` reuses only on `Get` hit and `Put`s only on pass; `cache_test.go:TestCacheContentChangeInvalidates`, `TestCacheRuleIdentityInKey`.
12. **tests green, none skipped** — MET. Gate reported green; no `t.Skip` anywhere in `cmd/lint/*_test.go`; suites cover classifier, selection, scheduler, cache, config, all five rules.

## Design soundness: 4

The manifest/orchestrator/scheduler/cache/config seams map cleanly onto the spec's six pieces, but staged materialization keys temp files on `filepath.Base(path)` (`adapters.go:88`), silently colliding two staged files of the same basename in different directories.

## Spec-gap findings

- **Staged collision safety unspecified.** The spec pins "staged blob materialized to a temp file" but never requires collision-safe paths; the code uses basename and would clobber same-named files across directories. Promote a fixture with two `x.go` in different dirs.
- **`io = "stdin"` is unexercised.** The spec defines stdin io and pins it for `--staged`, but all five starting rules are `io = "path"`, so no fixture ever drives the stdin branch (`scheduler.go:runCommand`). The checklist's "five rules" item waves this through.
- **`--changed [REF]` ref form left loose.** The spec writes a positional `[REF]`; the code implements it as a `--changed-ref` flag. Neither form is pinned, so the deviation passes with impunity.
- **Cache growth/eviction unspecified.** The cache writes one marker file per `(content,rule)` forever with no eviction contract; nothing in spec or checklist constrains lifecycle.