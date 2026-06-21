# WORK ORDER (REFINED): `lint+` Pluggable Linting Engine

You are implementing a Go CLI named `lint`. Follow every task literally. Make no design decisions beyond what is written here. When a task says "exact," reproduce it byte-for-byte.

This refinement closes gaps in the draft that would let a literal implementer produce a wrong, untestable, or environment-dependent result. The most consequential corrections are flagged inline as **[FIX]**, **[GAP]**, **[CONTRACT]**, **[ASSUMPTION]**, or **[OPTIONAL / skip-in-isolation]**.

---

## 0. Prerequisites and module setup

1. Confirm there is a Go module rooted at the repo root. If `go.mod` does not exist, run `go mod init lint` (module path `lint`). Set the Go directive to `go 1.21` or later.
2. Add the only third-party dependency: `github.com/BurntSushi/toml`. Run `go get github.com/BurntSushi/toml`.
3. Add `/bin/` to `.gitignore` if not already present. The built binary at `bin/lint` is **never committed**.
4. Go standard-library packages you will use: `crypto/sha256`, `encoding/hex`, `encoding/json`, `os`, `os/exec`, `path/filepath`, `sort`, `strings`, `bufio`, `sync`, `runtime`, `flag`, `fmt`, `io`, `errors`.

**[OPTIONAL / skip-in-isolation]** Tasks in this order that require a surrounding git repository (`--staged`, `--changed` end-to-end) or non-Go external tools (`shellcheck`, `json-sort`, `md-shape`) cannot be exercised end-to-end in a bare checkout. Every such task is marked. None of the *engine's own* unit tests may depend on them — see the injectable seams in §2.5 and the test tiering in §12 and §14. Their absence in isolation is **not** a defect.

---

## 1. Final file and directory layout

Create exactly these files. Every `.go` file is `package main` in directory `cmd/lint/`.

```
install.sh                              # build script (task 13)
go.mod / go.sum                         # module + deps
lint.toml                               # base repo-local config (task 11)
cmd/lint/main.go                        # entry point, arg parsing, verb dispatch (task 10)
cmd/lint/manifest.go                    # Rule + Selector types, manifest loading (task 3)
cmd/lint/classifier.go                  # file-type classification (task 5)
cmd/lint/selector.go                    # selector matching + selection engine (task 6)
cmd/lint/config.go                      # layered config discovery + resolution (task 7)
cmd/lint/scheduler.go                   # bounded worker pool + deterministic emit (task 8)
cmd/lint/cache.go                       # content-addressed cache (task 9)
cmd/lint/adapters.go                    # the four input adapters (task 4)
cmd/lint/exec.go                        # command + git runner seams (task 2.5)  [GAP: added]
cmd/lint/engine.go                      # orchestrator: wires everything, runs a verb (task 10)
cmd/lint/manifest_test.go
cmd/lint/classifier_test.go
cmd/lint/selector_test.go
cmd/lint/config_test.go
cmd/lint/scheduler_test.go
cmd/lint/cache_test.go
cmd/lint/adapters_test.go               # [GAP: added — adapters had zero coverage]
cmd/lint/engine_test.go                 # [GAP: added — end-to-end with fake rules]
cmd/lint/rules_test.go                  # fixture-driven, iterates all rules (task 12)
lint/rules.d/shellcheck.toml            # task 3.5
lint/rules.d/settings-sort.toml
lint/rules.d/md-shape.toml
lint/rules.d/gofmt.toml
lint/rules.d/json-fmt.toml
lint/testdata/<rule>/{ok,bad,fixed}/    # five rule fixture trees (task 12)
lint/testdata/_stubs/                   # [GAP: added — deterministic tool stubs (task 12.3)]
```

Splitting `.go` source across more files is allowed only if every symbol named below keeps the exact name and signature given.

---

## 2. Core data types (put in `manifest.go` unless noted)

Define these types verbatim.

```go
type Selector struct {
	Extensions []string         `toml:"extensions"`
	Shebangs   []string         `toml:"shebangs"`
	Paths      []string         `toml:"paths"`
	Globs      []string         `toml:"globs"`
	Exclude    *ExcludeSelector `toml:"exclude"`
}

type ExcludeSelector struct {
	Paths []string `toml:"paths"`
	Globs []string `toml:"globs"`
}

type Rule struct {
	Name   string   `toml:"name"`
	Select Selector `toml:"select"`
	IO     string   `toml:"io"`
	Check  string   `toml:"check"`
	Fix    string   `toml:"fix"`

	manifestPath string
	manifestHash string
}

type Result struct {
	Path    string
	Rule    string
	Passed  bool
	Mutated bool   // [GAP] fix mode: true when the fixer changed bytes
	Message string // rule stdout when Passed == false
}
```

