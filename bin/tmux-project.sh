#!/usr/bin/env bash
set -e

PROJECT_ROOT="$HOME/git"

# Collect first-level git repos
PROJECTS=()
for gitdir in "$PROJECT_ROOT"/*/.git; do
  [ -d "$gitdir" ] || continue
  PROJECTS+=( "$(dirname "$gitdir")" )
done

# Bail if none found
[ "${#PROJECTS[@]}" -eq 0 ] && exit 0

# Select project
PROJECT_PATH=$(printf '%s\n' "${PROJECTS[@]}" \
  | sed "s|^$PROJECT_ROOT/||" \
  | fzf --prompt="Select project: ")

[ -z "$PROJECT_PATH" ] && exit 0

PROJECT_PATH="$PROJECT_ROOT/$PROJECT_PATH"

# tmux-safe session name
SESSION="proj-$(basename "$PROJECT_PATH" | tr -c 'a-zA-Z0-9' '_')"

# Attach or create session
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach -d -t "$SESSION"
else
  tmux new-session -s "$SESSION" -c "$PROJECT_PATH"
fi
