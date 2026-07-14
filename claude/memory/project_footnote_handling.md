---
name: project-footnote-handling
description: How md-tools treats markdown footnotes and the danhorst.com parity/rendering constraints behind it
metadata: 
  node_type: memory
  type: project
  originSessionId: 199bfd42-a22c-41ff-a761-f0f0d390e7a4
---

md-tools treats a footnote definition plus its continuation lines as one **opaque block**: `markdown.Transform` collects `[^label]:` + continuation (via `IsFootnoteContinuation`) and by default emits it verbatim — never split by mdsplit, never joined by mdjoin/mdunwrap.
`mdwrap -f` (opt-in `Footnote` handler) is the one exception: it wraps the body to the column width with **4-space-indented** continuation.

**Why:** a multi-sentence footnote only renders portably when on one line, or with 4-space-indented continuation.
Flush-left continuation works in CommonMark-family parsers but breaks Kramdown and Pandoc (they need the indent), so it silently leaks footnote text into the body. mdsplit used to fragment footnotes into the flush-left form, which is what broke them.

**How to apply:** keep footnote definitions single-line in source `.md` (the portable, no-indent form).
The danhorst.com `.txt` export uses a Ruby port `lib/md_wrap.rb` that must stay byte-for-byte in parity with the Go `mdwrap` (verify with a diff); its export calls `MdWrap.wrap(..., wrap_footnotes: true)`. danhorst.com renders footnotes as Tufte sidenotes via Kramdown → `lib/builders/sidenotes.rb`, which requires single-line footnote definitions to pair references with content.

See [[feedback_md_tools]].
