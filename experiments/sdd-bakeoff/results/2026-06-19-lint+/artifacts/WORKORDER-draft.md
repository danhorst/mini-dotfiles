# WORK ORDER: `lint+` Pluggable Linting Engine

You are implementing a Go CLI named `lint`. Follow every task literally. Make no design decisions beyond what is written here. When a task says "exact," reproduce it byte-for-byte.

---

## 0. Prerequisites and module setup

1. Confirm there is a Go module rooted at the repo root. If `go.mod` does not exist, run `go mod init lint` (module path `lint`).
2. Add the only third-party dependency: `github.com/BurntSushi/toml`. Run `go get github.com/BurntSushi/toml` after the first file that imports it compiles.
3. Add `/bin/` to `.gitignore` if not already present. The built binary at `bin/lint` is **never committed**.
4. Go standard-library packages you will use: `crypto/sha256`, `encoding/hex`, `encoding/json`, `os`, `os/exec`, `path/filepath`, `sort`, `strings`, `bufio`, `sync`, `runtime`, `flag`, `fmt`, `io`, `errors`.

---

## 1. Final file and directory layout

Create exactly these files. Every `.go` file is `package main` in directory `cmd/lint/`.

```
install.sh                              # build script (task 13)
go.mod / go.sum                         # module + deps
lint.toml                               # base repo-local config (task 11)
cmd/lint/main.go                        # entry point, flag parsing, verb dispatch (task 10)
cmd/lint/manifest.go                    # Rule + Selector types, manifest loading (task 3)
cmd/lint/classifier.go                  # file-type classification (task 5)
cmd/lint/selector.go                    # selector matching + selection engine (task 6)
cmd/lint/config.go                      # layered config discovery + resolution (task 7)
cmd/lint/scheduler.go                   # bounded worker pool + deterministic emit (task 8)
cmd/lint/cache.go                       # content-addressed cache (task 9)
cmd/lint/adapters.go                    # the four input adapters (task 4)
cmd/lint/engine.go                      # orchestrator: wires everything, runs a verb (task 10)
cmd/lint/manifest_test.go
cmd/lint/classifier_test.go
cmd/lint/selector_test.go
cmd/lint/config_test.go
cmd/lint/scheduler_test.go
cmd/lint/cache_test.go
cmd/lint/rules_test.go                  # fixture-driven, iterates all rules (task 12)
lint/rules.d/shellcheck.toml            # task 3.5
lint/rules.d/settings-sort.toml
lint/rules.d/md-shape.toml
lint/rules.d/gofmt.toml
lint/rules.d/json-fmt.toml
lint/testdata/<rule>/{ok,bad,fixed}/    # five rule fixture trees (task 12)
```

Splitting `.go` source across more files is allowed only if every symbol named below keeps the exact name and signature given.

---

## 2. Core data types (put in `manifest.go` unless noted)

Define these types verbatim.

```go
// Selector is declarative match metadata read from a rule manifest.
type Selector struct {
	Extensions []string        `toml:"extensions"` // e.g. ["sh","bash"], no leading dot
	Shebangs   []string        `toml:"shebangs"`   // interpreter basenames, e.g. ["sh","bash"]
	Paths      []string        `toml:"paths"`      // exact path/basename matches
	Globs      []string        `toml:"globs"`      // filepath.Match globs
	Exclude    *ExcludeSelector `toml:"exclude"`   // optional; files matched here are NOT selected
}

type ExcludeSelector struct {
	Paths []string `toml:"paths"`
	Globs []string `toml:"globs"`
}

// Rule is one manifest from lint/rules.d/.
type Rule struct {
	Name   string   `toml:"name"`
	Select Selector `toml:"select"`
	IO     string   `toml:"io"`    // "path" (default) or "stdin"
	Check  string   `toml:"check"` // command template, may contain {file}
	Fix    string   `toml:"fix"`   // optional; empty means check-only

	manifestPath string // set at load time, not from TOML
	manifestHash string // sha256 of raw manifest bytes; set at load time
}

// Result is the outcome of one (rule, file) check.
type Result struct {
	Path    string // file path as supplied to the engine
	Rule    string // rule.Name
	Passed  bool
	Message string // rule stdout (human message + fix command) when Passed == false
}
```

