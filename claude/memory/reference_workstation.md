---
name: Workstation specs
description: Hardware facts for this machine — RAM and architecture — that drive context-discipline decisions
metadata:
  type: reference
  cement: false
---

<!-- Templated seed. seed-memory.sh resolves the RAM_GB and ARCH placeholders via envsubst (explicit allowlist) at integration time. cement: false excludes this file from cement-memory.sh — the template is the canonical form; live edits are not promoted back. -->

- RAM: ${RAM_GB}GB total
- Architecture: ${ARCH}

This is a single-machine setup; the dotfiles repo deploys these seeds only to this workstation.

**Behavioral implication:** memory pressure is the main constraint behind the context-discipline rules in CLAUDE.md.
See also [[dbh-profile-and-working-dynamics]].
