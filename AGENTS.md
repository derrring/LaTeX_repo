# LaTeX_repo project instructions

`AGENTS.md` is this repository's authoritative project guidance. `CLAUDE.md` is only a compatibility
symlink to the same bytes. Keep project rulings and evidence in this repository, not in a central
project manifest.

## Architecture

- Preserve the dependency direction:
  `sty_profiles/` (composition) → `sty_components/` (capabilities) → `sty_features/`
  (class-selectable presentation policy) → `classes/`.
- The four `e_class` products load CJK through the standard profile. Beamer and CV are independent
  products and do not pass through `e_cjk`; test them separately when their shared inputs change.
- Keep box configuration local to the box that owns it. A global `\tcbset` may silently restyle
  unrelated boxes.
- Do not redefine LuaTeX-ja's `\zh` or `\zw` primitives. Use collision-safe command names such as
  `\text<tag>` for inline script switches.

### File naming inside `sty_components/`

Two prefixes, and they are not cosmetic. They mark **package versus fragment**, and the extension,
the `\ProvidesPackage` line and the load mechanism all move together:

| name | is a | declares | loaded by |
| --- | --- | --- | --- |
| `e_<topic>.sty` | LaTeX package, the public capability unit | `\ProvidesPackage` | `\RequirePackage{e_visual}` |
| `c<NNN>_<topic>.tex` | fragment, private implementation | nothing | `\input{sty_components/c120_color.tex}` |

`\input` of a fragment is ordered textual inclusion; `\RequirePackage` is idempotent and handles
options. They are not interchangeable, so the name says which one you are getting. `<NNN>` orders
the fragment layer: 110 layout, 111 fonts, 120 color, 130 toc, 140 envs, 150 commands, 160
listings, 210 tikz, 310/320 math, 410 hyphenation, 510 ref/bib.

Note that a fragment is `\input` **with its `sty_components/` prefix**, not by bare filename.

Three files predate the rule. `check_repo.sh` carries them as an explicit allow-list so a fourth
cannot appear silently:

- `c112_langfamily.sty` and `c113_cjk_engine.sty` are packages under a fragment's name. **Do not
  rename them.** They are public: `e_class_prologue.tex` tells users to write
  `\usepackage{c113_cjk_engine}`, so a rename breaks documents outside this repository.
- `e_class_prologue.tex` is a fragment under a package's name. It has no public name to break, so it
  is the only one of the three that is safe to rename.

## Verification

- Run `./utils/check_repo.sh`; success requires the final `PASS: repository smoke checks` line.
- Run `PATH=/opt/homebrew/bin:$PATH ./utils/check_repo.sh --fonts` for the golden font-render checks.
  The bare `python3` chosen by another `PATH` may lack Pillow.
- For an isolated compile, include the repository in `TEXINPUTS`, for example
  `TEXINPUTS="$PWD//:"` from the repository root. The MyEspresso beamer theme lives in
  `MyEspressoTheme/`, which is a second root: `TEXINPUTS="$PWD//:$PWD/MyEspressoTheme//:"`.
- Verify visual changes by rendering PDFs and comparing pixels, not by reading TeX alone.
- Beamer documents using remembered TikZ positions or tables of contents need convergence through
  `latexmk` or at least four isolated passes. One or two passes can produce a false large diff.
- A full check normally takes minutes because each class loads the font stack; absence of immediate
  output is not evidence that it is hung.
