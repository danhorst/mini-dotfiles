#!/usr/bin/env bash
set -euo pipefail

# Emits the end-of-session memory-triage report consumed by /wrap-it-up. Buckets each
# live memory file against the cemented seed set and flags staleness. Deterministic
# bookkeeping only — the direction and worth-cementing judgments stay with the caller.

CLAUDE_ROOT="$(dirname "$(readlink "$HOME/.claude/commands")")"
SEEDS_DIR="$CLAUDE_ROOT/memory"
ENCODED_CWD="${PWD//\//-}"
LIVE_DIR="$HOME/.claude/projects/${ENCODED_CWD}/memory"

if [[ ! -d "$LIVE_DIR" ]]; then
  echo "no live memory dir ($LIVE_DIR)"
  exit 0
fi

new=() changed=() excluded=() unchanged=0

for live in "$LIVE_DIR"/*.md; do
  [[ -e "$live" ]] || continue
  filename=$(basename "$live")
  [[ "$filename" == "MEMORY.md" ]] && continue
  seed="$SEEDS_DIR/$filename"

  # Exclusion wins over changed: a templated seed byte-differs from its live copy
  # after envsubst, but must never be offered for cementing.
  if [[ -e "$seed" ]] && rg --quiet '^  cement: false$' "$seed"; then
    excluded+=("$filename")
  elif [[ ! -e "$seed" ]]; then
    new+=("$filename")
  elif ! cmp --silent "$live" "$seed"; then
    changed+=("$filename")
  else
    unchanged=$((unchanged + 1))
  fi
done

if [[ ${#new[@]} -eq 0 && ${#changed[@]} -eq 0 ]]; then
  echo "no memory changes to cement (${unchanged} unchanged, ${#excluded[@]} excluded)"
  exit 0
fi

if [[ ${#new[@]} -gt 0 ]]; then
  echo "## NEW (in live, not cemented)"
  echo ""
  for filename in "${new[@]}"; do
    desc=$(rg --max-count 1 --replace '$1' '^description: (.*)$' "$LIVE_DIR/$filename" 2>/dev/null || true)
    echo "- $filename — ${desc:-(no description)}"
  done
  echo ""
fi

if [[ ${#changed[@]} -gt 0 ]]; then
  echo "## CHANGED (in both, content differs)"
  echo ""
  for filename in "${changed[@]}"; do
    live="$LIVE_DIR/$filename"
    flags=()
    rg --quiet '^\s*originSessionId:' "$live" && flags+=("originSessionId")
    rg --quiet '^type:' "$live" && flags+=("flat-type")
    if [[ ${#flags[@]} -gt 0 ]]; then
      echo "### $filename — stale-live signals: ${flags[*]}"
    else
      echo "### $filename"
    fi
    echo ""
    git diff --no-index -- "$SEEDS_DIR/$filename" "$live" || true
    echo ""
  done
fi

if [[ ${#excluded[@]} -gt 0 ]]; then
  echo "## EXCLUDED (seed marked cement: false — reported, not offered)"
  echo ""
  for filename in "${excluded[@]}"; do
    echo "- $filename"
  done
  echo ""
fi

echo "(${unchanged} unchanged, not listed)"
