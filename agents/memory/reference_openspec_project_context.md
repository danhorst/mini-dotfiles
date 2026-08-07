---
name: reference_openspec_project_context
description: "OpenSpec 1.4.1 project context lives in openspec/config.yaml `context:` — `openspec/project.md` is legacy"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 24307e09-f00f-437b-9a01-27c5b43b1060
---

As of `@fission-ai/openspec` 1.4.1, project context belongs in `openspec/config.yaml` under `context:`, not `openspec/project.md`.
`dist/core/legacy-cleanup.js` preserves an existing `project.md` only to print a migration hint: *"move any useful content to config.yaml's context."*

`config.yaml` also takes per-artifact `rules:` keyed by artifact id (`proposal`, `specs`, `design`, `tasks`).
Both `context:` and the matching `rules:` entry are injected into `openspec instructions <artifact> --change <name> --json` — verify a seed actually lands by reading the `context` and `rules` fields of that JSON.

Repos still on the legacy layout as of 2026-07-09: `photo-management` (has `openspec/project.md`, no `config.yaml`).
It will be nagged on the next `openspec update`.

Useful headings for a `context:` block, taken from DBH's own `photo-management/openspec/project.md`: Purpose, Design guarantees, Critical behavior, Tech Stack, Project Conventions, Important Constraints, External Dependencies — plus `## Open questions` (see [[feedback_spec_process_boundary]]).
