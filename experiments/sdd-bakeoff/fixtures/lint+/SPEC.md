# lint+

A pluggable linting engine: the `lint` orchestrator grown to extraction scale — more rules, parallel dispatch, a result cache, and layered config.
This is the shape `lint` takes on its way to `danhorst/lint`.

## Goals

- One engine, three invocation surfaces, identical results.
- Rules plug in declaratively; adding a rule means dropping a manifest, not editing the orchestrator.
- The orchestrator decides only *which* files to lint and how to *schedule* the work; the rule decides *how* to check.
- Linting a large tree is fast: independent (rule, file) checks run concurrently, and unchanged work is skipped via a cache.
- Config layers: a base config and per-directory overrides that merge predictably.
- Every rule and every engine concern has unit tests.

## Model

Six pieces.

- **Rules** are the unit of linting.
  Each rule wraps an existing tool and knows how to check, and optionally fix, one kind of file.
- **Selectors** are declarative metadata on each rule stating which files it applies to: by extension, by interpreter shebang, or by exact path or glob.
- **The orchestrator** (`lint`) does file-selection, scheduling, and dispatch only.
- **Config** is the per-context layer naming which rules are active and any path scoping, now layered.
- **The scheduler** runs the matching (rule, file) checks across a bounded worker pool.
- **The cache** memoizes check outcomes keyed on file content, so an unchanged (rule, file) pair is not re-run.

The orchestrator is a single Go binary.
Rules are thin executables described by a TOML manifest.

## Rule manifest

A rule advertises its selector declaratively so the orchestrator can match files without spawning the rule, then exposes a check command and an optional fix command.

```toml
name = "shellcheck"
select.extensions = ["sh", "bash"]
select.shebangs   = ["sh", "bash"]
io    = "path"                          # "path" passes {file}; "stdin" pipes content
check = "shellcheck {file}"
# no fix key means the rule is check-only
```

- `check` exits nonzero on a violation and prints a human message plus a copy-pasteable fix command to stdout.
- `fix`, when present, mutates in place or acts as a stdin-to-stdout filter.
- A rule is policy-free: it does not know whether the caller will warn or block.

Manifests live in `lint/rules.d/`.

### Starting rules

Five conventions become five manifests, each shipping `testdata/<rule>/{ok,bad,fixed}/`.

- `shellcheck.toml` selects shell extensions and shebangs and runs shellcheck.
- `settings-sort.toml` selects `claude/settings.json` and `settings.local.json`, checks that `.permissions.allow` is sorted, and fixes with `json-sort`.
- `md-shape.toml` selects Markdown and checks the `mdsplit | mdtable` shape, fixing in place.
- `gofmt.toml` selects `.go` and checks `gofmt -l`, fixing with `gofmt -w`.
- `json-fmt.toml` selects `.json` not already owned by `settings-sort`, checks key-sorted form, and fixes with `json-sort`.

## The orchestrator

### Input adapters

The file list comes from one of four sources, one per surface.

- `lint check PATHS…` and `lint fix PATHS…` take explicit arguments for human use.
- `lint --staged` takes staged files, materialized from the staged blob with `git show :FILE`.
- `lint --changed [REF]` takes files changed against a ref.
- `lint --from-hook` reads the PostToolUse JSON on stdin and extracts `tool_input.file_path`.

### Selection engine

A shared classifier resolves each file's type by extension and by sniffing its shebang interpreter.
The engine computes the `(rule, file)` pairs and dispatches only the matching rules.

### Scheduler

Independent `(rule, file)` checks run concurrently across a bounded worker pool sized by `--jobs N` (default `NumCPU`).
Concurrency is an optimization only: the aggregated results are emitted in a stable, deterministic order — sorted by `(path, rule)` — regardless of the order workers finish.

### Cache

A content-addressed cache memoizes check outcomes.
The key is the file's content hash plus the rule's identity (name and manifest).
A cached pass is reused only when the content hash still matches; any content change is a miss and the check re-runs.
The cache lives under a cache directory (`--cache-dir`, defaulting to an XDG cache path).