- `IO` defaults to `"path"` when the manifest omits the `io` key. Enforce: after decode, if `r.IO == ""` set it to `"path"`. The only legal values are `"path"` and `"stdin"`; any other value is a load error.

---

## 3. Manifest loading (`manifest.go`)

### 3.1 Functions

```go
// LoadRule decodes one manifest file and stamps manifestPath + manifestHash.
func LoadRule(path string) (Rule, error)

// LoadRules loads every *.toml in dir, sorted by filename, returning rules keyed/ordered deterministically.
func LoadRules(dir string) ([]Rule, error)
```

### 3.2 Tasks

1. `LoadRule` reads the file bytes once. Compute `manifestHash = hex(sha256(bytes))`. Decode the same bytes with `toml.Decode`. Set `manifestPath = path`.
2. Validate after decode: `Name` non-empty; `IO` is `"path"` or `"stdin"` (apply the `""→"path"` default first); `Check` non-empty. On any failure return an error naming the file and the problem.
3. `LoadRules` lists `*.toml` in `dir`, sorts the filenames ascending, loads each, and returns the slice in that sorted order. A load error on any file aborts with that error.
4. Rules are **policy-free**: nothing in this file reads or stores warn/block behavior.

### 3.3 The five manifests (`lint/rules.d/`)

Write these exact files.

`shellcheck.toml`
```toml
name = "shellcheck"
select.extensions = ["sh", "bash"]
select.shebangs   = ["sh", "bash"]
io    = "path"
check = "shellcheck {file}"
```

`settings-sort.toml`
```toml
name = "settings-sort"
select.globs = ["**/settings.json", "**/settings.local.json", "claude/settings.json"]
io    = "path"
check = "json-sort --check --path .permissions.allow {file}"
fix   = "json-sort --path .permissions.allow {file}"
```

`md-shape.toml`
```toml
name = "md-shape"
select.extensions = ["md", "markdown"]
io    = "path"
check = "md-shape --check {file}"
fix   = "md-shape --fix {file}"
```

`gofmt.toml`
```toml
name = "gofmt"
select.extensions = ["go"]
io    = "path"
check = "gofmt -l {file}"
fix   = "gofmt -w {file}"
```

`json-fmt.toml`
```toml
name = "json-fmt"
select.extensions = ["json"]
select.exclude.globs = ["**/settings.json", "**/settings.local.json", "claude/settings.json"]
io    = "path"
check = "json-sort --check {file}"
fix   = "json-sort {file}"
```

> Note the json-fmt `exclude` block: it restates the spec's "`.json` not already owned by `settings-sort`" as a literal exclusion using the same patterns `settings-sort` selects.

---

## 4. Input adapters (`adapters.go`)

Each adapter returns the list of files to lint plus, for `--staged`, a way to feed staged content. Define:

```go
// FileSource yields the files to lint and how to read each one's content.
type FileSource struct {
	Files []SourceFile
}

type SourceFile struct {
	Path        string // logical path used for selection, sorting, and {file} default
	ContentPath string // filesystem path to read/pass as {file}; == Path for working-tree adapters
	cleanup     func() // removes temp file for staged blobs; may be nil
}
```

Implement these four constructors. Each returns `(FileSource, error)`.