- `IO` defaults to `"path"` when the manifest omits the `io` key. After decode, if `r.IO == ""` set it to `"path"`. Legal values are only `"path"` and `"stdin"`; any other value is a load error.

### 2.5 Command and git seams (`exec.go`) — **[GAP: this did not exist in the draft and is mandatory]**

Every external invocation goes through an injectable function variable so tests run with **no real tools and no git**.

```go
// commandRunner runs a shell command. Overridable in tests.
// Returns the process exit code, combined stdout, and an error ONLY when the
// process failed to LAUNCH (e.g. binary missing) — never for a nonzero exit.
var commandRunner = func(shellCmd string, stdin io.Reader) (exitCode int, stdout string, err error) { ... }

// gitRunner runs a git subcommand and returns stdout. Overridable in tests.
var gitRunner = func(args ...string) (stdout string, err error) { ... }
```

- `commandRunner` executes `exec.Command("sh", "-c", shellCmd)`, wires `stdin` when non-nil, captures stdout (and stderr folded into the returned string), and maps a launch failure (`exec.ErrNotFound`/`exec.Error`) to a non-nil `err`. A process that runs and exits nonzero returns `(code>0, output, nil)`.
- All scheduler command execution (§8.3) calls `commandRunner`. All adapters (§4) call `gitRunner`. **No other file may call `exec.Command` directly.** This single rule is what makes §8, §9, §4 unit-testable in isolation.

---

## 3. Manifest loading (`manifest.go`)

### 3.1 Functions

```go
func LoadRule(path string) (Rule, error)
func LoadRules(dir string) ([]Rule, error)
```

### 3.2 Tasks

1. `LoadRule` reads the file bytes once. Compute `manifestHash = hex(sha256(bytes))`. Decode the same bytes with `toml.Decode`. Set `manifestPath = path`.
2. Validate after decode: `Name` non-empty; apply the `""→"path"` default then require `IO ∈ {"path","stdin"}`; `Check` non-empty. On failure return an error naming the file and the problem.
3. `LoadRules` lists `*.toml` in `dir`, sorts filenames ascending, loads each, returns the slice in that order. Any load error aborts.
4. Rules are **policy-free**: nothing here reads or stores warn/block behavior.

### 3.3 Tool-interface contract — **[CONTRACT] read this before writing manifests**

The SPEC states each rule's `check` "exits nonzero on a violation and prints a human message plus a copy-pasteable fix command to stdout." **Raw upstream tools do not all satisfy this**, so the `check` string in each manifest is a **shell wrapper**, not a bare tool call. Two concrete traps the draft got wrong:

- **`gofmt -l` exits 0 even when a file is unformatted** — it only *prints* the filename. A bare `gofmt -l {file}` would mark every bad file as PASS. **[FIX]** The wrapper must convert nonempty output into a nonzero exit.
- Bare `shellcheck` prints diagnostics but no "copy-pasteable fix command." The wrapper appends the fix hint.

**[ASSUMPTION] `json-sort` and `md-shape` CLI surface.** The SPEC names `json-sort` (sort JSON keys / a JSON path) and the `mdsplit | mdtable` shape but pins no flags. This order assumes the following interface; if the real tools differ, the implementer must adjust the wrapper strings **only**, leaving every Go symbol unchanged:
- `json-sort [--path P] {file}` writes canonical (key-sorted, or sorted-array-at-`P`) JSON to **stdout**; it does **not** mutate. The wrapper diffs stdout against the file for `check` and writes-back for `fix`.
- `md-shape` does not exist as a binary; the shape is `mdsplit {file} | mdtable -w` producing canonical Markdown on stdout. The wrapper diffs for `check` and writes-back for `fix`. **[FIX: the draft invented an `md-shape` binary.]**

### 3.4 The five manifests (`lint/rules.d/`)

Write these exact files. Each `check`/`fix` is a self-contained `sh -c` payload that **exits nonzero on violation and prints a fix line**.

`shellcheck.toml`
```toml
name = "shellcheck"
select.extensions = ["sh", "bash"]
select.shebangs   = ["sh", "bash"]
io    = "path"
check = "shellcheck {file} || { echo 'fix: shellcheck {file}  # review and apply suggested edits'; exit 1; }"
# no fix key: shellcheck is check-only
```

`settings-sort.toml`
```toml
name = "settings-sort"
select.globs = ["**/settings.json", "**/settings.local.json", "claude/settings.json"]
io    = "path"
check = "json-sort --path .permissions.allow {file} | diff -q - {file} >/dev/null || { echo 'fix: json-sort --path .permissions.allow {file} > {file}.tmp && mv {file}.tmp {file}'; exit 1; }"
fix   = "json-sort --path .permissions.allow {file} > {file}.tmp && mv {file}.tmp {file}"
```

