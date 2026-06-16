#!/usr/bin/env bash
set -euo pipefail

# PreToolUse Bash hook: warn when a command's first word is a POSIX default
# that has an established replacement (see feedback_tool_prefs.md). Splits
# the command on pipeline separators and checks only the head of each
# segment, so `git grep`, `--grep` flags, and substrings in arguments don't
# trip the check. Warns; never blocks.

command=$(jq -r '.tool_input.command // empty')
[[ -z "$command" ]] && exit 0

# Normalize pipeline separators to | so segments can be split.
normalized="${command//&&/|}"
normalized="${normalized//||/|}"
normalized="${normalized//;/|}"

declare -a warnings=()

IFS='|' read -ra segments <<< "$normalized"
for segment in "${segments[@]}"; do
  segment="${segment#"${segment%%[![:space:]]*}"}"
  cmd="${segment%% *}"
  case "$cmd" in
    grep) warnings+=("rg (or ast-grep for code constructs) instead of grep") ;;
    find) warnings+=("fd instead of find") ;;
    sed)  warnings+=("sd for find/replace, or yq for config files, instead of sed") ;;
    awk)  warnings+=("rg --replace or yq instead of awk") ;;
  esac
done

[[ ${#warnings[@]} -eq 0 ]] && exit 0

echo "Tool prefs reminder — prefer:"
printf '%s\n' "${warnings[@]}" | sort -u | while IFS= read -r w; do
  printf '  - %s\n' "$w"
done
