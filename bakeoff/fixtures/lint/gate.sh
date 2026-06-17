#!/usr/bin/env bash
# Deterministic gate for the lint fixture: build, vet, gofmt, test.
# Skipped tests FAIL the gate — a skipped rule test is not coverage, so a
# cell cannot go green by skipping rules whose tools are absent.
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
  echo ">>> FAILED: skipped tests (rules must be exercised):"
  echo "$test_out" | grep -- '--- SKIP'
  fail=1
fi

if [ $fail -eq 0 ]; then echo "GATE: GREEN"; else echo "GATE: RED"; fi
exit $fail
