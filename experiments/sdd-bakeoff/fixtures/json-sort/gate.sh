#!/usr/bin/env bash
# Deterministic gate for the json-sort fixture: build, vet, gofmt, test.
# Skipped tests FAIL the gate — a skipped test is not coverage. Absent
# transform fixtures also fail: the tool must ship testdata/sort/ok and
# testdata/sort/bad fixtures and at least one test must read them, so a
# cell cannot go green by writing no fixture-driven tests at all.
# Run as: gate.sh <impl-dir>. Nonzero exit = not green.
set -uo pipefail

cd "$1" || { echo "GATE: bad dir $1"; exit 2; }

fail=0
run() {
  echo "=== $* ==="
  if ! "$@"; then echo ">>> FAILED: $*"; fail=1; fi
}

run go build ./...
run go vet ./...

echo "=== gofmt -l . ==="
unformatted=$(gofmt -l . 2>&1)
if [ -n "$unformatted" ]; then echo ">>> FAILED gofmt:"; echo "$unformatted"; fail=1; fi

echo "=== go test ./... -v (skips fail the gate) ==="
test_out=$(go test ./... -v 2>&1)
test_rc=$?
echo "$test_out" | grep -E '^(ok|FAIL|---)' || true
if [ "$test_rc" -ne 0 ]; then echo ">>> FAILED: go test"; fail=1; fi
if echo "$test_out" | grep -q -- '--- SKIP'; then
  echo ">>> FAILED: skipped tests (the transform must be exercised):"
  echo "$test_out" | grep -- '--- SKIP'
  fail=1
fi

echo "=== transform fixtures exercised ==="
# The transform must ship non-empty ok/ and bad/ fixtures somewhere in the
# tree, and at least one test must read testdata — so a cell cannot go green
# by implementing the sort but never running it against fixtures.
ok=$(find . -type d -path "*/testdata/sort/ok" 2>/dev/null | head -1)
bad=$(find . -type d -path "*/testdata/sort/bad" 2>/dev/null | head -1)
ok_has=""; bad_has=""
[ -n "$ok" ] && ok_has=$(find "$ok" -mindepth 1 2>/dev/null | head -1)
[ -n "$bad" ] && bad_has=$(find "$bad" -mindepth 1 2>/dev/null | head -1)
if [ -z "$ok_has" ] || [ -z "$bad_has" ]; then
  echo ">>> FAILED: component 'sort' missing non-empty ok/ or bad/ fixtures"
  fail=1
fi
if ! grep -rlq "testdata" --include='*_test.go' . 2>/dev/null; then
  echo ">>> FAILED: no *_test.go reads testdata (transform fixtures not exercised)"
  fail=1
fi

if [ $fail -eq 0 ]; then echo "GATE: GREEN"; else echo "GATE: RED"; fi
exit $fail
