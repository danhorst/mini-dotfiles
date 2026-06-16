#!/usr/bin/env bash
set -euo pipefail

# Idempotent, non-destructive: fills gaps in the live memory dir from cemented
# seeds in dotfiles. Runs at SessionStart. Never overwrites live state.

SEEDS_DIR="$HOME/git/danhorst/dotfiles/claude/memory"
ENCODED_CWD="${PWD//\//-}"
LIVE_DIR="$HOME/.claude/projects/${ENCODED_CWD}/memory"
SEEDS_INDEX="$SEEDS_DIR/MEMORY.md"
LIVE_INDEX="$LIVE_DIR/MEMORY.md"

[[ -d "$SEEDS_DIR" ]] || exit 0

mkdir -p "$LIVE_DIR"

# Host facts for templated seeds. envsubst is given an explicit allowlist so any
# other $VAR appearing in a seed is preserved literally.
RAM_GB=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
ARCH=$(uname -m)
export RAM_GB ARCH

for seed in "$SEEDS_DIR"/*.md; do
  filename=$(basename "$seed")
  [[ "$filename" == "MEMORY.md" ]] && continue
  target="$LIVE_DIR/$filename"
  [[ -e "$target" ]] && continue
  # shellcheck disable=SC2016  # envsubst parses the allowlist itself; literal $VAR is intended
  envsubst '$RAM_GB $ARCH' < "$seed" > "$target"
done

if [[ ! -s "$LIVE_INDEX" ]]; then
  printf '# Memory Index\n\n' > "$LIVE_INDEX"
fi

[[ -e "$SEEDS_INDEX" ]] || exit 0

while IFS= read -r line; do
  [[ "$line" =~ \(([^\)]+\.md)\) ]] || continue
  fname="${BASH_REMATCH[1]}"
  rg --fixed-strings --quiet "($fname)" "$LIVE_INDEX" && continue
  printf '%s\n' "$line" >> "$LIVE_INDEX"
done < "$SEEDS_INDEX"
