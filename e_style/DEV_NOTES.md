# e_style Dev Notes

Architecture / compatibility / migration notes for the `e_class` family.
Project-level concerns that don't belong in any single `.cls` or `.sty`.

---

## 2026-05-10 — `\DocumentMetadata` compatibility

**Status**: e_class is plug-and-play compatible with the LaTeX 2022+
`\DocumentMetadata{...}` PDF management infrastructure. No `.cls` or
`.sty` changes required.

### Background

LaTeX 2022-06-01 release introduced `\DocumentMetadata{...}` as the
unified PDF management API (project: `l3pdf`). It goes BEFORE
`\documentclass{...}` and provides:

- `pdfversion = 2.0` — PDF version control
- `pdfstandard = a-2u` (or `a-1a`, `a-2a`, `a-3u`, ...) — PDF/A
  archival compliance, replaces `pdfx` package
- `lang = en` — document language for accessibility
- `metadata = {title, author, subject, keywords}` — replaces
  `\hypersetup{pdftitle=...}` and `hyperxmp` for XMP metadata
- `testphase = {phase-III, table, sec, math}` — Tagged PDF
  / accessibility (experimental, evolving)

Modern `hyperref` (>= 2022) auto-detects `\DocumentMetadata` and yields
PDF management to it. `\hypersetup{pdftitle=...}` continues to work
alongside but is the older idiom.

### e_class compatibility audit (2026-05-10)

**Direct `\pdf...` primitive usage**: 0 in e_style/. (Single hit in
`e_frontbackmatter_formal.sty:465` is a comment, not code.) e_class
goes through `hyperref` exclusively, which is the
`\DocumentMetadata`-cooperating path.

**Package interactions**:

| Package | Loaded by | `\DocumentMetadata` compatibility |
|---|---|---|
| `hyperref` | `e_standard_doc` | ✓ cooperates natively (>=2022) |
| `bookmark` | `e_standard_doc` | ✓ improves with `\DocumentMetadata` |
| `geometry` | `e_standard_doc` | ✓ unaffected |
| `fancyhdr` | `e_standard_doc` | ✓ unaffected |
| `titlesec`, `titletoc`, `etoc` | `e_standard_doc` | ✓ unaffected |
| `tcolorbox` (+ skins, breakable, ...) | `c140_envs` / `e_math_env_deco` | ✓ metadata; ⚠ Tagged PDF (`testphase`) may produce untagged callout/theorem boxes |
| `microtype` | `c111_fonts` | ✓ |
| `unicode-math` | `c111_fonts` | ✓ |
| `fontspec` | `c111_fonts` | ✓ |
| `luatexja` (CJK) | `c111_fonts` | ✓ for metadata; ⚠ PDF/A mode may fail font-embedding subset rules |
| `biblatex` (+ biber) | per-doc | ✓ |
| `mathtools`, `amsmath`, `thmtools` | `e_core` | ✓ |

### Migration plan

**Phase A — metadata-only (zero-risk, recommended for active use)**

In a document preamble:
```latex
\DocumentMetadata{
  metadata = {
    title    = {Document Title},
    author   = {Author Name},
    subject  = {Concise subject line},
    keywords = {comma, separated, keywords}
  }
}
\documentclass{e_class_noteShort}   % or e_class_article, etc.
```
Functionally equivalent to `\hypersetup{pdftitle=..., pdfauthor=...}`,
syntactically more modern. Both can coexist; `\DocumentMetadata`
takes precedence. Drop the `\hypersetup{pdftitle=...}` lines once
migrated.

**Phase B — PDF/A archival (for journal / arXiv submission)**

Add `pdfversion = 2.0`, `pdfstandard = a-2u`, `lang = ...`. Test
points:

- CJK font embedding under `luatexja` — verify subset compliance
  (some publishers reject when CJK fonts can't be subset for PDF/A)
- `unicode-math` math fonts — verify same
- All bitmap images (in `assets/`) must be embedded as proper
  ICC-tagged streams — may need `pdfx` cleanup pass

Not needed for daily / personal use.

**Phase C — Tagged PDF (accessibility, experimental)**

Add `testphase = {phase-III, table, sec, math}`. Risk points specific
to e_class:

- `tcolorbox` callout / theorem decorations — Tagged PDF output may
  untag or mistag boxes (still under upstream development)
- `fancyhdr` running headers — testphase generally tags correctly
- `etoc` / `titlesec` custom ToC / section titles — testphase support
  exists but requires per-style verification
- `e_title_fenced_sec.sty` (custom rule-bracketed section titles) —
  unverified; rules may be tagged as decorative content rather than
  heading scaffolding

Recommendation: do NOT enable Phase C in production e_class docs
until LaTeX 2026/2027 release stabilizes Tagged PDF output for
`tcolorbox` and custom section formatters. Current e_class users
mostly produce non-accessibility-critical math / philosophy work
where Phase A suffices.

### Open TODO

- [ ] Test Phase A in `examples/sample_noteShort.tex` — verify
      `\DocumentMetadata{metadata={...}}` produces correct PDF Info
      Dictionary across `e_class_article`, `e_class_noteShort`,
      `e_class_noteLong`, `e_class_thesis`.
- [ ] Document Phase A in `e_style/README.md` (or top-level README) as
      the recommended metadata path; deprecate `\hypersetup{pdftitle=...}`
      in user-facing examples.
- [ ] Periodic re-audit of Phase C (`testphase`) compatibility as
      LaTeX 2026/2027 ships; particular attention to `tcolorbox`
      tag-mode output.
- [ ] If a user-facing project requires PDF/A submission, write a
      Phase B checklist note covering CJK and math font
      subset-compliance gotchas.

### References

- LaTeX project, *l3pdf — modern PDF generation in LaTeX*. https://latex-project.org/news/2022/06/02/release-LaTeX2022-2/
- `texdoc documentmetadata-support` (in any current TeX Live install)
- `hyperref` manual, "PDF version 2.0 / PDF management" section
