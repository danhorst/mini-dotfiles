#!/usr/bin/env bash
# Send a document or diff to OpenAI Codex for an adversarial second-opinion review.
# Orchestration only: target assembly, model/auth fallback, Codex flags, baked prompt.
# Claude triages the raw findings per commands/second-opinion.md.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: second-opinion.sh [-m MODEL] [-p PROMPT_FILE] <PATH...>
       second-opinion.sh [-m MODEL] [-p PROMPT_FILE] --diff [BASE]

  PATH...        files to review, concatenated
  --diff [BASE]  review the diff against BASE (default: HEAD)
  -m MODEL       force a Codex model; omitted, Codex picks its own default
  -p PROMPT_FILE read the review prompt from a file instead of the baked default
EOF
  exit 2
}

model=""
prompt_file=""
diff_mode=false
diff_base="HEAD"
paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) model="$2"; shift 2 ;;
    -p) prompt_file="$2"; shift 2 ;;
    --diff)
      diff_mode=true; shift
      if [[ $# -gt 0 && "$1" != -* ]]; then diff_base="$1"; shift; fi ;;
    -h|--help) usage ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *) paths+=("$1"); shift ;;
  esac
done

if ! $diff_mode && [[ ${#paths[@]} -eq 0 ]]; then usage; fi

# The material to review, emitted on stdin and appended by Codex as a <stdin> block.
material() {
  if $diff_mode; then
    git diff "$diff_base"
  else
    cat "${paths[@]}"
  fi
}

# The review prompt: baked default, or overridden with -p.
if [[ -n "$prompt_file" ]]; then
  review_prompt="$(cat "$prompt_file")"
else
  review_prompt="$(cat <<'EOF'
You are an adversarial design reviewer. The material to review follows in the
<stdin> block. Review the design and substance, not the prose. Report only
findings — no praise, no summary.

For each finding: state it precisely, cite the section or location, rate
severity (blocking / major / minor), and propose one concrete fix.

Prioritize, in order:
1. Internal contradictions — one part that defeats another.
2. Confounds and invalid comparisons — a conclusion the design cannot support.
3. Unhandled cases — concurrency, empty input, failure, adversarial input.
4. Hidden assumptions stated as fact.
5. Gaps between what is claimed done and what is actually verifiable.

Do not restate decisions the document has already pinned. Find what it missed.
EOF
)"
fi

# Codex streams its answer to stderr as it generates, then prints the final
# message to stdout. Keep the streams apart: stdout is the clean findings,
# stderr is progress chrome plus any auth error we need to detect. Merging them
# would duplicate every finding into the caller's context.
err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT

attempt() {
  local -a args=(exec --sandbox read-only --skip-git-repo-check --ephemeral)
  [[ -n "$1" ]] && args+=(-m "$1")
  material | codex "${args[@]}" "$review_prompt" 2>"$err_file"
}

if out="$(attempt "$model")"; then
  printf '%s\n' "$out"
  exit 0
fi

# A forced model can be silently unavailable under ChatGPT-account auth. Fall back.
if [[ -n "$model" ]] && grep -q "not supported when using Codex with a ChatGPT account" "$err_file"; then
  echo "second-opinion: model '$model' unavailable on this Codex auth; retrying on default" >&2
  if out="$(attempt "")"; then
    printf '%s\n' "$out"
    exit 0
  fi
fi

cat "$err_file" >&2
exit 1
