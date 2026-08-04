---
name: reference-aoe-integration-surfaces
description: "Which Agent of Empires extension points are actually reachable from a wrk-style workflow, and the one channel that always works"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 62e9f088-87c8-4597-9576-093198551415
  modified: 2026-08-04T15:25:02.630Z
---

Agent of Empires (`aoe`, source at `~/git/agent-of-empires/agent-of-empires`) advertises two extension surfaces, and both are unavailable unless a long-running aoe process happens to be up:

- **Plugin workers** (JSON-RPC over stdio, `aoe-plugin.toml`) are started only by the serve daemon — `PluginHost::new` is constructed in `src/server/mod.rs`. No `aoe serve`, no plugin.
- **`[status_hooks]`** fire only from the TUI (`src/tui/attached_status_hooks.rs`, `src/tui/home/mod.rs`) or from `aoe serve` via `src/server/callback.rs`. There is no headless dispatcher.

The channel that always works is the **hook status file**: `/tmp/aoe-hooks-<euid>/<instance-id>/status`, containing one of `running|waiting|idle|error` (`src/hooks/status_file.rs`, base path from `src/hooks/dir_guard.rs`).
The *agent* writes it, via hooks aoe installs into the agent's own config, so it stays current with no aoe process running at all.
The instance id is the full `.id` from `aoe list --json` and matches the directory name exactly.
Sibling files in that directory: `session_id`, and `attention.json` (`{urgent, urgent_expires_at}`) — a sanctioned *write* channel for raising attention from outside aoe.

`aoe list --json` publishes more than it looks like: `tool`, and a `worktree` object with `branch` and `main_repo_path`.
It does **not** expose `trashed_at`, and it does include trashed records, so trashed sessions must be subtracted via `aoe session list-trash` (no `--json`; two-space-indented rows).

**Why:** the plugin route is the obvious-looking way to integrate and it is a dead end for anyone who drives aoe from a session manager rather than living in its TUI.
Establishing that took reading aoe's source; nothing in either project's docs records it.

**How to apply:** when integrating anything with aoe, reach for the status file and `aoe list --json` first, and treat plugins or `[status_hooks]` as viable only once `aoe serve` or the TUI is a stated requirement.
See [[project_shell_config_naming]] for the related instinct that config belongs to the tool that owns it.