`md-shape.toml`
```toml
name = "md-shape"
select.extensions = ["md", "markdown"]
io    = "path"
check = "mdsplit {file} | mdtable -w | diff -q - {file} >/dev/null || { echo 'fix: mdsplit {file} | mdtable -w > {file}.tmp && mv {file}.tmp {file}'; exit 1; }"
fix   = "mdsplit {file} | mdtable -w > {file}.tmp && mv {file}.tmp {file}"
```

`gofmt.toml`
```toml
name = "gofmt"
select.extensions = ["go"]
io    = "path"
check = "out=$(gofmt -l {file}); [ -z \"$out\" ] || { echo 'fix: gofmt -w {file}'; exit 1; }"
fix   = "gofmt -w {file}"
```

`json-fmt.toml`
```toml
name = "json-fmt"
select.extensions = ["json"]
select.exclude.globs = ["**/settings.json", "**/settings.local.json", "claude/settings.json"]
io    = "path"
check = "json-sort {file} | diff -q - {file} >/dev/null || { echo 'fix: json-sort {file} > {file}.tmp && mv {file}.tmp {file}'; exit 1; }"
fix   = "json-sort {file} > {file}.tmp && mv {file}.tmp {file}"
```

> The `json-fmt` `exclude` block restates the SPEC's "`.json` not already owned by `settings-sort`" as a literal exclusion using the same patterns `settings-sort` selects.

---

## 4. Input adapters (`adapters.go`)

```go
type FileSource struct{ Files []SourceFile }

type SourceFile struct {
	Path        string // logical path: selection, sorting, {file} default, config resolution
	ContentPath string // filesystem path to read/pass as {file}; == Path for working-tree adapters
	cleanup     func()
}
```

Implement four constructors, each returning `(FileSource, error)`. All git calls go through `gitRunner` (§2.5).

1. `sourceFromArgs(paths []string)` — for `lint check/fix PATHS…`. For each arg: if a directory, walk recursively and add every **regular** file, **skipping `.git/` and `bin/`** **[GAP: the draft would lint `.git` objects and the built binary]**; if a file, add it. `Path == ContentPath == the path`.
2. `sourceStaged()` **[OPTIONAL / skip-in-isolation: requires git]** — `gitRunner("diff","--cached","--name-only","--diff-filter=ACM")`. For each staged path, materialize the staged blob via `gitRunner("show",":"+path)` and write its bytes to a temp file under one `os.MkdirTemp` dir. Set `Path = staged path`, `ContentPath = temp file`, `cleanup` removing it. **Staged content is linted, never the working tree.** For `io="stdin"` rules the blob is piped on stdin (§8.3); the temp file still backs `{file}` for `io="path"` rules.
3. `sourceChanged(ref string)` **[OPTIONAL / skip-in-isolation: requires git]** — if `ref == ""` default to `"HEAD"`. `gitRunner("diff","--name-only","--diff-filter=ACM",ref)`. `Path == ContentPath == working-tree path`.
4. `sourceFromHook(stdin io.Reader)` — decode PostToolUse JSON, extract `.tool_input.file_path`. Return a one-file source with `Path == ContentPath == that path`. If absent/empty, return an empty `FileSource`, **no error** (nothing to lint).

```go
type hookPayload struct {
	ToolInput struct {
		FilePath string `json:"file_path"`
	} `json:"tool_input"`
}
```

5. `func (s FileSource) Close()` calls every non-nil `cleanup`.

---

## 5. Classifier (`classifier.go`)

```go
type FileClass struct {
	Ext     string
	Shebang string
}
func Classify(logicalPath, contentPath string) (FileClass, error)
func sniffShebang(firstLine string) string
```

### Tasks

1. `Ext`: `strings.ToLower(strings.TrimPrefix(filepath.Ext(logicalPath), "."))`.
2. `sniffShebang`: line must start with `#!`. Strip `#!`, trim spaces, split on whitespace.
   - If the first token's basename is `env`, the interpreter is the **next** token: `#!/usr/bin/env bash` → `bash`.
   - Otherwise the interpreter is `filepath.Base(firstToken)`: `#!/bin/sh` → `sh`, `#!/bin/zsh` → `zsh`.
   - Do not parse flags; only the `env` indirection is special.
3. No `#!` first line ⇒ `Shebang == ""`.
4. `Classify` opens `contentPath`, reads the first line with `bufio.Scanner`, calls `sniffShebang`. **[FIX] Read errors propagate only for non-empty files; a missing/empty/zero-byte file yields `Shebang == ""` with a nil error** so directory walks over assorted files don't abort selection.

