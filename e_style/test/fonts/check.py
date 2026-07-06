#!/usr/bin/env python3
"""Render-regression check for the e_style font stack (c111_fonts.tex).

WHY THIS EXISTS. Three of the CJK/multilingual mechanisms in c111 depend on
things no compile-time check can assert:
  - the \\em reverse-patch string-matches a luatexja internal (\\gtfamily\\itshape);
  - the ssub matrix relies on an UNDOCUMENTED luatexja side effect (fake NFSS
    shapes aliasing to the jfont-id that carries the AltFont) to reach emph/bold/sc;
  - AltFont range fallback + Renderer=Harfbuzz are experimental / have broken
    silently across a TeX Live update before (luatexja-fontspec, TL2019).
All fail in the "compiles clean, renders WRONG" mode -- tofu instead of a rare
hanzi, gothic instead of upright-mincho emph, mis-ordered Devanagari. The only
thing that catches that class is rasterizing the output and diffing it.

WHAT IT DOES. Compiles fixture.tex (which \\inputs the REAL installed
c111_fonts.tex via kpsewhich), rasterizes with pdftoppm, and pixel-diffs
against the committed golden. Run it AFTER EVERY TeX Live / package update;
if it fails, a mechanism regressed -- inspect fixture_cur.png against
golden/fixture.png. Regenerate the golden (--bless) only after confirming the
new render is correct by eye.

CONTRACT. The golden is the FULL-FONT path (system Source Han + HanaMin/Jigmo/
Unifont installed) -> real glyphs everywhere. On a CTAN-only machine this test
is EXPECTED to fail (rare hanzi degrade to tofu); that is the portable path, a
separate contract not covered here.

Deps: lualatex, pdftoppm (poppler), Pillow, numpy.
"""
import subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
FIX = "fixture"
GOLDEN = HERE / "golden" / f"{FIX}.png"
DPI = "150"
TOL_PIXEL = 40     # per-channel delta under which a pixel counts as "same" (absorbs AA/hinting drift)
TOL_FRAC = 0.015   # fail if > this fraction of pixels differ beyond TOL_PIXEL


def run(cmd):
    return subprocess.run(cmd, cwd=HERE, capture_output=True, text=True)


def rasterize(pdf_stem, out_stem):
    run(["pdftoppm", "-png", "-r", DPI, "-singlefile", f"{pdf_stem}.pdf", out_stem])
    return HERE / f"{out_stem}.png"


def build():
    run(["lualatex", "-interaction=nonstopmode", f"{FIX}.tex"])
    if not (HERE / f"{FIX}.pdf").exists():
        sys.exit("FAIL: fixture did not compile (no PDF).")
    log = (HERE / f"{FIX}.log").read_text(errors="ignore")
    if "Could not revert" in log:
        sys.exit("FAIL: luatexja \\em reverse-patch no longer applies -> CJK \\emph would be gothic.")
    return log.count("Missing character")


def main():
    bless = "--bless" in sys.argv
    miss = build()
    if bless:
        rasterize(FIX, "golden/" + FIX)
        print("blessed: golden/fixture.png regenerated. Verify it by eye before committing.")
        return 0
    cur = rasterize(FIX, f"{FIX}_cur")
    a = np.asarray(Image.open(GOLDEN).convert("RGB"), dtype=np.int16)
    b = np.asarray(Image.open(cur).convert("RGB"), dtype=np.int16)
    if a.shape != b.shape:
        print(f"FAIL: image size changed golden{a.shape[:2]} vs current{b.shape[:2]} (layout/glyph regression).")
        return 1
    frac = float((np.abs(a - b).max(axis=2) > TOL_PIXEL).mean())
    print(f"missing-character lines in log : {miss}")
    print(f"pixel-diff fraction vs golden  : {frac:.4f}  (threshold {TOL_FRAC})")
    if miss:
        print("FAIL: 'Missing character' in log -- a glyph tofu'd (a fallback font or range regressed).")
        return 1
    if frac > TOL_FRAC:
        print("FAIL: render drifted beyond tolerance. Diff fixture_cur.png vs golden/fixture.png.")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
