## Compliance: 10/12

1. **check exit contract** — MET. `runCheck` prints `%s:%s: %s` per failing result and returns an error; `handleCheck` calls `os.Exit(1)` when not `--warn` (`main.go` `runCheck`/`handleCheck`).
2. **fix transforms** — MET. `Scheduler.Fix` runs the manifest `fix` command in place; `rules_test.go` `testRuleFixtures` asserts bad→fixed for each fixable rule and passes (gate green).
3. **staged adapter** — **NOT MET.** `getStagedFiles` runs `git diff --cached --name-only` and returns working-tree path names; it never materializes the staged blob (`git show :FILE`). The pinned decision requires linting the index blob, not the working tree (`main.go` `getStagedFiles`). Additionally `lint --staged` is unreachable — `main.go` requires a `check`/`fix` verb as `os.Args[1]`.
4. **changed adapter** — MET. `getChangedFiles` runs `git diff REF...HEAD --name-only` (`main.go`). Note: the bare `--changed` (no value) form falls through to args and lints nothing, since `getFiles` gates on `changed != ""`.
5. **hook adapter** — MET. `getFilesFromHook` decodes stdin into `PostToolUseInput.ToolInput.FilePath`; with `--warn`, `handleCheck` suppresses the exit (`main.go`). Reachable only as `lint check --from-hook --warn`, not the documented `lint --from-hook`.
6. **five rules** — MET. `rules/rules.d/{shellcheck,settings-sort,md-shape,gofmt,json-fmt}.toml`, each with `select.extensions`/`shebangs`/`paths`.
7. **fix-command output** — **NOT MET.** No check command emits a copy-pasteable fix command: `gofmt` (`test -z "$(gofmt -l {file})"`), `json-fmt`, `settings-sort`, and `md-shape` all suppress output to `/dev/null` or produce none on failure; `shellcheck` prints only its own diagnostics (`rules/rules.d/*.toml`).
8. **config inheritance** — MET. `loadConfigForFile` walks file→root prepending parents, then merges child-over-parent; `isRuleActive` consulted in `Scheduler.Check` and `runFix` (`config.go`, `scheduler.go`). `config_test.go` `TestConfigInheritance` verifies override + inherit.
9. **concurrent dispatch** — MET. `Scheduler.Check` fans `(file,rule)` jobs across `s.jobs` workers sized by `--jobs`/`NumCPU` (`scheduler.go`, `main.go`).
10. **deterministic output** — MET. `Scheduler.Check` sorts results by `(File, Rule)` after collection; `scheduler_test.go` `TestSchedulerDeterministicOutput` asserts jobs=1 vs jobs=N parity.
11. **sound cache** — MET. Key is content-hash + `manifest.Identity()` (name+manifest md5); `Cache.Get` re-reads and re-verifies the content hash before returning (`cache.go`); `cache_test.go` covers cold/warm/invalidate/identity.
12. **tests green, none skipped** — MET. Gate green; no `t.Skip` present; tests exist for classifier, selector, scheduler, cache, config, and all five rule fixtures.

## Design soundness: 2

The package mirrors the spec's six seams (manifest/classifier/selector/scheduler/cache/config), but load-bearing behavior is wrong or gamed — the staged adapter lints the working tree instead of materialized index blobs, the rules are degenerate placeholders (`md-shape` check is `test -s`, its fix is a constant `echo '# Fixed'`; `json-fmt` ignores the settings-sort exclusion), fixers `mv` through a shared hardcoded `/tmp/fmt.json`, and the documented `lint --staged/--changed/--from-hook` surface is unreachable without an undocumented `check` verb.

## Spec-gap findings

- **Fixture-pass is gameable by a constant-output fix.** "fix turns bad into fixed" (checklist) is satisfiable by a `fix` that ignores input and writes the fixed fixture verbatim — `md-shape.toml`'s `fix = "echo '# Fixed' > {file}"` does exactly this and passes. The spec/checklist should require fix to be a content transform (e.g. fix applied to `ok` is a no-op, or fix is idempotent), not merely bad→fixed.
- **No fixture exercises rule overlap / the settings-sort exclusion.** The spec says `json-fmt` selects JSON "not already owned by settings-sort," but nothing requires a file matched by two rules; `json-fmt.toml` selects all `.json` and would double-fire on `settings.json` with impunity.
- **Surface form is unpinned.** The spec's surfaces table shows `lint --staged` / `lint --from-hook` but does not pin whether adapters are top-level flags or subcommands, letting the implementation bury them under a `check` verb without failing any MUST.