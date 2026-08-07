---
name: feedback-deployment-hardening
description: "For personal/hobby-scale services, DBH closes out deployment once baseline safeguards exist rather than completing every hardening recommendation"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7bbfcf74-fbcf-4c46-9a6d-caf403c95e1e
  modified: 2026-08-05T13:29:51.232Z
---

DBH is fine skipping "nice to have" hardening steps (e.g. disabling system sleep) when existing safeguards already cover the same failure mode — don't push to complete a plan's full checklist if the residual risk is already mitigated another way.

**Why:** For the `watcher` service (personal restock/blog notifier, not mission-critical), the plan recommended `sudo pmset -c sleep 0` so the host wouldn't sleep and drop the WebSub listener.
DBH declined: the Mac Mini already restarts on power failure, Amphetamine keeps it awake indefinitely, and he'd independently verified via Lingon (a GUI launchd inspector he has installed) that the LaunchDaemon has `RunAtLoad` and crash-restart configured.
The recommended hardening step would have been redundant given those existing safeguards.

**How to apply:** When closing out a deployment/plan for a low-stakes personal tool, distinguish "safety net not yet in place" from "belt-and-suspenders on top of an existing safety net" — press on the former, accept a reasoned pass on the latter.
Also: DBH has Lingon installed and uses it to *inspect/verify* launchd job state, even when the actual deploy mechanism is a plain plist + script.
