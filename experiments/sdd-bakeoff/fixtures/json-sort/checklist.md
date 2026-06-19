# fixture json-sort — normative checklist

The MUST items the grader scores compliance against, gradeable from the built binary and its tests in isolation.
Derived from `SPEC.md` but scoped to a clean-room implementation: the spec's repo-integration Growth items (replace the shell script and the `settings-sort` rule fixer, wire `install.sh`) are out of scope and not listed here.

- **recursive sort.** Sorting a nested unsorted file orders object keys at every depth, not just the top level, and leaves array element order unchanged.
- **idempotent and formatted.** An already-sorted file is rewritten byte-for-byte identically; output is two-space indented with a trailing newline.
- **in place, atomic, mode-preserved.** The file is rewritten in place via a same-directory temp file then rename, and the original file mode is retained.
- **multi-file, independent.** Multiple path arguments are each processed; a failure on one does not abort the others.
- **contract.** No arguments prints usage to stderr and exits nonzero; `-h`/`--help` prints usage to stdout and exits zero; a non-file or invalid-JSON path prints to stderr and makes the exit nonzero while other valid files are still sorted.
- **tests green, none skipped.** `go test ./...` passes with zero skipped tests, covering the sort fixtures (`ok`/`bad`/`fixed`) and the contract. A skipped test is not coverage.
