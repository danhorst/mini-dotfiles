# fixture lint — normative checklist

The MUST items the grader scores compliance against, gradeable from the built binary and its tests in isolation.
Derived from `SPEC.md` but scoped to what a clean-room implementation can satisfy: the spec's repo-integration Done items (reduce the pre-commit hook, edit `settings.json`, remove `md-format-check.sh`) are out of scope for the bake-off and are not listed here.

- **check exit contract.** `lint check PATHS` exits nonzero on a violation and zero on clean input, printing a human message per violation.
- **fix transforms.** `lint fix PATHS` turns a rule's `bad` fixture into its `fixed` form.
- **staged adapter.** `lint --staged` lints blobs materialized from the git index, not the working tree, and blocks on a violation.
- **hook adapter.** `lint --from-hook --warn` reads PostToolUse JSON on stdin, extracts `tool_input.file_path`, and always exits zero.
- **changed adapter.** `lint --changed [REF]` lints files changed against a ref.
- **three rules.** Manifests for shellcheck, settings-sort, and md-shape exist, each with declarative selectors by extension, shebang, or path.
- **config is honored.** `lint.toml`'s active-rules list actually scopes which rules run; a rule absent from it does not execute. An unread `lint.toml` does not satisfy this — Config is one of the spec's four named pieces.
- **fix-command output.** A failing `check` prints a copy-pasteable fix command, per the spec's rule-manifest contract.
- **tests green, none skipped.** `go test ./...` passes with zero skipped tests, covering the classifier, the selection engine, and all three rules' fixtures. A skipped rule test is not coverage.
