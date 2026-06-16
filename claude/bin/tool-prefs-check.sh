#!/usr/bin/env bash
set -euo pipefail

# PreToolUse Bash hook: warn when a command's first word is a POSIX default
# that has an established replacement (see feedback_tool_prefs.md).
#
# Light context awareness:
#   - extension match on positional args (file.rb → code, config.yaml → config)
#   - recursive-search flag (-r / -R / --recursive) on grep → code
# Extension lists live in claude/etc/{code,config}-extensions.txt so they
# can be tuned without editing this script. Warns; never blocks.

DOTFILES_ETC="${HOME}/git/danhorst/dotfiles/claude/etc"

command=$(jq -r '.tool_input.command // empty')
[[ -z "$command" ]] && exit 0

load_exts() {
  local file="$1"
  [[ -r "$file" ]] || return 0
  rg --no-line-number --no-filename '^[^#[:space:]]+' "$file" 2>/dev/null || true
}

mapfile -t code_exts < <(load_exts "${DOTFILES_ETC}/code-extensions.txt")
mapfile -t config_exts < <(load_exts "${DOTFILES_ETC}/config-extensions.txt")

# Does any token in the segment end in .<ext> (or contain *.<ext>) for any
# extension in the list?
has_target_ext() {
  local segment="$1"
  shift
  local -a exts=("$@")
  [[ ${#exts[@]} -eq 0 ]] && return 1
  local -a tokens=()
  read -ra tokens <<< "$segment"
  local token ext
  for token in "${tokens[@]}"; do
    token="${token#\"}"; token="${token%\"}"
    token="${token#\'}"; token="${token%\'}"
    for ext in "${exts[@]}"; do
      [[ "$token" == *".$ext" ]] && return 0
      [[ "$token" == *"*.$ext"* ]] && return 0
    done
  done
  return 1
}

# Is grep being run recursively over a directory tree (a strong code-search
# signal absent other context)?
has_recursive_flag() {
  local segment="$1"
  case " $segment " in
    *" -r "*|*" -R "*|*" --recursive "*) return 0 ;;
  esac
  return 1
}

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
    grep)
      if has_target_ext "$segment" "${code_exts[@]}" || has_recursive_flag "$segment"; then
        warnings+=("ast-grep instead of grep (target looks like code)")
      else
        warnings+=("rg instead of grep")
      fi
      ;;
    find)
      warnings+=("fd instead of find")
      ;;
    sed)
      if has_target_ext "$segment" "${config_exts[@]}"; then
        warnings+=("yq instead of sed (target looks like a config file)")
      else
        warnings+=("sd for find/replace instead of sed")
      fi
      ;;
    awk)
      if has_target_ext "$segment" "${config_exts[@]}"; then
        warnings+=("yq instead of awk (target looks like a config file)")
      else
        warnings+=("rg --replace or yq instead of awk")
      fi
      ;;
  esac
done

[[ ${#warnings[@]} -eq 0 ]] && exit 0

echo "Tool prefs reminder — prefer:"
printf '%s\n' "${warnings[@]}" | sort -u | while IFS= read -r w; do
  printf '  - %s\n' "$w"
done
