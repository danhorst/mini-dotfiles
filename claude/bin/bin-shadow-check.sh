#!/usr/bin/env bash
set -euo pipefail

# Flags the self-recursion footgun from feedback_repo_bin_path.md: a script that
# lives in a bin/ dir (usually on PATH) and invokes its own basename as a bare
# command word re-enters itself instead of the same-named system binary.
# Takes script paths as args so other repos' pre-commits can reuse it.
#
# Conservative by design: only the self-name case is detected — the two real
# incidents. Bare calls to *other* shadowed system tools are out of scope; they
# can't be told from ordinary command use without false positives.

fail=0

for f in "$@"; do
  [[ -f "$f" ]] || continue
  # Only scripts whose immediate parent dir is bin/.
  [[ "$(basename "$(dirname "$f")")" == "bin" ]] || continue

  name=$(basename "$f")
  name="${name%.*}"   # bin/sample.sh guards the tool `sample` too
  # Escape regex metacharacters so names like bin-shadow-check match literally.
  # shellcheck disable=SC2016  # literal sed replacement, no shell expansion intended
  esc=$(printf '%s' "$name" | sed 's/[.[\*^$()+?{|]/\\&/g')

  # Bare invocation at a command position: line start, or after a separator
  # ( ; | & ( && || ), optional `exec`, then the name followed by space or EOL.
  # Path forms (./name, /usr/bin/name, dir/name) and `name=` assignments don't
  # match; the function definition `name ()` is filtered out below.
  matches=$(rg --line-number \
    "(^|[;|&(]|&&|\|\|)[[:space:]]*(exec[[:space:]]+)?${esc}([[:space:]]|\$)" "$f" 2>/dev/null \
    | rg --invert-match "[[:space:]]*(function[[:space:]]+)?${esc}[[:space:]]*\(\)" || true)

  if [[ -n "$matches" ]]; then
    echo "bin-shadow-check: $f invokes its own name '${name}' by bare word — self-recurses on PATH."
    echo "  Fix: call the system tool by absolute path (e.g. /usr/bin/${name}, /usr/sbin/${name})."
    while IFS= read -r line; do echo "    $line"; done <<< "$matches"
    fail=1
  fi
done

exit "$fail"