---

## 6. Selector matching + selection engine (`selector.go`)

```go
func (r Rule) matches(fc FileClass, logicalPath string) bool

type Pair struct {
	Rule Rule
	File SourceFile
}

func SelectPairs(rules []Rule, src FileSource, cfg *ConfigResolver) ([]Pair, error)
```

### `globMatch` — **[FIX: the draft's "match basename and full path, collapse `**`" was ambiguous and buggy]**

```go
func globMatch(pattern, path string) bool
```

Precise semantics:
1. If `pattern` contains no `/` and no `**`: match `filepath.Match(pattern, filepath.Base(path))`.
2. If `pattern` has the form `**/TAIL` (one leading `**/`): match if `filepath.Match(TAIL, filepath.Base(path))` is true **OR** `filepath.Match(TAIL, path)` is true. This makes `**/settings.json` match `settings.json` at depth 0 **and** `claude/settings.json` at any depth.
3. Otherwise: `filepath.Match(pattern, path)`.
4. A `filepath.Match` error is treated as "no match" (never panics, never matches).

### `matches` (a rule matches iff **any** positive selector hits AND no exclude hits)

1. **Exclude first:** if `Select.Exclude != nil` and the file matches any `Exclude.Paths` (exact `logicalPath` or basename equality) or any `Exclude.Globs` (via `globMatch`), return `false`.
2. Extension: `fc.Ext` ∈ `Select.Extensions`.
3. Shebang: `fc.Shebang != "" && fc.Shebang` ∈ `Select.Shebangs`.
4. Path: `logicalPath` equals an entry in `Select.Paths`, or `filepath.Base(logicalPath)` equals one.
5. Glob: any `Select.Globs` matches via `globMatch`.
6. Return `(2 ‖ 3 ‖ 4 ‖ 5) && !excluded`.

### `SelectPairs`

1. For each `SourceFile`, call `Classify(file.Path, file.ContentPath)`. **[GAP]** classify on `ContentPath` (the staged temp blob for `--staged`) so shebang sniffing sees staged content, but match on `file.Path` (the logical path) so extension/glob/config use the real location.
2. Resolve the file's **active rule set** via `cfg.ActiveRulesFor(file.Path)` (§7). A rule whose `Name` is not in the resolved active set **does not execute** for that file.
3. For each active rule that `matches`, emit a `Pair`.
4. Build pairs in `(file, rule)` input order (the scheduler sorts on emit; this is only for reproducibility of intermediate state).

---

## 7. Layered config (`config.go`)

### File format (`lint.toml`)

```toml
rules = ["shellcheck", "gofmt", "json-fmt"]
```

### Types + functions

```go
type ConfigLayer struct {
	Dir      string
	Rules    []string
	hasRules bool
}

type ConfigResolver struct {
	baseDir string
	layers  map[string]ConfigLayer // absolute dir -> layer
}

func NewConfigResolver(baseDir string) (*ConfigResolver, error)
func (c *ConfigResolver) ActiveRulesFor(path string) []string
```

### Tasks

