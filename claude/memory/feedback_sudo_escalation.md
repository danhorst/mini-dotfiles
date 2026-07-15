---
name: feedback-sudo-escalation
description: "For helper scripts needing root, self-escalate at the top — don't prime sudo mid-script"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fd44a43c-440b-419c-aa7a-9ee4fe2c5f8b
---

When a bash helper script needs root for one of its commands, re-exec under sudo at the very top instead of priming via `sudo -v` and calling `sudo cmd` later.

**Why:** A helper script that primed with `sudo -v` plus a background keepalive failed in DBH's terminal — the interactive prompt didn't take, and the privileged command later ran without root.
He had to invoke the script explicitly with sudo himself.
The prime-then-call pattern is unreliable in his environment.

**How to apply:** At the top of any script that needs root for at least one command:

```bash
if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi
# Use SUDO_USER if you need the invoking user's home dir.
```

Drop the `sudo -v` prime, the background `sudo -n true` keepalive, and per-call `sudo` prefixes — they're not needed once the whole script runs as root.
