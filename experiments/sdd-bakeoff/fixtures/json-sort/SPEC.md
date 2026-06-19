# json-sort

A small CLI that sorts the keys of JSON files in place, so machine-edited config (Claude settings, tool manifests) stays diff-stable.

## Goals

- Deterministic, idempotent output: sorting twice changes nothing.
- In place, preserving each file's mode, and safe against a crash mid-write.
- No runtime dependency on `jq`; the shell version it replaces shells out, this one does not.
- Every behavior has a unit test.

## Behavior

`json-sort FILE [FILE …]` rewrites each FILE with its object keys sorted.

- Keys are sorted recursively, at every object depth; array order is preserved.
- Output is two-space indented with a trailing newline — the `jq -S` shape it replaces.
- The transform is idempotent: an already-sorted file is rewritten byte-for-byte identically.
- Each file is rewritten in place and atomically: a temp file in the same directory, then a rename.
- The original file mode is preserved.
- Multiple files are processed independently; a failure on one is reported and does not abort the rest.

## Contract

- No arguments prints usage to stderr and exits nonzero.
- `-h` / `--help` prints usage to stdout and exits zero.
- A path that is not a regular file, or does not hold valid JSON, prints a message to stderr and makes the exit nonzero; other valid files in the same invocation are still sorted.

## Pinned decisions

- **Sort is recursive and total.** Every object at every depth is sorted, not just the top level; this is what makes the output diff-stable.
- **Array element order is data, not formatting.** Arrays are never reordered — only object keys are.
- **Atomic and mode-preserving.** A crash mid-write must never truncate the original; temp-then-rename keeps the file intact, and the mode is copied so a restricted file is not widened.
- **No `jq`.** Sorting is native; the binary has no external process dependency.

## Testing

- **Fixtures** live in `testdata/sort/{ok,bad,fixed}/`.
  Running the tool on a `bad/` file must produce the matching `fixed/` file; running it on an `ok/` file must leave it byte-for-byte unchanged.
  Fixtures cover nested objects, an array of objects, and an already-sorted file.
- **Contract tests** cover no-args, `--help`, a non-file path, and an invalid-JSON file.
- **Mode preservation** is asserted: a file with a non-default mode keeps it after sorting.

## Layout

```
bin/json-sort                  # built binary, installed by install.sh
cmd/json-sort/                 # Go source and *_test.go
testdata/sort/{ok,bad,fixed}/  # transform fixtures
```

`install.sh` builds with `go build -o bin/json-sort ./cmd/json-sort`.
The binary is not committed.

## Done

- `json-sort FILE …` sorts object keys recursively, in place, idempotently, preserving mode.
- The contract — no-args, `--help`, non-file, invalid JSON — behaves as specified.
- `go test ./...` is green over the sort fixtures and the contract, with no skipped tests.

## Growth

- A `--check` mode that exits nonzero on an unsorted file without rewriting it, for pre-commit use.
- Replaces the `bin/json-sort` shell script and the `settings-sort` lint rule's fixer.
