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
% or with CJK support:
\documentclass[12pt,cjk]{e_class_thesis}
```

### Options

- `12pt` - Adjusted font sizes for section headings
- `cjk` / `nocjk` - Enable/disable CJK (Chinese/Japanese/Korean) support

## Architecture

```
e_style/
├── classes/                 # Document classes
├── sty_components/          # Core modules
│   ├── e_core.sty           # Universal packages (Beamer-safe)
│   ├── e_standard_doc.sty   # Document-specific packages
│   ├── c111_fonts.tex       # Font configuration
│   ├── c120_color.tex       # Color palettes
│   ├── c130_toc.tex         # Table of contents styling
│   ├── c310_math_symbol.tex # Math operators and symbols
│   ├── c320_math_env.tex    # Theorem environments
│   └── ...
└── sty_features/            # Optional features
    ├── e_title_fenced_*.sty # Fenced title styles
    ├── e_title_caligraphy_*.sty
    ├── e_math_env_deco.sty  # Colored theorem boxes
    └── e_frontbackmatter_*.sty
```

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

### CJK Support

When `cjk` option is enabled:
- Source Han Serif/Sans fonts
- HanaMin fallback for rare characters
- Boten (dots) emphasis via `\emph{}`

## Other Templates

- `MyCV/` - Two-column CV template (Deedy-style)
- `MyEspressoTheme/` - Beamer presentation theme

## Requirements

- LuaLaTeX (recommended) or XeLaTeX
- `--shell-escape` flag (for minted code listings)
- Text fonts: Noto Serif/Sans, Source Code Pro
- Math fonts: STIX Two Math, New Computer Modern Math, XITS Math, IBM Plex Math
- For CJK: Source Han Serif/Sans, HanaMinA/B

## Examples

See `examples/` directory for sample documents demonstrating each class.

## License

MIT
