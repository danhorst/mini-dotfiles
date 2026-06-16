---
name: md-tools usage — mdsplit and mdtable
description: Pipe mdsplit into mdtable -i to round-trip a file; use &#124; not \| for pipes in table cells
metadata:
  type: feedback
---

`mdsplit` and `mdtable` print to stdout; they do not modify files in-place by default.
Use `-w <file>` to read a file and write back to it (ignores stdin).
Use `-i <file>` to read stdin and write to the given file — the right form at the end of a pipe.
Pipe `mdsplit` into `mdtable -i` to run both in one pass:

```
mdsplit <file> | mdtable -i <file>
```

**Why:** `mdtable -w <file>` re-reads `<file>` from disk and discards the piped `mdsplit` output, silently producing the wrong result.
`-i` was added in md-tools v1.1.0 specifically to make this chain work; v1.1.1 made `-i` a boolean flag with the file as a positional argument (same command-line surface).

**How to apply:** whenever processing a Markdown file through both tools, use the pipe form above.

Also: the `\|` escape for pipes in table cells breaks `mdtable` — it parses the backslash-pipe as a real column separator.
Use the HTML entity `&#124;` instead when a literal pipe is needed inside a table cell.
