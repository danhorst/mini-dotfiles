#!/usr/bin/env bash
# Deterministic gate for the lint+ fixture: build, vet, gofmt, test.
# Skipped tests FAIL the gate — a skipped rule test is not coverage, so a
# cell cannot go green by skipping rules whose tools are absent. Absent
# rule-fixture tests also fail: every rule must ship ok/ and bad/ fixtures
# and at least one test must read them, so a cell cannot go green by writing
# no rule tests at all.
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

echo "=== rule fixtures exercised ==="
# Each rule must ship non-empty ok/ and bad/ fixtures somewhere in the tree,
# and at least one test must read testdata — so a cell cannot go green by
# declaring rules but never running them against fixtures.
for rule in shellcheck settings-sort md-shape gofmt json-fmt; do
  ok=$(find . -type d -path "*/testdata/$rule/ok" 2>/dev/null | head -1)
  bad=$(find . -type d -path "*/testdata/$rule/bad" 2>/dev/null | head -1)
  ok_has=""; bad_has=""
  [ -n "$ok" ] && ok_has=$(find "$ok" -mindepth 1 2>/dev/null | head -1)
  [ -n "$bad" ] && bad_has=$(find "$bad" -mindepth 1 2>/dev/null | head -1)
  if [ -z "$ok_has" ] || [ -z "$bad_has" ]; then
    echo ">>> FAILED: rule '$rule' missing non-empty ok/ or bad/ fixtures"
    fail=1
  fi
done
if ! grep -rlq "testdata" --include='*_test.go' . 2>/dev/null; then
  echo ">>> FAILED: no *_test.go reads testdata (rule fixtures not exercised)"
  fail=1
fi

if [ $fail -eq 0 ]; then echo "GATE: GREEN"; else echo "GATE: RED"; fi
exit $fail
