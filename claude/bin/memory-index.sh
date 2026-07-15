#!/usr/bin/env bash
set -euo pipefail

# Regenerates MEMORY.md from the frontmatter of the cemented seeds. Single source
# of truth for the index format; called by cement-memory.sh after a promotion, and
# runnable standalone. Order: type priority, then alpha within type (glob default).

CLAUDE_ROOT="$(dirname "$(readlink "$HOME/.claude/commands")")"
SEEDS_DIR="$CLAUDE_ROOT/memory"
SEEDS_INDEX="$SEEDS_DIR/MEMORY.md"

{
  echo "# Memory Index"
  echo ""
  for type in user reference project feedback; do
    for f in "$SEEDS_DIR"/*.md; do
      base=$(basename "$f")
      [[ "$base" == "MEMORY.md" ]] && continue
      file_type=$(rg --max-count 1 --replace '$1' '^  type: (.*)$' "$f" 2>/dev/null || true)
      [[ "$file_type" != "$type" ]] && continue
      name=$(rg --max-count 1 --replace '$1' '^name: (.*)$' "$f" 2>/dev/null || true)
      desc=$(rg --max-count 1 --replace '$1' '^description: (.*)$' "$f" 2>/dev/null || true)
      [[ -z "$name" || -z "$desc" ]] && continue
      echo "- [$name]($base) — $desc"
    done
  done
} > "$SEEDS_INDEX"

echo "regenerated $SEEDS_INDEX" >&2
