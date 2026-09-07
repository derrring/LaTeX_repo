# LaTeX Template Collection

A modular LaTeX template system with document classes, style components, and themes for academic writing.

## Document Classes

| Class | Base | Use Case |
|-------|------|----------|
| `e_class_article` | article | Short papers, reports |
| `e_class_noteShort` | article | Short notes with decorated math environments |
| `e_class_noteLong` | book | Lecture notes, long-form documents |
| `e_class_thesis` | book | Theses, dissertations |

### Usage

```latex
\documentclass[12pt]{e_class_article}
% CJK glyph routing is part of the standard profile.
\documentclass[12pt]{e_class_thesis}
```

### Options

- `12pt` - Adjusted font sizes for section headings
- `cjk` / `nocjk` - Deprecated compatibility options; both are no-ops

## Architecture

```
e_style/
├── classes/                 # Document classes
├── sty_profiles/            # Thin composition manifests
│   ├── e_profile_standard.sty
│   └── e_profile_beamer.sty
├── sty_components/          # Implemented capabilities
│   ├── e_kernel.sty         # Engine guard and programming support
│   ├── e_fonts.sty          # Latin/script and math fonts
│   ├── e_cjk.sty            # CJK glyph routing and fallbacks
│   ├── e_math.sty           # Math package foundation
│   ├── e_math_notation.sty  # Project notation API
│   ├── e_document_layout.sty
│   ├── e_theorems.sty
│   ├── c120_color.tex       # Color palettes
│   ├── c130_toc.tex         # Table of contents styling
│   ├── c310_math_symbol.tex # Math operators and symbols
│   ├── c320_math_env.tex    # Theorem environments
│   └── ...
└── sty_features/            # Replaceable policies/renderers
    ├── e_title_fenced_*.sty # Fenced title styles
    ├── e_title_caligraphy_*.sty
    ├── e_math_env_deco.sty  # Colored theorem boxes
    └── e_frontbackmatter_*.sty
```

Profiles contain no implementation: they only select components for a target.
Components own reusable capabilities; features own class-selectable presentation
policies such as title and frontmatter styles. Document classes and themes select
profiles plus the features they need.

## Features

### Math Support

- Paired delimiters: `\parens{}`, `\bracks{}`, `\abs{}`, `\norm{}`
- Quantum notation: `\ket{}`, `\bra{}`, `\braket{}{}`
- Set builder: `\ensemble{x \given x > 0}`
- Expectation: `\expect{X}`, `\expect[Y]{X}` (conditional)
- Shorthand: `\mbbR`, `\mcalF`, `\mbfx`, `\mscrL`, etc.

### Color Palettes

- **Washi-Ink**: 19 traditional Japanese paper tones
- **Oceanic**: 21 colors × 3 tiers (Morandi/Saturated/Crystal)
- Semantic aliases: `myred`, `myblue`, `mylinkcolor`, `mytheoremcolor`, etc.

### Theorem Environments

Defined: `theorem`, `definition`, `lemma`, `proposition`, `corollary`, `remark`, `example`, `exercise`, `proof`, `solution`

With `e_math_env_deco.sty`: colored left-border boxes for visual distinction.

### Fenced Heading Fonts

The fenced styles keep their internal line-to-text gaps proportional to the
selected heading font and independent of body line spacing. Customize the font
without replacing the renderer:

```latex
\renewcommand{\eFencedSectionFont}{\normalfont\bfseries\Large} % noteShort
\renewcommand{\eFencedChapterFont}{\normalfont\bfseries\Large} % noteLong (thesis chapters use calligraphy; no font hook)
```

### CJK Support

The standard document profile includes lightweight CJK glyph routing:
- Source Han Serif/Sans fonts (cover CJK Unified + Extension A — effectively all
  real-world CJK)
- Rare supplementary-plane fallbacks (HanaMin/Jigmo/Unifont) are **opt-in**: they
  add ~10–15s of font loading per compile, so they are off by default. Enable
  them with `\eEnableCJKExtensionFonts` in the preamble, or by loading
  `e_cjk_engine` (which turns them on).

Load `e_cjk_engine` explicitly for full Japanese layout features such as ruby
and kenten (it also enables the rare-glyph fallbacks). Load `e_langfamily` to
declare custom per-script CJK families.

## Other Templates

- `MyCV/` - Two-column CV template (Deedy-style)
- `MyEspressoTheme/` - Beamer presentation theme

## Requirements

- LuaLaTeX (required)
- For code listings/algorithms, load `e_code` explicitly; minted may require
  shell escape depending on the TeX installation
- Text fonts: Noto Serif/Sans, Source Code Pro; and, loaded unconditionally by
  `e_fonts`, PT Serif/Sans (Cyrillic), Libertinus Serif/Sans (Greek), Shobhika
  (Sanskrit)
- Math fonts: STIX Two Math, New Computer Modern Math, XITS Math, IBM Plex Math
- For CJK: Source Han Serif/Sans (Harano Aji Mincho/Gothic as fallback). Opt-in
  rare supplementary-plane fallbacks (via `\eEnableCJKExtensionFonts` or
  `e_cjk_engine`): HanaMinB, Jigmo2, Jigmo3, Unifont Upper

## Examples

See `examples/` directory for sample documents demonstrating each class.

## Installation

Run `./utils/link_texmf.sh`. The installer replaces only existing symbolic
links; it refuses to remove real files or directories in `TEXMFHOME`.

## Verification

Run `./utils/check_repo.sh` for class, CV, Beamer, metadata, anchor, and ToC
smoke checks. Run `./utils/check_repo.sh --fonts` to include the CJK/font golden
render regression (requires Poppler and Pillow).

## License

MIT
