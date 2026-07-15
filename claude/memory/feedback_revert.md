---
name: Use git revert for rollbacks
description: When reverting failed experiments, use git revert or git checkout instead of manually recoding the changes
type: feedback
originSessionId: b9fb9796-6d13-4813-8b40-171fd705aa3c
---
Use `git checkout` or `git revert` to undo failed experiments instead of manually re-editing files back to their previous state.

**Why:** It's faster and less error-prone than recoding.
The user explicitly corrected this approach.

**How to apply:** When a change needs to be fully rolled back, use git tools (checkout files, revert commits) rather than planning to re-edit each file.
