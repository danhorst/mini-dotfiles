---
name: feedback_spec_process_boundary
description: "Keep solution design out of guidance files — AGENTS.md states invariants, OpenSpec artifacts decide mechanisms"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 24307e09-f00f-437b-9a01-27c5b43b1060
---

When DBH runs a spec-driven process, do not resolve product design questions in guidance files, plans, or conversation — route them into the spec process.
He pushed back on a question about where triage belongs with: "This is straying into solution design which should be in the spec-driven process."

The altitude split he wants:

- `AGENTS.md` / `openspec/config.yaml` `context:` — invariants and constraints a design must honor, plus explicitly-named open questions.
- `openspec/changes/*/design.md` — the mechanism that honors them.

An open question is not a gap to fill before proposing; recording it *in* the project context is the work, because it forces the generated design artifact to confront it.

**Why:** deciding in the guidance file skips the process that exists to weigh alternatives, and pins a choice where no one will look for it later.
See [[spec-pipeline-status]] — the pipeline's whole premise is that specs, not side channels, carry decisions.

**How to apply:** when a design choice surfaces mid-planning, name the tension, write it under an `## Open questions` heading in the project context, and let `/opsx:explore` or `/opsx:propose` resolve it.
State invariants ("the reviewer runs cold"), never mechanisms (`-c project_doc_max_bytes=0`), in guidance.
Related: [[feedback_config_ownership]].