### Policy flags

- Default exits with a meaningful code; the pre-commit hook blocks on it.
- `--warn` always exits zero and prints reminders; the PostToolUse hook uses it.
- The `fix` verb applies fixers.

## Config

Config is layered.

- A base `lint.toml` plus per-directory `lint.toml` overrides, discovered by walking from each file toward the base.
- The nearest `lint.toml` to a file determines its active rules; a key absent from a nearer layer inherits from the parent.
- A rule absent from the resolved active-rules list does not execute for that file.

## Surfaces

| Surface          | Invocation                             | Policy           |
| ---------------- | -------------------------------------- | ---------------- |
| pre-commit hook  | `lint --staged`                        | block            |
| human CLI        | `lint check PATHS` or `lint fix PATHS` | report or mutate |
| PostToolUse hook | `lint --from-hook --warn`              | warn only        |

All three collapse to the same engine; only the adapter and the policy flag differ.

## Pinned decisions

- **Staged content is linted, not the working tree.**
  For `--staged`, each staged blob is materialized to a temp file that `{file}` points at; `io = "stdin"` rules receive the blob on stdin directly.
- **Fix is working-tree only; the pre-commit hook blocks and prints, it never auto-mutates.**
- **Path scoping lives in the caller, not the rule.** Rule manifests stay location-agnostic.
- **Concurrency is never observable.** Parallel dispatch must not change output; results are sorted by `(path, rule)` before emit, so `--jobs 1` and `--jobs N` are byte-identical. Nondeterministic ordering is a correctness bug, not a speed trade.
- **The cache is sound, never stale.** A result is reused only when content hash and rule identity match; a changed file always re-checks. A cache that serves a stale pass has corrupted the gate, not optimized it.
- **Config is nearest-wins.** The nearest `lint.toml` to a file sets its active rules; unspecified keys inherit from the parent layer.

## Testing

- **Per-rule fixtures** live in `lint/testdata/<rule>/{ok,bad,fixed}/`.
  Each rule's `check` must pass on `ok`, fail on `bad` with a message, and `fix` must turn `bad` into `fixed`.
- **Classifier tests** cover extension and shebang edge cases: the zsh false positive, files with no shebang, and `env`-style shebangs.
- **Selection-engine tests** assert the right `(rule, file)` pairs for a given manifest set and file list.
- **Scheduler tests** assert results are identical and identically ordered for `--jobs 1` and `--jobs N` — determinism under concurrency.
- **Cache tests** assert a cold key runs the check, a warm key skips it, a content change invalidates (no stale pass), and the key includes rule identity.
- **Config tests** assert a base plus a nested override changes the active rules for files under the override.

## Layout

```
bin/lint                              # built binary, installed by install.sh
cmd/lint/                             # Go source and *_test.go
lint/rules.d/*.toml                   # five rule manifests
lint/testdata/<rule>/{ok,bad,fixed}/  # per-rule fixtures
lint.toml                             # base repo-local config
**/lint.toml                          # per-directory overrides
```

`install.sh` builds the binary with `go build -o bin/lint ./cmd/lint`.
The binary is not committed.

## Done

- `lint check`, `lint fix`, `--staged`, `--changed`, and `--from-hook --warn` all work against the five starting rules.
- The scheduler runs checks concurrently with deterministic, stably-ordered output.
- The cache skips unchanged `(rule, file)` pairs and invalidates on content change.
- Config inheritance resolves the nearest `lint.toml` per file.
- `go test ./...` is green across the classifier, the selection engine, the scheduler, the cache, config inheritance, and all five rules' fixtures, with no skipped tests.

## Growth

This is the extraction candidate.
It moves to `danhorst/lint` and ships through `danhorst/homebrew-tap`; dotfiles then declares `brew "lint"` and carries only repo-local rule config.
The manifest-and-config split is the seam that makes that extraction cheap.
