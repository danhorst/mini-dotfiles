# fixture lint+ — normative checklist

The MUST items the grader scores compliance against, gradeable from the built binary and its tests in isolation.
Derived from `SPEC.md` but scoped to what a clean-room implementation can satisfy: the spec's repo-integration items (reduce the pre-commit hook, edit `settings.json`, extract to `danhorst/lint`) are out of scope and not listed here.
Per the spec-gap→checklist discipline, the latent-correctness properties the new features can silently violate (deterministic ordering under concurrency, cache invalidation) are MUST items here, not left to design judgment.

- **check exit contract.** `lint check PATHS` exits nonzero on a violation and zero on clean input, printing a human message per violation.
- **fix transforms.** `lint fix PATHS` turns a rule's `bad` fixture into its `fixed` form.
- **staged adapter.** `lint --staged` lints blobs materialized from the git index, not the working tree, and blocks on a violation.
- **changed adapter.** `lint --changed [REF]` lints files changed against a ref.
- **hook adapter.** `lint --from-hook --warn` reads PostToolUse JSON on stdin, extracts `tool_input.file_path`, and always exits zero.
- **five rules.** Manifests for shellcheck, settings-sort, md-shape, gofmt, and json-fmt exist, each with declarative selectors by extension, shebang, or path.
- **fix-command output.** A failing `check` prints a copy-pasteable fix command, per the rule-manifest contract.
- **config inheritance.** A base `lint.toml` plus a nearer per-directory `lint.toml` resolve nearest-wins: the nearer layer scopes which rules run for files under it, and an unspecified key inherits from the parent. An unread config does not satisfy this.
- **concurrent dispatch.** Independent `(rule, file)` checks run across a bounded worker pool sized by `--jobs`.
- **deterministic output.** Aggregated results are byte-identical and identically ordered for `--jobs 1` and `--jobs N`, sorted by `(path, rule)` regardless of worker completion order.
- **sound cache.** A warm `(content-hash, rule)` key skips re-running the check; a content change invalidates the entry and re-checks; the cache never serves a stale pass.
- **tests green, none skipped.** `go test ./...` passes with zero skipped tests, covering the classifier, the selection engine, the scheduler, the cache, config inheritance, and all five rules' fixtures. A skipped rule test is not coverage.
