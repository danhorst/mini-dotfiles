Get an adversarial second opinion on a spec, design doc, or diff from a different model (OpenAI Codex).
The external model finds; you filter.
Raw Codex output is mostly triage overhead — the value is in the filtering, which is your job, not the script's.

## Run it

`second-opinion.sh` owns the orchestration — target assembly, Codex flags, the baked adversarial prompt, and the model/auth fallback.

- A document: `second-opinion.sh path/to/SPEC.md [more.md ...]`
- The current diff: `second-opinion.sh --diff [BASE]` (BASE defaults to `HEAD`)
- Override the prompt: `-p prompt.txt`. Force a model: `-m MODEL`.

Default to no `-m`.
Codex's model selection is auth-dependent: under a ChatGPT-account login, models like `o3` are silently rejected.
The script detects that one failure and retries on the default, but a forced model is a foot-gun — only pass `-m` when you know it is available on the active auth.

The script runs Codex read-only and ephemeral, so it cannot mutate the repo or leave session cruft.

## Triage the output

Codex returns many findings, ranked by its own sense of severity, and it does not always read the whole document.
Do not relay the raw dump.
Filter:

1. **Cluster.** Collapse findings that circle one root cause into a single item.
2. **Dedupe against the document.** Drop anything that restates a decision the document already pinned — Codex flagging your own stated constraint as "blocking" is noise.
3. **Rank by severity × novelty.** A "blocking" that repeats a pinned decision is noise; a "minor" you had not seen is signal. Novelty is the axis Codex cannot judge and you can.
4. **Split by altitude.** Separate findings that belong in the document (fold into the spec) from implementation-level ones (defer to the code or the driver script).
5. **Name the spec-gaps.** A finding that the *document* failed to require something grades the document, not the author — surface it as a gap to close, not a defect.

## Report

Present a synthesis, not the transcript:

- The one or few findings that genuinely matter, with the section each cites.
- The cheap, real fixes worth taking regardless.
- What was noise or already-covered, named briefly so DBH can see the filter you applied.

Then act on DBH's call.
Expect roughly two-thirds of the raw output to fall away in triage; if it does not, you are under-filtering.