1. `func sourceFromArgs(paths []string) (FileSource, error)` — for `lint check PATHS…` / `lint fix PATHS…`. For each arg: if it is a directory, walk it recursively and add every regular file; if a file, add it. `Path == ContentPath == the path`.
2. `func sourceStaged() (FileSource, error)` — run `git diff --cached --name-only --diff-filter=ACM`. For each staged path: materialize the staged blob to a temp file via `git show :PATH` (capture stdout, write to a temp file under `os.MkdirTemp`). Set `Path = staged path`, `ContentPath = temp file path`, and a `cleanup` that removes the temp file. **Staged content is linted, never the working tree.** For `io = "stdin"` rules the blob is piped on stdin (see 8.4); the temp file still backs `{file}` for `io = "path"` rules.
3. `func sourceChanged(ref string) (FileSource, error)` — if `ref == ""` default it to `"HEAD"`. Run `git diff --name-only --diff-filter=ACM <ref>`. `Path == ContentPath == working-tree path`.
4. `func sourceFromHook(stdin io.Reader) (FileSource, error)` — decode the PostToolUse JSON from stdin into a struct and extract `.tool_input.file_path`. Return a one-file source with `Path == ContentPath == that path`. If the field is absent/empty, return an empty `FileSource` with no error (nothing to lint).

```go
type hookPayload struct {
	ToolInput struct {
		FilePath string `json:"file_path"`
	} `json:"tool_input"`
}
```

5. Add `func (s FileSource) Close()` that calls every non-nil `cleanup`.

---

## 5. Classifier (`classifier.go`)

Resolves a file's type tags by extension and by sniffing its shebang interpreter.

```go
type FileClass struct {
	Ext     string // lowercased extension without dot, "" if none
	Shebang string // interpreter basename, "" if no shebang
}

// Classify reads up to the first line of contentPath to sniff a shebang.
func Classify(logicalPath, contentPath string) (FileClass, error)

// sniffShebang returns the interpreter basename for a "#!"-prefixed first line, else "".
func sniffShebang(firstLine string) string
```

### Tasks

1. `Ext`: `strings.TrimPrefix(filepath.Ext(logicalPath), ".")`, lowercased.
2. `sniffShebang`: line must start with `#!`. Strip `#!`, trim spaces, split on whitespace.
   - If the first token's basename is `env`, the interpreter is the **next** token (the `env`-style case). Example: `#!/usr/bin/env bash` → `bash`.
   - Otherwise the interpreter is `filepath.Base(firstToken)`. Example: `#!/bin/sh` → `sh`.
   - Strip a leading version-bare arg only if it is `env`; do not over-parse flags.
3. A file with **no** `#!` first line yields `Shebang == ""`.
4. `Classify` opens `contentPath`, reads the first line with `bufio.Scanner`, calls `sniffShebang`. Reading errors (e.g. unreadable) propagate. An empty file yields `Shebang == ""`.

---

## 6. Selector matching + selection engine (`selector.go`)

```go
// matches reports whether one rule's selector matches a classified file.
func (r Rule) matches(fc FileClass, logicalPath string) bool

// Pair is a (rule, file) unit of work.
type Pair struct {
	Rule Rule
	File SourceFile
}

// SelectPairs computes the matching (rule, file) pairs for the given rules and files,
// honoring per-file active-rule resolution from cfg.
func SelectPairs(rules []Rule, src FileSource, cfg *ConfigResolver) ([]Pair, error)
```

### `matches` tasks (a rule matches a file if **any** positive selector hits AND no exclude hits)

1. Exclude first: if `Select.Exclude != nil` and the file matches any `Exclude.Paths` (exact `Path` or basename equality) or any `Exclude.Globs` (via `globMatch`), return `false`.
2. Extension: true if `fc.Ext` is in `Select.Extensions`.
3. Shebang: true if `fc.Shebang != "" && fc.Shebang` is in `Select.Shebangs`.
4. Path: true if `logicalPath` equals an entry in `Select.Paths`, or `filepath.Base(logicalPath)` equals one.
5. Glob: true if any `Select.Globs` matches. Implement `globMatch(pattern, path)` supporting `**` by matching against both the full path and the basename, and falling back to `filepath.Match`. Treat `**/X` as "X at any depth" (match if basename-level `filepath.Match` of the trailing component succeeds or the full path matches with `**` collapsed).
6. The rule matches if (2)‖(3)‖(4)‖(5) is true and (1) did not exclude it.

### `SelectPairs` tasks

