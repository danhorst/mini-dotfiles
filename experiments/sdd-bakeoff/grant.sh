#!/usr/bin/env bash
# Toggle the scoped implementer permission for a bake-off run.
#
# RUN THIS YOURSELF — the auto-mode classifier blocks the agent from granting
# bypassPermissions, by design. The grant is temporary: run `off` when the run
# finishes, and do NOT commit the settings change (the file is tracked here).
#
#   experiments/sdd-bakeoff/grant.sh on      # add the allow rule before a run
#   experiments/sdd-bakeoff/grant.sh off     # remove it after
#   experiments/sdd-bakeoff/grant.sh status  # report whether it is present
set -euo pipefail

rule='Bash(claude -p * --permission-mode bypassPermissions*)'
root="$(git rev-parse --show-toplevel)"
file="$root/.claude/settings.local.json"
action="${1:-}"

case "$action" in
  on|off|status) ;;
  *) echo "usage: grant.sh on|off|status" >&2; exit 2 ;;
esac

python3 - "$file" "$rule" "$action" <<'PY'
import json, os, sys
file, rule, action = sys.argv[1:4]
data = json.load(open(file)) if os.path.exists(file) else {}
allow = data.setdefault("permissions", {}).setdefault("allow", [])
present = rule in allow
if action == "status":
    print("present" if present else "absent"); raise SystemExit(0)
if action == "on" and not present:
    allow.append(rule); print("granted:", rule)
elif action == "on":
    print("already granted")
elif action == "off" and present:
    allow.remove(rule); print("revoked:", rule)
else:
    print("not present")
with open(file, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

if [ "$action" = on ]; then
  echo "reminder: $file is tracked here — do NOT commit it; run 'grant.sh off' after the run." >&2
fi
