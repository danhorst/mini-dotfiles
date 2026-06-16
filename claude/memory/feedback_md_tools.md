---
name: md-tools usage — mdsplit and mdtable
description: Pipe mdsplit into mdtable with -w; use &#124; not \| for pipes in table cells
metadata:
  type: feedback
---

`mdsplit` and `mdtable` print to stdout; they do not modify files in-place by default.
Use `-w <file>` to write output back to a file.
Pipe `mdsplit` into `mdtable` to run both in one pass:

```
mdsplit <file> | mdtable -w <file>
```

**Why:** running them separately (without piping) requires a temp file or two passes; piping is the intended workflow.

**How to apply:** whenever processing a Markdown file through both tools, use the pipe form above.

Also: the `\|` escape for pipes in table cells breaks `mdtable` — it parses the backslash-pipe as a real column separator.
Use the HTML entity `&#124;` instead when a literal pipe is needed inside a table cell.
