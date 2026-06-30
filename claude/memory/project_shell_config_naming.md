---
name: project_shell_config_naming
description: "shell config files named \"zsh\" are deliberately kept bash-compatible"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4cb87a65-fa21-40ae-89d4-9a2a1cbbab48
---

In dotfiles, shell config files carry the `zsh` name (e.g.
`shell/zsh_aliases`) because DBH *uses* zsh, but the contents are deliberately kept bash-compatible.
The `#!/bin/bash` shebang and shellcheck linting-as-bash are intentional, not a mismatch to "fix."

**Why:** lets the same files work across shells; shellcheck stays useful.
**How to apply:** don't flag the zsh-name/bash-shebang as an error; avoid zsh-only syntax in these files.
