End-of-session memory triage.
Compare live memory against the cemented seed set and resolve each divergence in whichever direction makes sense per file.
Live can drift behind cemented when a seed update wasn't mirrored — promotion isn't always the right move.

The script buckets and diffs; you judge; DBH decides.
`memory triage` does the deterministic bookkeeping (classification, staleness flags, diffs) so you spend context on judgment, not enumeration.

## Steps

1. Run `memory triage`.
   It resolves live and cemented paths itself and prints the report.
   If it reports "no memory changes to cement", relay that and stop.

2. The report has three sections. Judge each — do not rubber-stamp the buckets:

   - **CHANGED** — read the emitted diff (not the whole file) and decide the direction.
     Default **cement** (live → cemented) for a clean change.
     When a `stale-live` signal is flagged (`originSessionId`, `flat-type`), the live file is likely drift from a seed update never mirrored back, not a deliberate edit — default **re-sync** (cemented → live) instead.
   - **NEW** — read the file's content. A new live memory is a *candidate*, not an automatic promotion: session-noise gets **skipped/dropped**, not cemented.
   - **EXCLUDED** — seed is marked `cement: false` (templated). Reported for visibility only; nothing to offer.

3. While judging, surface quality issues alongside your recommendation: a broken `[[link]]`, a `description` that should be rewritten before it lands in the index, a file grown to cover two facts that should split.

4. Ask DBH the direction per file via `AskUserQuestion` (single-select, batched in groups of up to 4).
   Order options recommended-first: **Re-sync** first for stale-changed files, **Cement** first for new and clean-changed files.
   - **Cement** (live → cemented): `memory cement <filenames>`.
   - **Re-sync** (cemented → live): `memory resync <filenames>`.
   - **Skip**: leave the divergence.

5. Apply the selected actions.
   `memory cement` copies the files, regenerates `MEMORY.md`, and stages the result; it refuses any seed marked `cement: false`.

6. Show what's staged: `git -C "$(dirname "$(readlink ~/.claude/commands)")" status`.
   **Do not commit** — leave the working state clean for DBH's review.
