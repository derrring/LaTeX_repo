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