1. For each `SourceFile`, call `Classify`.
2. Resolve the file's **active rule set** via `cfg.ActiveRulesFor(file.Path)` (task 7). A rule whose `Name` is not in the resolved active set **does not execute** for that file.
3. For each active rule that `matches`, emit a `Pair`.
4. Return all pairs. Order here is not significant (the scheduler sorts on emit), but for reproducibility build them in `(file, rule)` input order.

---

## 7. Layered config (`config.go`)

Config names which rules are active, layered base + per-directory, nearest-wins.

### File format (`lint.toml`)

```toml
rules = ["shellcheck", "gofmt", "json-fmt"]   # active rule names at this layer
```

### Types + functions

```go
type ConfigLayer struct {
	Dir   string   // directory containing this lint.toml
	Rules []string // active rule names declared here
	hasRules bool   // whether the "rules" key was present
}

type ConfigResolver struct {
	baseDir string
	layers  map[string]ConfigLayer // dir -> layer, for every dir that has a lint.toml
}

// NewConfigResolver discovers lint.toml files from baseDir downward (or lazily by walk).
func NewConfigResolver(baseDir string) (*ConfigResolver, error)

// ActiveRulesFor walks from the file's directory up to baseDir, returning the
// nearest layer's rules; keys absent from a nearer layer inherit from the parent.
func (c *ConfigResolver) ActiveRulesFor(path string) []string
```

### Tasks