1. `baseDir` is the absolute repo root (the engine's working directory). Store it absolute.
2. Discovery: `filepath.WalkDir(baseDir, …)` collecting every `lint.toml`, **skipping `.git/` and `bin/`**. Key each `ConfigLayer` by its **absolute** directory. Record `hasRules` = whether the `rules` key was present (so `rules = []` is distinguishable from omission). **[GAP: the draft never said discovery skips `.git`/`bin`, nor that keys are absolute.]**
3. `ActiveRulesFor(path)`:
   - Compute the file's absolute directory: if `path` is relative, join with `baseDir`; then `filepath.Dir`.
   - Walk parent directories from that dir **up to and including `baseDir`**.
   - The **nearest** dir whose layer has `hasRules == true` wins; return its `Rules`.
   - If no layer on the chain declares `rules`, return the base layer's `Rules` if present, else an empty slice.
   - **[FIX] A path that resolves outside `baseDir`** (e.g. an absolute temp path that is not under the repo) cannot reach `baseDir` by walking up. In that case return the base layer's `Rules`. Note `SelectPairs` always resolves on `file.Path` (logical, repo-relative) per §6.1, so staged temp paths never reach this branch in practice; this rule only guards stray inputs.
4. **Nearest-wins** is pinned: the nearest `lint.toml` to a file sets its active rules; unspecified keys inherit from the parent layer.

---

## 8. Scheduler (`scheduler.go`)

```go
func RunPairs(pairs []Pair, jobs int, mode Mode, cache *Cache) ([]Result, error)

type Mode int
const (
	ModeCheck Mode = iota
	ModeFix
)
```

### Tasks

1. If `jobs <= 0`, set `jobs = runtime.NumCPU()`.
2. **[GAP] Safe collection:** feed pairs on an input channel; each worker pushes `Result` on an output channel (or appends under a `sync.Mutex`). Use `sync.WaitGroup` to know when to close the output channel. No shared slice is appended without synchronization.
3. Per pair, the worker first computes `contentHash, err := hashContent(pair.File.ContentPath)` (§9). A hash error is a launch-class error: stop and return it from `RunPairs`.
4. **Check mode:**
   - Consult cache: `if cache != nil && cache.Get(pair.Rule, contentHash)` → emit `Result{Passed:true}` **without** calling `commandRunner`.
   - On miss: run the check (§8.3). On a pass, `cache.Put(pair.Rule, contentHash)`. On a tool **launch** error, return it from `RunPairs` (do not silently pass). On a clean run, set `Passed` from the exit code and `Message` from stdout when failed.
5. **Fix mode:**
   - If `pair.Rule.Fix != ""`: run the fix command (§8.3). After it returns, recompute the content hash; set `Result.Mutated = (newHash != contentHash)`. **Fix never writes cache pass entries.**
   - If the rule is check-only (`Fix == ""`): run the check instead and report it; never error merely because no fixer exists.
6. After all workers finish, **sort results** with `sort.Slice` by `(Path, Rule)` ascending — mandatory, regardless of `jobs`. **Concurrency must never be observable:** `--jobs 1` and `--jobs N` output must be byte-identical. Nondeterministic ordering is a correctness bug, not a speed trade.

### 8.3 Command execution

```go
func runCommand(template string, file SourceFile, ioMode string) (passed bool, output string, err error)
```

1. Expand **every** occurrence of `{file}` in `template` with `file.ContentPath` (use `strings.ReplaceAll`). **[FIX: the wrappers in §3.4 contain multiple `{file}`s.]**
2. **stdin rules** (`ioMode == "stdin"`): pass file content on stdin — for staged sources the blob lives at `ContentPath`; open `ContentPath` and pass the reader to `commandRunner`. For `"path"` rules pass `nil` stdin. Note `{file}` is still expanded in both modes (harmless for stdin rules that ignore it).
3. Call `commandRunner(expanded, stdinReader)`.
4. **Check semantics:** exit code 0 ⇒ `passed = true`; nonzero ⇒ `passed = false`, `output` = the command's combined stdout (the human message + copy-pasteable fix line). **[FIX] Pass/fail is driven by the wrapper's exit code, which §3.4 guarantees is correct even for `gofmt`.**
5. A tool that failed to **launch** (binary missing) returns via `err`; a tool that ran and reported a violation returns `(false, output, nil)`.

---

## 9. Cache (`cache.go`)

```go
type Cache struct{ dir string }

func NewCache(dir string) (*Cache, error)
func (c *Cache) key(rule Rule, contentHash string) string
func hashContent(path string) (string, error) // hex(sha256(file bytes))
func (c *Cache) Get(rule Rule, contentHash string) (hit bool)
func (c *Cache) Put(rule Rule, contentHash string) error
```

### Tasks

1. `NewCache("")` ⇒ `dir = filepath.Join(base, "lint")` where `base, _ = os.UserCacheDir()` (XDG cache). `os.MkdirAll(dir, 0o755)`.
2. `key` = `hex(sha256( contentHash + "\x00" + rule.Name + "\x00" + rule.manifestHash ))`. The key **must include rule identity** so two rules over identical content never collide and a manifest edit invalidates.
3. An entry is a file named by the key under `dir`; its existence means "this `(content, rule)` passed."
4. `Get` returns true only when the entry exists for the exact key. Any content change ⇒ different `contentHash` ⇒ different key ⇒ **miss** ⇒ re-run. No expiry, no path keying. A stale pass would corrupt the gate; do not implement TTLs or path keys.
5. Only **passing** checks are cached. Failures are never cached. `Put` is idempotent (writing an existing key is fine).

---

## 10. Orchestrator + entry point (`engine.go`, `main.go`)

### 10.1 Argument parsing (`main.go`) — **[FIX: the draft mixed verbs and flags without specifying how `flag` resolves them; Go's `flag` stops at the first non-flag token.]**

Parse `os.Args[1:]` with this explicit, ordered algorithm:

1. Scan for an optional leading **verb**: if `args[0]` is `check` or `fix`, record it and consume it. Otherwise verb is empty.
2. Define a `flag.FlagSet` with: `--staged` (bool), `--changed` (bool), `--changed-ref` (string, default `"HEAD"`) **[GAP: `--changed [REF]` is not expressible as one `flag`; REF is supplied via `--changed-ref` or, if absent, defaults to `HEAD`]**, `--from-hook` (bool), `--warn` (bool), `--jobs` (int, default `runtime.NumCPU()`), `--cache-dir` (string, default `""` → XDG), `--rules-dir` (string, default `"lint/rules.d"`).
3. Parse the FlagSet over the post-verb args. Remaining positionals are `PATHS…`.
4. Validate: exactly one *source* must be determined — a verb (`check`/`fix` ⇒ args source) **xor** exactly one of `--staged`/`--changed`/`--from-hook`. More than one source, or a verb combined with a source flag, is a usage error (exit `2`).
5. `--warn` is orthogonal and may combine with any **check** source; it is ignored with `fix` (fix never blocks anyway).

### Dispatch table

| Invocation | Source adapter | Mode | Policy |
|---|---|---|---|
| `lint check PATHS…` | `sourceFromArgs` | check | report (exit 1 on violation) |
| `lint fix PATHS…` | `sourceFromArgs` | fix | mutate working tree |
| `lint --staged` | `sourceStaged` | check | block (exit 1 on violation) |
| `lint --changed [--changed-ref REF]` | `sourceChanged` | check | report |
| `lint --from-hook` | `sourceFromHook(os.Stdin)` | check | report unless `--warn` |
| `lint --from-hook --warn` | `sourceFromHook` | check | warn only (exit 0) |

### 10.2 Engine flow (`engine.go`)

```go
type Options struct {
	Verb      string // "check" | "fix" | ""
	Source    string // "args" | "staged" | "changed" | "hook"
	Paths     []string
	ChangedRef string
	Warn      bool
	Jobs      int
	CacheDir  string
	RulesDir  string
}
func Run(opts Options) (exitCode int, err error)
```

1. Build `ConfigResolver` rooted at the working directory.
2. `LoadRules(opts.RulesDir)`.
3. Build the `FileSource` from the chosen adapter; `defer src.Close()`.
4. `SelectPairs(rules, src, cfg)`.
5. `NewCache(opts.CacheDir)`.
6. `mode` = `ModeFix` if `opts.Verb == "fix"` else `ModeCheck`. `RunPairs(pairs, opts.Jobs, mode, cache)`.
7. Print results (§10.3).
8. Return exit code (§10.4). Any internal `error` returned by a step maps to `(2, err)`.

### 10.3 Output

- Failing `Result` (already sorted by `(Path, Rule)`): print a block of the exact form
  ```
  <Path> [<Rule>]
  <Message>
  ```
  (Message is the rule's stdout — the human message + copy-pasteable fix line.)
- Passing results in check mode print **nothing** (no summary line) so stdout is purely the failure set and deterministic. **[FIX: "nothing OR a summary count" left the contract ambiguous — pick nothing.]**
- Fix mode: for each `Result` with `Mutated == true`, print exactly `fixed: <Path> [<Rule>]`. Print nothing for unchanged files. No cache/timing/worker output ever.

### 10.4 Exit codes (pinned)

1. Check, no `--warn`: `0` if zero failing results, else `1`. The pre-commit hook (`--staged`) blocks on `1`.
2. `--warn`: **always `0`**, printing reminders for any failures.
3. Fix: `0` on success; nonzero (`1`) only if a **fixer command itself failed to run** (launch error or nonzero exit from the fix payload). A file that simply had nothing to fix is success.
4. Internal/usage error: `2`.
5. **Fix is working-tree only.** The `--staged` path never auto-mutates — it blocks and prints. Do not call fixers from the staged path.

---

## 11. Base config (`lint.toml`)

```toml
rules = ["shellcheck", "settings-sort", "md-shape", "gofmt", "json-fmt"]
```

---

## 12. Fixtures and the fixture-driven rule test

### 12.1 Fixture trees

For each rule create `lint/testdata/<rule>/{ok,bad,fixed}/` with at least one file each:

- `shellcheck`: `ok/script.sh` (clean, e.g. quoted vars), `bad/script.sh` (e.g. unquoted `$var`). Check-only ⇒ **no `fixed/` assertion**; the test asserts `Fix == ""` for this rule.
- `settings-sort`: `ok/settings.json` sorted `.permissions.allow`, `bad/settings.json` unsorted, `fixed/settings.json` sorted.
- `md-shape`: `ok/doc.md` canonical shape, `bad/doc.md` non-canonical, `fixed/doc.md` canonical.
- `gofmt`: `ok/clean.go` gofmt-clean, `bad/dirty.go` not formatted, `fixed/dirty.go` gofmt'd.
- `json-fmt`: `ok/data.json` key-sorted, `bad/data.json` unsorted, `fixed/data.json` sorted.

### 12.2 The test (`rules_test.go`)

For every manifest in `lint/rules.d/`:
1. **ok:** run `check` on each `ok/` file; assert `passed == true`.
2. **bad:** run `check` on each `bad/` file; assert `passed == false` **and** `Message` nonempty.
3. **fix→fixed:** for rules with `Fix != ""`, copy the `bad/` file to a temp dir, run `fix`, assert resulting bytes equal the matching `fixed/` file. For check-only rules assert `Fix == ""`.

### 12.3 Tool availability — **[FIX: the draft punted this decision ("choose one approach") to a junior who exercises no judgment; this order decides.]**

The rule wrappers call `gofmt` (ships with the Go toolchain), `shellcheck`, `json-sort`, `mdsplit`/`mdtable` — the last three are **not present in a clean checkout**. Resolution, applied uniformly:

1. **gofmt is mandatory** (guaranteed by the toolchain): its `rules_test.go` cases never skip.
2. For `shellcheck`, `json-sort`, `mdsplit`, `mdtable`: at the start of `rules_test.go`, detect each with `exec.LookPath`.
   - **Default (isolation) mode:** if a tool is absent, **prepend `lint/testdata/_stubs/` to `PATH`** for the test process. `_stubs/` contains deterministic shell stubs (`shellcheck`, `json-sort`, `mdsplit`, `mdtable`) that emulate exactly the pass/fail behavior the fixtures need — e.g. `json-sort` sorts keys/array with `jq`-free pure-shell or a tiny embedded sorter, `shellcheck` exits nonzero iff the input contains the fixture's marker pattern. This keeps the rule tests **running, deterministic, and unskipped in a bare checkout**.
   - **[OPTIONAL] integration mode:** when the real tools are on `PATH` and env `LINT_TEST_REAL_TOOLS=1` is set, run against the real binaries instead of stubs.
3. Net effect on the Done criteria: **no `t.Skip` anywhere.** The previously irreconcilable "no skipped tests" vs. "tools may be absent" tension is closed by the stub PATH, not by skipping. Write the stubs as part of this task; they are fixtures, committed.

---

## 13. `install.sh`

```sh
#!/usr/bin/env sh
set -eu
go build -o bin/lint ./cmd/lint
```

`chmod +x install.sh`. Binary lands at `bin/lint`, git-ignored, uncommitted.

---

## 14. Per-component test obligations

No test may be `t.Skip`ped in a green run (see §12.3 for how external-tool rules avoid skips via stubs). Every test that drives the engine uses the §2.5 seams (`commandRunner`, `gitRunner`) with fakes — **no real tools, no git** in these files.

### `manifest_test.go`
- Loading each of the five manifests succeeds; assert `Name`, `IO` default (`json-fmt`/`shellcheck`/`md-shape`/`gofmt` get `"path"`), `Check` present, `Fix` present/absent as specified (`shellcheck` ⇒ `Fix == ""`).
- A manifest missing `name`, missing `check`, or with `io = "weird"` returns an error.
- `manifestHash` differs for two manifests whose bytes differ.

### `classifier_test.go`
- Extensions for `.sh`, `.go`, `.json`, `.md`, and no-extension files.
- Shebangs: `#!/bin/sh`→`sh`, `#!/bin/bash`→`bash`, `#!/usr/bin/env bash`→`bash`, `#!/bin/zsh`→`zsh`.
- **zsh false positive:** a `#!/bin/zsh` file must NOT match `shellcheck`'s `sh`/`bash` shebang selector.
- A file with **no shebang** ⇒ `Shebang == ""`, matched by extension only.
- An empty/zero-byte file ⇒ `Shebang == ""`, nil error.

### `selector_test.go`
- Given the five-manifest set and a fixed file list, assert the exact `(rule, file)` pairs.
- Assert `json-fmt` does **not** select `settings.json`/`settings.local.json` (exclusion), while `settings-sort` does — at both depth 0 (`settings.json`) and a nested path (`claude/settings.json`), exercising the `**/X` glob.
- Assert a `.go` file pairs only with `gofmt`, a `.md` only with `md-shape`.
- **[GAP] `globMatch` unit cases:** `**/settings.json` matches `settings.json` and `a/b/settings.json`; `claude/settings.json` matches only that exact path; a malformed pattern never panics.

### `config_test.go`
- Base `lint.toml` = `[A,B,C]`; `sub/lint.toml` = `[D]`. A file under `sub/` resolves to `[D]` (nearest-wins); a root file resolves to `[A,B,C]`.
- An empty `rules = []` in a nearer layer **wins** (resolves to `[]`), proving `hasRules` distinguishes empty from omitted.
- Cross-check with `SelectPairs`: a rule absent from the resolved set produces no pair.

### `scheduler_test.go`
- Run the same pair set with `jobs=1` and `jobs=8`; assert returned `[]Result` slices are **identical and identically ordered**.
- Use enough distinct `(path, rule)` pairs that an unsorted result would reorder with high probability.
- Drive checks through a fake `commandRunner` (deterministic pass/fail by path), not real tools.

### `cache_test.go`
- **Cold key:** `Get` false; check runs (fake-runner counter increments).
- **Warm key:** after `Put`, `Get` true and the scheduler **skips** the runner (counter unchanged).
- **Content change invalidates:** changing content changes `contentHash` ⇒ `Get` false ⇒ re-run; assert **no stale pass**.
- **Rule identity in key:** same content, different `Name`/`manifestHash` ⇒ different keys (no collision).

### `adapters_test.go` — **[GAP: adapters had zero coverage in the draft]**
- `sourceFromArgs`: a temp dir tree resolves to the expected file list, with `.git/` and `bin/` skipped; a single-file arg yields one entry.
- `sourceFromHook`: valid PostToolUse JSON yields one file at `tool_input.file_path`; missing/empty field yields an empty source and **no error**.
- `sourceStaged` / `sourceChanged`: inject a fake `gitRunner` returning canned `--name-only` and `show :PATH` output; assert the constructed `SourceFile`s (logical `Path` vs. temp `ContentPath`, default ref `HEAD`). These run in isolation because git is faked. **[OPTIONAL]** A real-git integration variant runs only when `LINT_TEST_REAL_GIT=1`.

### `engine_test.go` — **[GAP: no end-to-end coverage in the draft]**
- With fake rules (pure-shell `check`/`fix` needing no external tools) and `commandRunner` real-but-trivial, assert: `check` over a known tree returns exit `1` with the expected sorted failure blocks; `--warn` returns exit `0` with the same printed reminders; `fix` reports `fixed:` lines and mutates only the intended files; a usage error (verb + `--staged`) returns exit `2`.

---

## 15. Definition of done (self-check)

- [ ] `./install.sh` produces `bin/lint`; `bin/` is git-ignored and uncommitted.
- [ ] `lint check PATHS…` reports violations, exits `1` on any failure, `0` otherwise; output is the sorted `<Path> [<Rule>]` + message blocks only.
- [ ] `lint fix PATHS…` mutates the working tree via each rule's fixer, prints `fixed:` lines for changed files, leaves check-only rules untouched.
- [ ] `lint --staged` lints **staged blob content** (materialized via `git show :FILE`; stdin rules get the blob on stdin), blocks (exit `1`) on violation, never auto-mutates. **[OPTIONAL / skip-in-isolation: needs git.]**
- [ ] `lint --changed [--changed-ref REF]` lints files changed against `REF` (default `HEAD`). **[OPTIONAL / skip-in-isolation: needs git.]**
- [ ] `lint --from-hook --warn` reads PostToolUse JSON on stdin, extracts `tool_input.file_path`, **always exits 0** while printing reminders.
- [ ] Five manifests exist in `lint/rules.d/`; adding a rule is dropping a manifest, zero orchestrator edits. Each manifest's `check` genuinely exits nonzero on violation and prints a copy-pasteable fix line (verified for `gofmt`, whose `-l` exits 0 by default).
- [ ] The scheduler runs `(rule,file)` checks concurrently across a `--jobs N` pool (default `NumCPU`), emits results sorted by `(path, rule)`; `--jobs 1` and `--jobs N` output is byte-identical; all command/git I/O flows through the §2.5 seams.
- [ ] The cache skips unchanged `(rule,file)` pairs, invalidates on any content change (no stale pass), keys on content hash **plus** rule identity (name + manifest hash); lives under `--cache-dir` (default XDG).
- [ ] Config resolves nearest-wins per file (absolute keying, `.git`/`bin` skipped, empty-vs-omitted distinguished); a rule absent from the resolved set does not execute.
- [ ] Each rule's fixtures pass via §12.3 (gofmt against the real toolchain; the rest against committed deterministic stubs on a temp `PATH`).
- [ ] `go test ./...` is green across manifest, classifier, selector/globMatch, config, scheduler, cache, **adapters**, **engine**, and all five rules' fixtures, **with no skipped tests** — the only environment-gated paths (real git, real third-party tools) are covered by faked seams/stubs in isolation and run against the real thing only under `LINT_TEST_REAL_GIT=1` / `LINT_TEST_REAL_TOOLS=1`.