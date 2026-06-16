#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook for .md files written or edited under personal repos:
# warns when md-tools (mdsplit + mdtable) would change the file's shape.
# Path-scoped so legacy/work repos with their own conventions are left alone.

file_path=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file_path" ]] && exit 0
[[ -f "$file_path" ]] || exit 0

case "$file_path" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

case "$file_path" in
  "$HOME/git/danhorst/"*) ;;
  *) exit 0 ;;
esac

command -v mdsplit > /dev/null || exit 0
command -v mdtable > /dev/null || exit 0

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

mdsplit "$file_path" 2>/dev/null | mdtable 2>/dev/null > "$tmp" || exit 0
[[ -s "$tmp" ]] || exit 0

if ! diff --brief "$tmp" "$file_path" > /dev/null 2>&1; then
  echo "Markdown reminder: $(basename "$file_path") would change under mdsplit | mdtable."
  echo "  Fix: mdsplit \"$file_path\" | mdtable -i \"$file_path\""
fi
