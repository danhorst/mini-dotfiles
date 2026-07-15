---
name: feedback-repo-bin-path
description: "Project bin/ dirs are almost always on DBH's PATH (check .mise.toml); scripts there can shadow system binaries — write helper scripts to call system tools by absolute path"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f145cb42-244c-40e0-aa93-41f6367c6ced
---

A project's `bin/` directory is almost always on DBH's PATH — check the project's `.mise.toml` to confirm.
When a script there shares a name with a system binary (e.g.
`bin/sample` vs `/usr/bin/sample`), an unqualified call inside the script recurses on itself instead of invoking the system tool.

**Why:** This bit twice in one week: two `bin/` scripts wrapping same-named system profiling tools called them by bare name, self-recursed indefinitely (each recursion shifting `$1` into the wrong parameter), and never reached the system binary.
Diagnosis took longer than it should have both times.

**How to apply:**
- When writing or editing a script in `bin/`, call system binaries by absolute path (`/usr/bin/...`, `/usr/sbin/...`) — not the bare command name.
- When DBH says "there's an issue with that script", check the script's source before running it or recommending its use. Don't ask him to repeat himself.
- Audit other `bin/` scripts for the same shadowing pattern when touching them.
