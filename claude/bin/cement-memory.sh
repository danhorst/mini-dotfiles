#!/usr/bin/env bash
set -euo pipefail

# Promotes named files from live memory to the cemented seed set in dotfiles.
# Regenerates MEMORY.md from the frontmatter of present seeds when anything
# was cemented. Refuses files marked `cement: false` in their seed frontmatter.

CLAUDE_ROOT="$(dirname "$(readlink "$HOME/.claude/commands")")"
SEEDS_DIR="$CLAUDE_ROOT/memory"
ENCODED_CWD="${PWD//\//-}"
LIVE_DIR="$HOME/.claude/projects/${ENCODED_CWD}/memory"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <file.md> [<file2.md> ...]" >&2
  echo "Promotes the named files from live memory to the cemented seed set." >&2
  exit 1
fi

cemented=0
for filename in "$@"; do
  live_file="$LIVE_DIR/$filename"
  seed_file="$SEEDS_DIR/$filename"

  if [[ ! -e "$live_file" ]]; then
    echo "skip $filename: not in live memory ($LIVE_DIR)" >&2
    continue
  fi

  if [[ -e "$seed_file" ]] && rg --quiet '^  cement: false$' "$seed_file"; then
    echo "skip $filename: seed is marked cement: false (templated or excluded)" >&2
    continue
  fi

  cp "$live_file" "$seed_file"
  echo "cemented $filename"
  cemented=$((cemented + 1))
done

[[ $cemented -eq 0 ]] && exit 0

memory-index.sh
