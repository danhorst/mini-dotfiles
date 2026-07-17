#!/usr/bin/env bash
set -euo pipefail

# Validates the cemented memory seeds that memory-index.sh consumes but never
# checks — it silently drops anything malformed, which is how flat-`type:` seeds
# and filename-stem [[wikilinks]] stayed invisible. Exits non-zero with a
# per-failure fix hint. Runnable standalone; called from .githooks/pre-commit.

CLAUDE_ROOT="$(dirname "$(readlink "$HOME/.claude/commands")")"
SEEDS_DIR="$CLAUDE_ROOT/memory"
INDEX="$SEEDS_DIR/MEMORY.md"

fail=0
note() { echo "memory-lint: $1"; fail=1; }

# Match [[tokens]] to seed names the way the memory resolver does: lowercase,
# every run of non-alphanumerics (spaces, _, em/en dashes, punctuation) -> '-',
# trimmed. Byte-safe, so no multibyte bracket expressions needed.
kebab() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//'
}

# Pass 1: resolvable link targets = kebab(name) of every seed.
declare -A valid_target=()
for f in "$SEEDS_DIR"/*.md; do
  base=$(basename "$f")
  [[ "$base" == "MEMORY.md" ]] && continue
  name=$(rg --max-count 1 --replace '$1' '^name: (.*)$' "$f" 2>/dev/null || true)
  [[ -n "$name" ]] && valid_target["$(kebab "$name")"]=1
done

# Pass 2: per-seed structural checks.
for f in "$SEEDS_DIR"/*.md; do
  base=$(basename "$f")
  [[ "$base" == "MEMORY.md" ]] && continue

  name=$(rg --max-count 1 --replace '$1' '^name: (.*)$' "$f" 2>/dev/null || true)
  desc=$(rg --max-count 1 --replace '$1' '^description: (.*)$' "$f" 2>/dev/null || true)
  [[ -z "$name" ]] && note "$base: missing 'name:' (memory-index.sh will drop it)"
  [[ -z "$desc" ]] && note "$base: missing 'description:' (memory-index.sh will drop it)"

  # type must be nested under metadata (^  type:), not flat (^type:).
  if rg --quiet '^type:' "$f"; then
    note "$base: flat 'type:' — nest under 'metadata:' (2-space indent) or memory-index.sh skips it"
  elif ! rg --quiet '^  type: (user|reference|project|feedback)$' "$f"; then
    note "$base: missing or unknown 'metadata.type:' (want user|reference|project|feedback)"
  fi

  # Must appear in the generated index.
  rg --fixed-strings --quiet "($base)" "$INDEX" 2>/dev/null \
    || note "$base: absent from MEMORY.md — run memory-index.sh"

  # Every [[wikilink]] must resolve to some seed's kebab(name). Tokens are
  # space-free by convention, which also skips bash `[[ ... ]]` tests in code.
  while IFS= read -r token; do
    [[ -z "$token" ]] && continue
    [[ -n "${valid_target[$(kebab "$token")]:-}" ]] \
      || note "$base: broken [[${token}]] — no seed's name resolves to it"
  done < <(rg --only-matching --replace '$1' '\[\[([^\]\s]+)\]\]' "$f" 2>/dev/null || true)
done

[[ $fail -eq 0 ]] && echo "memory-lint: ok"
exit "$fail"
