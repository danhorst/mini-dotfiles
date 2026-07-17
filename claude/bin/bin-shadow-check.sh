#!/usr/bin/env bash
set -euo pipefail

# Flags the self-recursion footgun from feedback_repo_bin_path.md: a script that
# lives in a bin/ dir (usually on PATH) and invokes its own basename as a bare
# command word re-enters itself instead of the same-named system binary.
# Takes script paths as args so other repos' pre-commits can reuse it.
#
# Conservative by design: only the self-name case is detected — the two real
# incidents. Bare calls to *other* shadowed system tools are out of scope; they
# can't be told from ordinary command use without false positives. Comments,
# quoted strings, and heredoc bodies are blanked before matching so a name that
# is also an English word (e.g. `memory`) isn't flagged where it's just prose.

fail=0
hd_re='[<][<]-?['\''"]?([A-Za-z_][A-Za-z0-9_]*)'

for f in "$@"; do
  [[ -f "$f" ]] || continue
  # Only scripts whose immediate parent dir is bin/.
  [[ "$(basename "$(dirname "$f")")" == "bin" ]] || continue

  name=$(basename "$f")
  name="${name%.*}"   # bin/sample.sh guards the tool `sample` too
  # Escape regex metacharacters so names like bin-shadow-check match literally.
  # shellcheck disable=SC2016  # literal sed replacement, no shell expansion intended
  esc=$(printf '%s' "$name" | sed 's/[.[\*^$()+?{|]/\\&/g')

  # Build a line-for-line "code only" view: heredoc bodies become blank lines,
  # and per line the quoted spans and trailing comments are stripped. Line count
  # is preserved so rg --line-number still points at the real source line.
  cleaned=""
  heredoc=""
  while IFS= read -r raw || [[ -n "$raw" ]]; do
    if [[ -n "$heredoc" ]]; then
      [[ "$raw" =~ ^[[:space:]]*${heredoc}[[:space:]]*$ ]] && heredoc=""
      cleaned+=$'\n'
      continue
    fi
    [[ "$raw" =~ $hd_re ]] && heredoc="${BASH_REMATCH[1]}"
    cleaned+=$(printf '%s' "$raw" | sed -E -e 's/"[^"]*"//g' -e "s/'[^']*'//g" -e 's/(^|[[:space:]])#.*$//')
    cleaned+=$'\n'
  done < "$f"

  # Bare invocation at a command position: line start, or after a separator
  # ( ; | & ( && || ), optional `exec`, then the name followed by space or EOL.
  # Path forms (./name, /usr/bin/name, dir/name) and `name=` assignments don't
  # match; the function definition `name ()` is filtered out below.
  matches=$(printf '%s' "$cleaned" | rg --line-number \
    "(^|[;|&(]|&&|\|\|)[[:space:]]*(exec[[:space:]]+)?${esc}([[:space:]]|\$)" 2>/dev/null \
    | rg --invert-match "[[:space:]]*(function[[:space:]]+)?${esc}[[:space:]]*\(\)" || true)

  if [[ -n "$matches" ]]; then
    echo "bin-shadow-check: $f invokes its own name '${name}' by bare word — self-recurses on PATH."
    echo "  Fix: call the system tool by absolute path (e.g. /usr/bin/${name}, /usr/sbin/${name})."
    # Show the real source line (matches carry line numbers into the cleaned view).
    while IFS=: read -r ln _; do
      [[ -n "$ln" ]] || continue
      echo "    ${ln}:$(sed -n "${ln}p" "$f")"
    done <<< "$matches"
    fail=1
  fi
done

exit "$fail"
