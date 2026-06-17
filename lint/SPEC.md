# lint

A pluggable linting system invoked by a pre-commit hook, by a human on the command line, and by the Claude Code PostToolUse lifecycle hook.

## Goals

- One engine, three invocation surfaces, identical results.
- Rules plug in declaratively; adding a rule means dropping a manifest, not editing the orchestrator.
- The orchestrator decides only *which files* to lint; the rule decides *how*.
- Every rule has unit tests.

## Model

Four pieces.

- **Rules** are the unit of linting.
  Each rule wraps an existing tool (shellcheck, rubocop, json-sort, the md-tools chain) and knows how to check, and optionally fix, one kind of file.
- **Selectors** are declarative metadata on each rule stating which files it applies to: by extension, by interpreter shebang, or by exact path or glob.
- **The orchestrator** (`lint`) does file-selection and dispatch only.
  It takes a file list from some source, matches files against rule selectors, runs the matching rules, and aggregates results.
- **Config** is the per-context layer naming which rules are active and any path scoping.

The orchestrator is a single Go binary.
Rules are thin executables described by a TOML manifest.

## Rule manifest

A rule advertises its selector declaratively so the orchestrator can match files without spawning the rule, then exposes a check command and an optional fix command.

```toml
name = "shellcheck"
select.extensions = ["sh", "bash"]      # zsh is excluded: shellcheck rejects it (SC1071)
select.shebangs   = ["sh", "bash"]      # matched against the interpreter basename
io    = "path"                          # "path" passes {file}; "stdin" pipes content
check = "shellcheck {file}"
# no fix key means the rule is check-only
```

- `check` exits nonzero on a violation and prints a human message plus a copy-pasteable fix command to stdout.
- `fix`, when present, mutates in place or acts as a stdin-to-stdout filter.
- A rule is policy-free.
  It does not know whether the caller will warn or block; that is the caller's decision.

Manifests live in `lint/rules.d/`.
TOML is chosen over JSON for authoring ergonomics, at the cost of one parser dependency in Go.

### Starting rules

The three conventions enforced today become three manifests.

- `shellcheck.toml` selects shell extensions and shebangs and runs shellcheck.
- `settings-sort.toml` selects `claude/settings.json` and `claude/settings.local.json`, checks that `.permissions.allow` is sorted, and fixes with `json-sort`.
- `md-shape.toml` selects Markdown extensions and checks the `mdsplit | mdtable` shape, fixing with `mdsplit "{file}" | mdtable -i "{file}"`.

## The orchestrator

### Input adapters

The file list comes from one of four sources, one per surface.

- `lint check PATHS…` and `lint fix PATHS…` take explicit arguments for human use.
- `lint --staged` takes staged files, materialized from the staged blob with `git show :FILE` rather than the working tree.
- `lint --changed [REF]` takes files changed against a ref.
- `lint --from-hook` reads the PostToolUse JSON on stdin and extracts `tool_input.file_path`.

### Selection engine

A shared classifier resolves each file's type by extension and by sniffing its shebang interpreter.
The engine computes the `(rule, file)` pairs and dispatches only the matching rules.

### Policy flags

Policy is the caller's decision, not the rule's.

- Default exits with a meaningful code; the pre-commit hook blocks on it.
- `--warn` always exits zero and prints reminders; the PostToolUse hook uses it.
- The `fix` verb applies fixers.

## Surfaces

| Surface          | Invocation                             | Policy           |
| ---------------- | -------------------------------------- | ---------------- |
| pre-commit hook  | `lint --staged`                        | block            |
| human CLI        | `lint check PATHS` or `lint fix PATHS` | report or mutate |
| PostToolUse hook | `lint --from-hook --warn`              | warn only        |

All three collapse to the same engine; only the adapter and the policy flag differ.
The current pre-commit hook, the three inline commands in `claude/settings.json`, and `claude/bin/md-format-check.sh` all retire.

## Pinned decisions

- **Staged content is linted, not the working tree.**
  For `--staged`, each staged blob is materialized to a temp file that `{file}` points at; `io = "stdin"` rules receive the blob on stdin directly.
  This designs out the working-tree mismatch in the current hook.
- **Fix is working-tree only; the pre-commit hook blocks and prints, it never auto-mutates.**
  A failing staged check prints the fix command rather than rewriting and re-staging the blob.
  Auto-fix-and-restage is a deliberate later feature.
- **Path scoping lives in the caller, not the rule.**
  The global PostToolUse hook restricts reshaping to `~/git/danhorst/` via a `--root` scope; an in-repo run does not.
  Rule manifests stay location-agnostic, so `md-format-check.sh`'s personal-repo gate moves to the hook wrapper.

## Testing

- **Per-rule fixtures** live in `lint/testdata/<rule>/{ok,bad,fixed}/`.
  Each rule's `check` must pass on `ok`, fail on `bad` with a message, and `fix` must turn `bad` into `fixed`.
  Because every rule is a CLI with a fixed contract, this is uniform regardless of the wrapped tool.
- **Classifier unit tests** cover extension and shebang edge cases: the zsh false positive, files with no shebang, and `env`-style shebangs.
- **Selection-engine tests** assert the right `(rule, file)` pairs for a given manifest set and file list.

## Layout

```
bin/lint                              # built binary, installed by install.sh
cmd/lint/                             # Go source and *_test.go
lint/rules.d/*.toml                   # rule manifests
lint/testdata/<rule>/{ok,bad,fixed}/  # per-rule fixtures
lint.toml                             # repo-local config: active rules and scopes
```

`install.sh` builds the binary with `go build -o bin/lint ./cmd/lint`, gated on the `go` toolchain the Brewfile already provides.
The binary is not committed.

## Done

- `lint check`, `lint fix`, `--staged`, and `--from-hook --warn` all work against the three starting rules.
- The pre-commit hook is reduced to `exec lint --staged`.
- `claude/settings.json` PostToolUse is reduced to one `lint --from-hook --warn` per surface.
- The old pre-commit hook and `md-format-check.sh` are removed.
- `go test ./...` is green across the classifier, the selection engine, and all three rules' fixtures.

## Growth

If this outgrows dotfiles, it extracts to `danhorst/lint` and ships through `danhorst/homebrew-tap` like md-tools. dotfiles then declares `brew "lint"` and carries only repo-local rule config.
The manifest-and-config split is the seam that makes that extraction cheap.
