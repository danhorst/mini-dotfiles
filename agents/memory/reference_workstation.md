---
name: Workstation specs
description: Hardware facts for this machine — RAM and architecture — that drive context-discipline decisions
metadata:
  type: reference
  cement: false
---

- RAM: ${RAM_GB}GB total
- Architecture: ${ARCH}

This is a single-machine setup; the dotfiles repo deploys these seeds only to this workstation.

**Behavioral implication:** memory pressure is the binding constraint.
Sub-agents (parent reclaims their window on exit), `run_in_background` for long shell commands, and `Read` with `offset`/`limit` rather than whole-file loads are the levers when context budget tightens.
See also [[dbh-profile-and-working-dynamics]].
