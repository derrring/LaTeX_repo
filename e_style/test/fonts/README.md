# Font-stack render regression test

Guards the CJK / multilingual / rare-character implementation in `e_cjk` and
`e_fonts` against silent breakage on TeX Live / package updates. The fixture
loads `e_cjk` directly; it previously went through a `c111_fonts.tex`
compatibility wrapper, which has been deleted.

## Why a *render* test (not a compile check)

Three mechanisms in `c111` depend on things no compile-time assertion can see:

| Mechanism | Dependency | Failure mode |
|---|---|---|
| `\em` reverse-patch | string-matches a luatexja internal (`\gtfamily\itshape`) | CJK `\emph` silently reverts to **gothic** |
| ssub → AltFont all-shape reach | UNDOCUMENTED luatexja side effect (fake shapes share the jfont-id that carries the AltFont) | rare hanzi tofu in **bold / emph / sc** only |
| AltFont ranges + `Renderer=Harfbuzz` | experimental; AltFont broke silently once (TL2019) | tofu / mis-ordered Devanagari |

Every one fails as **"compiles clean, renders wrong."** Only rasterizing and
pixel-diffing the output catches it. The 2019 luatexja-fontspec AltFont break
is the proof: unchanged source, zero errors, glyphs silently gone.

## Run

```
cd e_style/test/fonts
python3 check.py          # PASS / FAIL (exit 0 / non-zero)
```

Run it **after every `tlmgr update` / TeX Live year bump**. On FAIL, open
`fixture_cur.png` next to `golden/fixture.png` and look. Deps: `lualatex`,
`pdftoppm` (poppler), Pillow.

`fixture.tex` `\input`s the repository's real compatibility entrypoint through
an explicit `TEXINPUTS`, so a fresh clone does not depend on an installed
symlink. It exercises: the CJK
AltFont chain (one glyph each for Ext-B / Ext-I / Ext-G / Ext-J), CJK
`\emph` (must stay upright mincho), `\textbf` + `\textsc` (ssub + AltFont must
reach them), a Devanagari conjunct + Vedic svara (HarfBuzz), and polytonic
Greek + Russian italic.

## Golden

`golden/fixture.png` is the committed reference. Regenerate **only** after
verifying a new render is correct by eye:

```
python3 check.py --bless
```

## Contract & scope

- The golden is the **full-font** path (system Source Han + HanaMin +
  Jigmo2/3 + Unifont installed) → real glyphs everywhere.
- On a **CTAN-only** machine (Overleaf, a co-author without the system fonts)
  this test is *expected* to fail: rare hanzi degrade to tofu. That portable
  path is a **separate contract** (Harano Aji primary + controlled tofu) and
  is not yet a golden here — TODO if needed.
- If you pin a TeX Live year (Docker tag / `tlnet-final`), run this before
  moving the pin forward; a green run is the go-ahead.

## Do NOT

- Do not `\WarningFilter` the `\em` patch's "Could not revert" warning — this
  test greps for it and it is the fail-loud signal for a luatexja internal rename.
- Do not "clean up" the ssub matrix (`\ltj@nofakeital`) or migrate the AltFont
  chain to `luaotfload.add_fallback` (experimental + crashes under luatexja,
  ctex-kit #691). See the implementation notes in `e_cjk.sty`.
