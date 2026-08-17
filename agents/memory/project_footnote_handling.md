---
name: project-footnote-handling
description: How md-tools treats markdown footnotes and the danhorst.com parity/rendering constraints behind it
metadata: 
  node_type: memory
  type: project
  originSessionId: 199bfd42-a22c-41ff-a761-f0f0d390e7a4
  modified: 2026-08-17T19:55:27.025Z
---

md-tools treats a footnote definition plus its continuation lines as one **opaque block**: `markdown.Transform` collects `[^label]:` + continuation (via `IsFootnoteContinuation`) and by default emits it verbatim — never split by mdsplit, never joined by mdjoin/mdunwrap.
`mdwrap -f` (opt-in `Footnote` handler) is the one exception: it wraps the body to the column width with **4-space-indented** continuation.

**Why:** a multi-sentence footnote only renders portably when on one line, or with 4-space-indented continuation.
Flush-left continuation works in CommonMark-family parsers but breaks Kramdown and Pandoc (they need the indent), so it silently leaks footnote text into the body. mdsplit used to fragment footnotes into the flush-left form, which is what broke them.

**How to apply:** keep footnote definitions single-line in source `.md` (the portable, no-indent form).
The danhorst.com `.txt` export uses a Ruby port `lib/md_wrap.rb` that must stay byte-for-byte in parity with the Go `mdwrap` (verify with a diff); its export calls `MdWrap.wrap(..., wrap_footnotes: true)`. danhorst.com renders footnotes as Tufte sidenotes via Kramdown → `lib/builders/sidenotes.rb`, which requires single-line footnote definitions to pair references with content.

**Parity drift as of 2026-08-17 (v1.2.0), unresolved:** Go `mdwrap` now treats an HTML tag as one unbreakable token, so it no longer breaks between a tag's name and its attributes.
Output is unchanged for tag-free prose — every existing fixture is byte-identical — so the two diverge **only on text containing inline HTML with attributes**.
`lib/md_wrap.rb` needs the same change before parity holds for that input class.
The Go rule: `<` opens a tag only when followed by `/` or an ASCII letter and closed by a later `>`, so `a < b` and `5<10` stay ordinary text.

Note danhorst.com does **not** use `mdsidenote` — it builds sidenotes itself in Ruby from single-line footnote definitions.
So the 2026-08-17 change to `mdsidenote`'s output (the marker now attaches to the preceding text instead of starting its own line) does not touch the site.
It does change `mdsidenote`'s output for anything else; `mdfootnote | mdsidenote` migrates older documents.

No parity or Ruby constraint is documented anywhere in the md-tools repo — it lives only here and in danhorst.com.

See [[md-tools-usage-mdsplit-and-mdtable]].
