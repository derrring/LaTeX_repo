# LaTeX_repo project instructions

`AGENTS.md` is this repository's authoritative project guidance. `CLAUDE.md` is only a compatibility
symlink to the same bytes. Keep project rulings and evidence in this repository, not in a central
project manifest.

## Architecture

- Preserve the dependency direction. `classes/` is the entry point and loads downward; nothing
  loads a class. Measured edge counts, source-extracted:

  | from | to | edges |
  | --- | --- | --- |
  | `sty_profiles/` (composition) | `sty_components/` (capabilities) | 18 |
  | `classes/` | `sty_features/` (class-selectable presentation policy) | 13 |
  | `classes/` | `sty_profiles/` | 4 |
  | `classes/` | `sty_components/` | 4 |
  | `sty_features/` | `sty_components/` | 2 |

  **`sty_components/` must never load `sty_profiles/`.** That edge inverts the layering, and
  `check_repo.sh` fails on it. The only two instances were deprecated compatibility wrappers, now
  deleted.
- The four `e_class` products load CJK through the standard profile. Beamer and CV are independent
  products and do not pass through `e_cjk`; test them separately when their shared inputs change.
- Keep box configuration local to the box that owns it. A global `\tcbset` may silently restyle
  unrelated boxes.
- Do not redefine LuaTeX-ja's `\zh` or `\zw` primitives. Use collision-safe command names such as
  `\text<tag>` for inline script switches.

### File naming inside `sty_components/`

The prefix is not cosmetic. It marks which of **three roles** a file has, and the extension, the
`\ProvidesPackage` line and the load mechanism all move together with it:

| name | role | declares | loaded by |
| --- | --- | --- | --- |
| `e_<topic>.sty` | package — a capability unit | `\ProvidesPackage` | `\RequirePackage{e_visual}`, from a profile, another package, or a class |
| `c<NNN>_<topic>.tex` | component fragment | nothing | `\input{sty_components/c120_color.tex}` by **exactly one** `e_*.sty` |
| `e_class_prologue.tex` | class prologue | nothing | `\input{sty_components/e_class_prologue.tex}` by **all four** `.cls` |

`\input` of a fragment is ordered textual inclusion; `\RequirePackage` is idempotent and handles
options. They are not interchangeable, so the name says which one you are getting. `<NNN>` orders
the fragment layer: 110 layout, 120 color, 130 toc, 140 envs, 150 commands, 160 listings, 210 tikz,
310/320 math, 410 hyphenation, 510 ref/bib.

Note that a fragment is `\input` **with its `sty_components/` prefix**, not by bare filename.

The class prologue is a third role and not a mislabelled fragment: it is consumed by the class
layer, not by a component, and its `e_class_*` name is the one it shares with the four
`e_class_*.cls` files it serves. Renaming it `c100_*` would file it under component-fragment
numbering and assert a consumer relationship it does not have.

**There are no exceptions, and `check_repo.sh` enforces that.** The allow-list is empty. If you find
yourself wanting to add one, the file is telling you it has the wrong name or the wrong role. The
three that used to be there were resolved rather than excused: `c112_langfamily.sty` and
`c113_cjk_engine.sty` were packages under a fragment's name and are now `e_langfamily.sty` and
`e_cjk_engine.sty`; `e_class_prologue.tex` was never wrong, only unaccounted for.

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