1. `baseDir` is the repo root (the directory containing the base `lint.toml`). Determine it as the working directory the engine runs in.
2. Load the base `lint.toml` and every `**/lint.toml` override into `layers`, keyed by the **directory** they sit in. Record `hasRules` = whether the `rules` key was present (so an empty `rules = []` is distinguishable from omission).
3. `ActiveRulesFor(path)`:
   - Start at `filepath.Dir(path)` (absolute-normalize relative to `baseDir`).
   - Walk parent directories up to and including `baseDir`.
   - The **nearest** layer that declares the `rules` key (`hasRules == true`) wins for the `rules` key. A key absent from nearer layers inherits from the parent (here there is only one key, `rules`, so nearest-with-`rules` wins; if no layer declares it, return the base layer's rules, else empty).
   - Return that rule-name slice.
4. **Nearest-wins** is the pinned semantics: the nearest `lint.toml` to a file sets its active rules; unspecified keys inherit from the parent layer.

---

## 8. Scheduler (`scheduler.go`)

Runs independent `(rule, file)` checks concurrently across a bounded pool, then emits results in a stable deterministic order.

```go
// RunPairs executes each pair's check (or fix, per mode) using up to jobs workers,
// consulting the cache, and returns results sorted by (Path, Rule).
func RunPairs(pairs []Pair, jobs int, mode Mode, cache *Cache) ([]Result, error)

type Mode int
const (
	ModeCheck Mode = iota
	ModeFix
)
```

### Tasks

1. If `jobs <= 0`, set `jobs = runtime.NumCPU()`.
2. Spawn a worker pool of size `jobs` consuming pairs from a channel; collect `Result`s. Use `sync.WaitGroup`.
3. Each worker, for one pair:
   - **Check mode:** consult the cache (task 9). On a cache hit (warm), produce a passing `Result` without spawning the tool. On miss, run the check command (task 8.3 below), record the outcome, and on a pass write the cache entry.
   - **Fix mode:** run the fix command if `Rule.Fix != ""`; if the rule is check-only, run the check (do not error on absence of a fixer—just report). Fix does not write cache pass entries.
4. After all workers finish, **sort results** with `sort.Slice` by `(Path, Rule)` ascending. This sort is mandatory and runs regardless of `jobs`. **Concurrency must never be observable**: `--jobs 1` and `--jobs N` output must be byte-identical. Nondeterministic ordering is a correctness bug.

### 8.3 Command execution

```go
// runCommand expands {file}, executes via the shell, and returns (passed, stdout).
func runCommand(template string, file SourceFile, io string) (passed bool, output string, err error)
```

1. Expand `{file}` in `template` with `file.ContentPath`.
2. Execute through the shell: `exec.Command("sh", "-c", expanded)`.
3. **stdin rules** (`io == "stdin"`): do not rely on `{file}`; pipe the file content to the command's stdin. For staged sources this is the staged blob; for working-tree sources it is the file bytes from `ContentPath`.
4. **Check semantics:** exit code 0 ⇒ `passed = true`; nonzero ⇒ `passed = false`, and `output` is the command's combined stdout (the human message + copy-pasteable fix command the rule prints).
5. Distinguish a tool that failed to launch (binary missing) — return that as `err` — from a tool that ran and reported a violation (`passed=false, err=nil`).

---

## 9. Cache (`cache.go`)

Content-addressed memoization of check passes. Sound, never stale.

```go
type Cache struct {
	dir string
}

// NewCache uses dir, or an XDG cache path when dir == "".
func NewCache(dir string) (*Cache, error)

// key = hash(file content) + rule identity (name + manifest hash).
func (c *Cache) key(rule Rule, contentHash string) string

func hashContent(path string) (string, error) // hex(sha256(file bytes))

// Get reports whether a passing result is cached for this key.
func (c *Cache) Get(rule Rule, contentHash string) (hit bool)

// Put records a passing result for this key.
func (c *Cache) Put(rule Rule, contentHash string) error
```

### Tasks

1. `NewCache("")` ⇒ `dir = filepath.Join(os.UserCacheDir(), "lint")`. Create it (`os.MkdirAll`).
2. `key` = `hex(sha256( contentHash + "\x00" + rule.Name + "\x00" + rule.manifestHash ))`. The key **must include rule identity** (name and manifest hash) so two rules over identical content do not collide, and a manifest edit invalidates.
3. A cache entry is a file named by the key under `dir`; its existence means "this `(content, rule)` passed."
4. `Get` returns true only when the entry exists for the exact key. Any content change yields a different `contentHash`, hence a different key, hence a **miss** that re-runs the check. There is no expiry and no path-based keying — only content + rule identity. A stale pass would corrupt the gate; do not implement TTLs or path keys.
5. Only **passing** checks are cached (`Put` called on pass). Failures are never cached.

---

## 10. Orchestrator + entry point (`engine.go`, `main.go`)

### 10.1 Flags and verbs (`main.go`)

Parse this surface:

- Verbs: `lint check PATHS…`, `lint fix PATHS…`.
- Mutually exclusive source flags: `--staged`, `--changed [REF]`, `--from-hook`.
- `--warn` (bool), `--jobs N` (int, default `runtime.NumCPU()`), `--cache-dir DIR` (string, default XDG).
- `--rules-dir DIR` default `lint/rules.d`.

Dispatch table:

| Invocation | Source adapter | Mode | Policy |
|---|---|---|---|
| `lint check PATHS…` | `sourceFromArgs` | check | report (exit nonzero on violation) |
| `lint fix PATHS…` | `sourceFromArgs` | fix | mutate working tree |
| `lint --staged` | `sourceStaged` | check | block (exit nonzero on violation) |
| `lint --changed [REF]` | `sourceChanged` | check | report |
| `lint --from-hook` | `sourceFromHook(os.Stdin)` | check | report unless `--warn` |
| `lint --from-hook --warn` | `sourceFromHook` | check | warn only (always exit 0) |

`--warn` is orthogonal: it may combine with any check source; it forces exit 0.

### 10.2 Engine flow (`engine.go`)

```go
func Run(opts Options) (exitCode int, err error)
```

1. Build `ConfigResolver` (task 7) rooted at the working directory.
2. `LoadRules(opts.RulesDir)` (task 3).
3. Build the `FileSource` from the chosen adapter (task 4). `defer src.Close()`.
4. `SelectPairs(rules, src, cfg)` (task 6).
5. `NewCache(opts.CacheDir)` (task 9).
6. `RunPairs(pairs, opts.Jobs, mode, cache)` (task 8).
7. Print results (task 10.3).
8. Compute exit code (task 10.4).

### 10.3 Output

- For each failing `Result` (already sorted by `(Path, Rule)`): print a block identifying `Path` and `Rule` followed by the rule's `Message` (its stdout — the human message and copy-pasteable fix command). Passing results print nothing (or a summary count; keep stdout deterministic and free of timing/worker info).
- Fix mode: report which files were mutated; do not print cached-pass noise.

### 10.4 Exit codes (pinned)

1. Check mode, no `--warn`: exit `0` if zero failing results, else exit `1`. The pre-commit hook (`--staged`) blocks on this nonzero code.
2. `--warn`: **always exit `0`**, printing reminders for any failures.
3. Fix mode: exit `0` on success; nonzero only if a fixer command itself failed to run.
4. **Fix is working-tree only.** The `--staged` pre-commit path never auto-mutates — it blocks and prints. Do not call fixers from the staged path.

---

## 11. Base config (`lint.toml`)

Write a repo-root `lint.toml` activating all five rules:

```toml
rules = ["shellcheck", "settings-sort", "md-shape", "gofmt", "json-fmt"]
```

---

## 12. Fixtures and the fixture-driven rule test (`rules_test.go` + `lint/testdata/`)

### 12.1 Fixture trees

For each of the five rules create `lint/testdata/<rule>/{ok,bad,fixed}/` containing at least one file each:

- `ok/` — a file the rule's `check` must pass.
- `bad/` — a file the rule's `check` must fail (with a nonempty message).
- `fixed/` — the expected result of running `fix` on the corresponding `bad/` file.

Concretely:
- `shellcheck`: `ok/script.sh` (clean), `bad/script.sh` (a shellcheck violation, e.g. unquoted `$var`), `fixed/` — shellcheck is check-only, so `fixed/` mirrors `bad/` (mark this rule check-only in the test; see 12.2).
- `settings-sort`: `ok/settings.json` with sorted `.permissions.allow`, `bad/settings.json` unsorted, `fixed/settings.json` sorted.
- `md-shape`: `ok/doc.md` correct shape, `bad/doc.md` wrong shape, `fixed/doc.md` fixed.
- `gofmt`: `ok/clean.go` gofmt-clean, `bad/dirty.go` not gofmt'd, `fixed/dirty.go` gofmt'd.
- `json-fmt`: `ok/data.json` key-sorted, `bad/data.json` unsorted, `fixed/data.json` sorted.

### 12.2 The test (`rules_test.go`)

Write a table/loop test that, for every manifest in `lint/rules.d/`:
1. **ok:** runs `check` on each file in `ok/`; asserts `passed == true`.
2. **bad:** runs `check` on each file in `bad/`; asserts `passed == false` **and** the message is nonempty.
3. **fix→fixed:** for rules with a `Fix`, copies the `bad/` file to a temp dir, runs `fix`, and asserts the bytes equal the corresponding `fixed/` file. For check-only rules (`Fix == ""`), skip the fix assertion but assert `Fix == ""` is intentional.
4. The test must not be skipped at runtime for any rule whose underlying tool is available; the definition-of-done requires `go test ./...` green with **no skipped tests**, so ensure the tools (`shellcheck`, `json-sort`, `md-shape`, `gofmt`) are available in the test environment, or wrap each rule's external command behind a fake that the test can drive deterministically. Choose one approach and apply it to all five rules consistently.

---

## 13. `install.sh`

```sh
#!/usr/bin/env sh
set -eu
go build -o bin/lint ./cmd/lint
```

Make it executable (`chmod +x install.sh`). The binary lands at `bin/lint` and is git-ignored.

---

## 14. Per-component test obligations (the remaining `_test.go` files)

Write each test below. No test may be `t.Skip`ped in a green run.

### `manifest_test.go`
- Loading each of the five manifests succeeds; asserts `Name`, `IO` default (`json-fmt`/`shellcheck` get `"path"`), `Check` present, `Fix` present/absent as specified.
- A manifest missing `name` or `check` returns an error.
- `manifestHash` changes when manifest bytes change (load two variants).

### `classifier_test.go`
- Extension classification for `.sh`, `.go`, `.json`, `.md`, and no-extension files.
- Shebang sniffing: `#!/bin/sh`→`sh`, `#!/bin/bash`→`bash`, `#!/usr/bin/env bash`→`bash` (env-style), `#!/bin/zsh`→`zsh`.
- **The zsh false positive:** a `#!/bin/zsh` file must NOT match `shellcheck`'s `sh`/`bash` shebang selector.
- A file with **no shebang** yields `Shebang == ""` and matches by extension only.

### `selector_test.go` (selection engine)
- Given the five-manifest set and a fixed file list, assert the exact `(rule, file)` pairs produced.
- Assert `json-fmt` does **not** select `settings.json`/`settings.local.json` (exclusion), while `settings-sort` does.
- Assert a `.go` file pairs only with `gofmt`, a `.md` only with `md-shape`, etc.

### `config_test.go`
- Base `lint.toml` lists rules A,B,C; a nested directory `sub/lint.toml` lists D only. Assert a file under `sub/` resolves active rules to `[D]` (nearest-wins) and a file at root resolves to `[A,B,C]`.
- A rule absent from a file's resolved active set produces no `(rule,file)` pair (cross-check with `SelectPairs`).

### `scheduler_test.go`
- Run the same pair set with `jobs=1` and `jobs=8`; assert the returned `[]Result` slices are **identical and identically ordered** (sorted by `(Path, Rule)`).
- Use enough distinct `(path, rule)` pairs that an unsorted result would reorder with high probability.

### `cache_test.go`
- **Cold key:** `Get` returns false, the check runs.
- **Warm key:** after `Put`, `Get` returns true and the scheduler skips the tool (verify via a counter on the fake command runner).
- **Content change invalidates:** changing the file content changes `contentHash`, so `Get` returns false and the check re-runs — assert **no stale pass** is served.
- **Rule identity in key:** two rules with the same content but different `Name`/`manifestHash` produce different keys (no collision).

---

## 15. Definition of done (self-check)

Tick every box.

- [ ] `./install.sh` produces `bin/lint`; `bin/` is git-ignored and the binary is uncommitted.
- [ ] `lint check PATHS…` reports violations and exits `1` on any failure, `0` otherwise.
- [ ] `lint fix PATHS…` mutates the working tree via each rule's fixer; check-only rules are left untouched.
- [ ] `lint --staged` lints **staged blob content** (materialized via `git show :FILE`; stdin rules get the blob on stdin), blocks (nonzero) on violation, and never auto-mutates.
- [ ] `lint --changed [REF]` lints files changed against `REF` (default `HEAD`).
- [ ] `lint --from-hook --warn` reads PostToolUse JSON on stdin, extracts `tool_input.file_path`, and **always exits 0** while printing reminders.
- [ ] Five manifests exist in `lint/rules.d/`; adding a rule is dropping a manifest, with zero orchestrator edits.
- [ ] The scheduler runs `(rule,file)` checks concurrently across a `--jobs N` pool (default `NumCPU`) and emits results sorted by `(path, rule)`; `--jobs 1` and `--jobs N` output is byte-identical.
- [ ] The cache skips unchanged `(rule,file)` pairs, invalidates on any content change (no stale pass), and keys on content hash **plus** rule identity (name + manifest hash); lives under `--cache-dir` (default XDG cache).
- [ ] Config resolves nearest-wins per file: nearest `lint.toml` sets active rules, unspecified keys inherit from the parent, and a rule absent from the resolved set does not execute.
- [ ] Each of the five rules: `check` passes on `ok/`, fails on `bad/` with a message, and `fix` turns `bad/` into `fixed/` (where a fixer exists).
- [ ] `go test ./...` is green across classifier, selection engine, scheduler, cache, config inheritance, and all five rules' fixtures, **with no skipped tests**.