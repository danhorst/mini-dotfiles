---
name: project_watcher_heartbeat
description: "watcher's healthchecks.io dead-man's-switch is Period 1h / Grace 1h — grace deliberately equals the ping interval so one dropped ping doesn't page"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8b25d8f3-d7d0-4c11-8dd8-fe4e6d65c17c
  modified: 2026-08-05T15:37:38.063Z
---

The `watcher` daemon (`~/git/local/watcher`) pings a healthchecks.io check hourly; the check is configured Period 1h, Grace Time 1h as of 2026-08-05.

**Why:** grace equals the interval on purpose, not by accident.
A failed ping in `internal/heartbeat/heartbeat.go` is logged and dropped — there's no retry until the next tick — so a single transient failure leaves a ~2h gap between successful pings.
Any grace under 1h would page on one blip.
At 1h it takes two consecutive misses (~2h) to alert, which is the right tradeoff for a personal restock/blog notifier where detection latency doesn't matter.

**How to apply:** if `heartbeat.interval` in `config.yaml` changes, both healthchecks.io values need to change with it — period to match the new interval, grace to at least one interval.
`README.md` documents matching the period but not the grace reasoning, so don't assume the repo is the full picture.
Tightening detection means shortening the interval (e.g.
15m/20m), not shrinking the grace.

See [[feedback_deployment_hardening]] for the surrounding preference on how far to take hardening on this service.
